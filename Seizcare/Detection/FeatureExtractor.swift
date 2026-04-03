// FeatureExtractor.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Transform a window of SensorSamples + DetectionContext into a
// WindowFeatures struct. All math is pure/testable (no side effects).
// Uses Accelerate / vDSP for FFT-based dominant frequency and spectral power.
//
// Window spec: 200 samples @ 50 Hz = 4 seconds
// All features are documented with units and expected range.

import Foundation
import Accelerate

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FeatureExtractor
// ─────────────────────────────────────────────────────────────────────────────

enum FeatureExtractor {

    // MARK: - Public Entry Point

    /// Extract a full WindowFeatures struct from `samples` and `context`.
    /// Samples must be ordered oldest→newest.
    /// Returns nil only if `samples` is empty.
    static func extract(from samples: [SensorSample],
                        context: DetectionContext,
                        previousRisk: Double = 0,
                        positiveWindowCount: Int = 0,
                        rhythmicDuration: Double = 0,
                        postEventStillness: Double = 0) -> WindowFeatures? {

        guard !samples.isEmpty else { return nil }

        var f = WindowFeatures()

        // --- Motion ----------------------------------------------------------
        let magnitudes  = samples.map { $0.accelMagnitude }
        let gyroMags    = samples.map { $0.gyroMagnitude  }
        let n           = Double(samples.count)

        f.accelMagMean    = mean(magnitudes)
        f.accelMagStd     = std(magnitudes, mu: f.accelMagMean)
        f.accelPeakToPeak = (magnitudes.max() ?? 0) - (magnitudes.min() ?? 0)
        f.signalMagnitudeArea = samples.reduce(0.0) { acc, s in
            acc + abs(s.ax) + abs(s.ay) + abs(s.az)
        } / n

        // Jerk: rate of change of acceleration magnitude
        let jerks: [Double] = zip(magnitudes.dropFirst(), magnitudes).map { abs($0 - $1) }
        f.jerkMean     = mean(jerks)
        f.jerkVariance = variance(jerks, mu: f.jerkMean)

        // FFT-based spectral features
        let sampleRate: Double = 50.0
        let spectral = computeSpectralFeatures(magnitudes, sampleRate: sampleRate)
        f.dominantFrequency = spectral.dominant
        f.spectralPowerLow  = spectral.lowBand   // 0.5–3 Hz
        f.spectralPowerMid  = spectral.midBand   // 3–8 Hz
        f.spectralPowerHigh = spectral.highBand  // 8–20 Hz

        // Periodicity: normalised lag-1 autocorrelation
        f.periodicityScore = autocorrelationLag1(magnitudes)

        // Gyro
        f.gyroMagMean = mean(gyroMags)
        f.gyroMagStd  = std(gyroMags, mu: f.gyroMagMean)

        // --- Heart Rate ------------------------------------------------------
        let hrValues = samples.compactMap { $0.hr }
        if !hrValues.isEmpty {
            f.hrMean  = mean(hrValues)
            f.hrMax   = hrValues.max() ?? 0
            f.hrSlope = linearSlope(hrValues)
            f.hrDeltaFromBaseline = f.hrMean - context.baselineHR
        } else {
            f.hrMean             = context.baselineHR
            f.hrMax              = context.baselineHR
            f.hrSlope            = 0
            f.hrDeltaFromBaseline = 0
        }

        // --- Context ---------------------------------------------------------
        f.sleepHoursLastNight = context.sleepHoursLastNight
        f.sevenDaySleepAvg    = context.sevenDaySleepAvg
        f.isAsleepFlag        = context.isCurrentlyAsleep  ? 1.0 : 0.0
        f.isWorkoutFlag       = context.isWorkoutActive    ? 1.0 : 0.0
        f.timeOfDayNorm       = context.timeOfDayNorm
        f.userBaselineHR      = context.baselineHR
        f.userBaselineMotion  = context.baselineMotion

        // --- Personalization -------------------------------------------------
        switch context.sensitivityLevel {
        case .high:   f.sensitivityEncoded = 1.0
        case .medium: f.sensitivityEncoded = 0.5
        case .low:    f.sensitivityEncoded = 0.0
        }
        f.seizureFreqProfile = context.seizureFreqProfile

        // --- Temporal --------------------------------------------------------
        f.prevWindowRiskScore  = previousRisk
        f.positiveWindowCount  = Double(positiveWindowCount)
        f.rhythmicDuration     = rhythmicDuration
        f.postEventStillness   = postEventStillness

        return f
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Math Helpers
    // ─────────────────────────────────────────────────────────────────────────

    static func mean(_ v: [Double]) -> Double {
        guard !v.isEmpty else { return 0 }
        return v.reduce(0, +) / Double(v.count)
    }

    static func variance(_ v: [Double], mu: Double) -> Double {
        guard !v.isEmpty else { return 0 }
        return v.reduce(0.0) { $0 + ($1 - mu) * ($1 - mu) } / Double(v.count)
    }

    static func std(_ v: [Double], mu: Double) -> Double { sqrt(variance(v, mu: mu)) }

    /// Linear regression slope (value/index). Returns BPM/sample — caller converts to BPM/s.
    static func linearSlope(_ v: [Double]) -> Double {
        let n = Double(v.count)
        guard n > 1 else { return 0 }
        let mu = mean(v)
        let xMean = (n - 1) / 2
        var num = 0.0, den = 0.0
        for (i, val) in v.enumerated() {
            let xi = Double(i) - xMean
            num += xi * (val - mu)
            den += xi * xi
        }
        // Slope in units/sample; convert to units/second at 50 Hz
        return den != 0 ? (num / den) * 50.0 : 0
    }

    /// Normalised lag-1 autocorrelation. Range [-1, 1].
    /// A value near 1 indicates strongly periodic (rhythmic) motion.
    static func autocorrelationLag1(_ v: [Double]) -> Double {
        guard v.count > 1 else { return 0 }
        let mu = mean(v)
        var c0 = 0.0, c1 = 0.0
        let demeaned = v.map { $0 - mu }
        for i in 0..<demeaned.count { c0 += demeaned[i] * demeaned[i] }
        for i in 1..<demeaned.count { c1 += demeaned[i] * demeaned[i - 1] }
        return c0 > 0 ? c1 / c0 : 0
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - FFT Spectral Features (vDSP)
    // ─────────────────────────────────────────────────────────────────────────

    struct SpectralResult {
        let dominant: Double   // Hz
        let lowBand:  Double   // power in 0.5–3 Hz
        let midBand:  Double   // power in 3–8 Hz
        let highBand: Double   // power in 8–20 Hz
    }

    static func computeSpectralFeatures(_ signal: [Double], sampleRate: Double) -> SpectralResult {
        // Pad to next power of 2 for FFT efficiency
        let fftSize = nextPow2(signal.count)
        var padded = signal + Array(repeating: 0.0, count: fftSize - signal.count)

        // Apply Hann window to reduce spectral leakage
        var window = [Double](repeating: 0, count: fftSize)
        vDSP_hann_windowD(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        
        var windowed = [Double](repeating: 0, count: fftSize)
        vDSP_vmulD(&padded, 1, &window, 1, &windowed, 1, vDSP_Length(fftSize))

        // Set up FFT
        let log2n = Int(log2(Double(fftSize)))
        guard let setup = vDSP_create_fftsetupD(vDSP_Length(log2n), FFTRadix(FFT_RADIX2)) else {
            return SpectralResult(dominant: 0, lowBand: 0, midBand: 0, highBand: 0)
        }
        defer { vDSP_destroy_fftsetupD(setup) }

        var real = windowed
        var imag = [Double](repeating: 0.0, count: fftSize)
        let halfSize = fftSize / 2
        var magnitudeSpectrum = [Double](repeating: 0.0, count: halfSize)

        real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPDoubleSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                vDSP_fft_zipD(setup, &splitComplex, 1, vDSP_Length(log2n), FFTDirection(FFT_FORWARD))

                // Magnitude spectrum (only first half — positive frequencies)
                vDSP_zvmagsD(&splitComplex, 1, &magnitudeSpectrum, 1, vDSP_Length(halfSize))
            }
        }

        // Frequency resolution
        let freqResolution = sampleRate / Double(fftSize)   // Hz per bin

        // Find dominant frequency (skip DC bin 0)
        var dominantBin = 1
        var maxMag = magnitudeSpectrum[1]
        for i in 2..<halfSize {
            if magnitudeSpectrum[i] > maxMag {
                maxMag = magnitudeSpectrum[i]
                dominantBin = i
            }
        }
        let dominant = Double(dominantBin) * freqResolution

        // Band power integration
        var lowPower = 0.0, midPower = 0.0, highPower = 0.0
        for i in 1..<halfSize {
            let freq = Double(i) * freqResolution
            let power = magnitudeSpectrum[i]
            if freq >= 0.5 && freq < 3.0  { lowPower  += power }
            if freq >= 3.0 && freq < 8.0  { midPower  += power }
            if freq >= 8.0 && freq < 20.0 { highPower += power }
        }

        return SpectralResult(dominant: dominant,
                              lowBand:  lowPower,
                              midBand:  midPower,
                              highBand: highPower)
    }

    private static func nextPow2(_ n: Int) -> Int {
        var p = 1
        while p < n { p <<= 1 }
        return p
    }
}
