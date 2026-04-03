import Foundation
import CoreML

// MARK: - SensorSample

/// A single snapshot of sensor readings from the Apple Watch.
struct SensorSample {
    let timestamp: Double   // Unix epoch seconds
    let ax: Double          // Accelerometer X  (g)
    let ay: Double          // Accelerometer Y  (g)
    let az: Double          // Accelerometer Z  (g)
    let hr: Double          // Heart rate       (BPM)
}

// MARK: - SensorBuffer

/// A sliding-window ring buffer that retains the last `maxCapacity` samples.
/// At ~50 Hz this represents a 10-second analysis window (500 samples).
final class SensorBuffer {

    // MARK: Configuration

    /// Maximum number of samples to retain (50 Hz × 10 s = 500)
    private let maxCapacity: Int

    // MARK: State

    private var samples: [SensorSample] = []

    // MARK: Init

    init(capacity: Int = 500) {
        self.maxCapacity = capacity
    }

    // MARK: Public API

    /// Appends a new sample, automatically evicting the oldest when full.
    func add(sample: SensorSample) {
        if samples.count >= maxCapacity {
            samples.removeFirst()
        }
        samples.append(sample)
    }

    /// Returns a snapshot of the current window only when the buffer is full,
    /// ensuring the ML model always receives a consistent fixed-length input.
    func getWindow() -> [SensorSample]? {
        guard samples.count >= maxCapacity else { return nil }
        return samples
    }

    /// Whether the buffer has collected enough samples for analysis.
    var isFull: Bool { samples.count >= maxCapacity }

    /// Number of samples currently held.
    var count: Int { samples.count }
}

// MARK: - Feature Extraction

/// Extracts an 11-element feature vector from a window of sensor samples.
///
/// Returned order (must match CoreML model input names exactly):
/// `mean_acc`, `std_acc`, `max_acc`, `min_acc`, `sma`,
/// `peak_count`, `zero_crossings`, `dominant_freq`,
/// `hr_mean`, `hr_std`, `hr_slope`
func extractFeatures(from samples: [SensorSample]) -> [Double] {
    guard !samples.isEmpty else {
        return Array(repeating: 0.0, count: 11)
    }

    let n = Double(samples.count)

    // -----------------------------------------------------------------
    // Acceleration magnitudes
    // -----------------------------------------------------------------
    let magnitudes: [Double] = samples.map { s in
        sqrt(s.ax * s.ax + s.ay * s.ay + s.az * s.az)
    }

    // mean_acc
    let meanAcc = magnitudes.reduce(0.0, +) / n

    // std_acc
    let variance = magnitudes.reduce(0.0) { $0 + ($1 - meanAcc) * ($1 - meanAcc) } / n
    let stdAcc   = sqrt(variance)

    // max_acc / min_acc
    let maxAcc = magnitudes.max() ?? 0.0
    let minAcc = magnitudes.min() ?? 0.0

    // Signal Magnitude Area (SMA) — sum of per-axis absolute values / n
    let sma: Double = samples.reduce(0.0) { acc, s in
        acc + (abs(s.ax) + abs(s.ay) + abs(s.az))
    } / n

    // Peak count — local maxima in the magnitude signal
    var peakCount: Double = 0.0
    if magnitudes.count >= 3 {
        for i in 1 ..< magnitudes.count - 1 {
            if magnitudes[i] > magnitudes[i - 1] && magnitudes[i] > magnitudes[i + 1] {
                peakCount += 1.0
            }
        }
    }

    // Placeholders (computed in future iterations)
    let zeroCrossings: Double = 0.0    // TODO: implement zero-crossing rate
    let dominantFreq:  Double = 2.0    // TODO: implement FFT-based frequency

    // -----------------------------------------------------------------
    // Heart rate features
    // -----------------------------------------------------------------
    let hrValues: [Double] = samples.map { $0.hr }
    let hrMean   = hrValues.reduce(0.0, +) / n

    let hrVariance = hrValues.reduce(0.0) { $0 + ($1 - hrMean) * ($1 - hrMean) } / n
    let hrStd      = sqrt(hrVariance)

    // HR slope via simple linear regression over sample index
    let xMean   = (n - 1.0) / 2.0
    var num     = 0.0
    var den     = 0.0
    for (i, hr) in hrValues.enumerated() {
        let xi = Double(i) - xMean
        num += xi * (hr - hrMean)
        den += xi * xi
    }
    let hrSlope: Double = den != 0.0 ? num / den : 0.0

    // -----------------------------------------------------------------
    // Assemble feature vector (order MUST match model input names)
    // -----------------------------------------------------------------
    return [
        meanAcc,       // mean_acc
        stdAcc,        // std_acc
        maxAcc,        // max_acc
        minAcc,        // min_acc
        sma,           // sma
        peakCount,     // peak_count
        zeroCrossings, // zero_crossings
        dominantFreq,  // dominant_freq
        hrMean,        // hr_mean
        hrStd,         // hr_std
        hrSlope        // hr_slope
    ]
}

// MARK: - SeizureDetectionManager

/// Orchestrates the end-to-end real-time seizure detection pipeline.
///
/// Usage:
/// ```swift
/// let detector = SeizureDetectionManager.shared
/// detector.processSample(sample: SensorSample(timestamp: ..., ax: ..., ay: ..., az: ..., hr: ...))
/// ```
final class SeizureDetectionManager {

    // MARK: Singleton

    static let shared = SeizureDetectionManager()

    // MARK: Configuration

    /// Probability threshold above which a seizure is flagged.
    private let seizureThreshold: Double = 0.7

    // MARK: State

    private let buffer  = SensorBuffer(capacity: 500)
    private var model:  SeizureModel?

    // MARK: Callbacks

    /// Called on the **main thread** whenever a new prediction is produced.
    /// - Parameter probability: Seizure probability in [0, 1].
    var onPrediction: ((Double) -> Void)?

    /// Called on the **main thread** when a seizure is detected (probability > threshold).
    var onSeizureDetected: ((Double) -> Void)?

    // MARK: Init

    private init() {
        loadModel()
    }

    // MARK: - Model Loading

    private func loadModel() {
        do {
            let config           = MLModelConfiguration()
            config.computeUnits  = .all          // GPU + Neural Engine when available
            model                = try SeizureModel(configuration: config)
            print("✅ [SeizureDetection] CoreML model loaded successfully")
        } catch {
            print("❌ [SeizureDetection] Failed to load CoreML model: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Pipeline Entry Point

    /// Processes a single sensor sample through the sliding-window pipeline.
    /// Call this every time new accelerometer + heart-rate data arrives from the Watch.
    func processSample(sample: SensorSample) {
        buffer.add(sample: sample)

        // Only run inference once the buffer holds a full 10-second window.
        guard let window = buffer.getWindow() else {
            print("⏳ [SeizureDetection] Buffer filling… (\(buffer.count)/500 samples)")
            return
        }

        let features     = extractFeatures(from: window)
        let probability  = predict(features: features)

        handlePrediction(probability: probability)
    }

    // MARK: - CoreML Prediction

    /// Feeds an 11-element feature vector into the model and returns seizure probability.
    private func predict(features: [Double]) -> Double {
        guard let model = model else {
            print("⚠️  [SeizureDetection] Model not available — skipping prediction")
            return 0.0
        }

        guard features.count == 11 else {
            print("❌ [SeizureDetection] Feature vector has \(features.count) elements; expected 11")
            return 0.0
        }

        do {
            let input = SeizureModelInput(
                mean_acc:       features[0],
                std_acc:        features[1],
                max_acc:        features[2],
                min_acc:        features[3],
                sma:            features[4],
                peak_count:     features[5],
                zero_crossings: features[6],
                dominant_freq:  features[7],
                hr_mean:        features[8],
                hr_std:         features[9],
                hr_slope:       features[10]
            )

            let output      = try model.prediction(input: input)
            let probability = output.probabilities[1] ?? 0.0 // adjust property name to match your .mlmodel output

            print(String(format: "📊 [SeizureDetection] Seizure probability: %.4f", probability))
            return probability

        } catch {
            print("❌ [SeizureDetection] Prediction failed: \(error.localizedDescription)")
            return 0.0
        }
    }

    // MARK: - Detection Logic

    private func handlePrediction(probability: Double) {
        // Always surface the raw probability to any registered listener.
        DispatchQueue.main.async { [weak self] in
            self?.onPrediction?(probability)
        }

        if probability > seizureThreshold {
            print("🚨 [SeizureDetection] Seizure detected! Probability: \(String(format: "%.4f", probability))")

            DispatchQueue.main.async { [weak self] in
                self?.onSeizureDetected?(probability)
            }
        }
    }
}

// MARK: - WatchConnectivityManager Integration

extension WatchConnectivityManager {

    /// Call this from the WC payload handler whenever the Watch sends sensor data.
    /// Expected payload keys: `"ax"`, `"ay"`, `"az"`, `"heartRate"`, `"timestamp"`.
    func forwardSensorPayloadToDetection(_ payload: [String: Any]) {
        guard
            let ax        = payload["ax"]        as? Double,
            let ay        = payload["ay"]        as? Double,
            let az        = payload["az"]        as? Double,
            let hr        = payload["heartRate"] as? Double,
            let timestamp = payload["timestamp"] as? Double
        else {
            // Not a sensor payload — let the normal handler deal with it.
            return
        }

        let sample = SensorSample(timestamp: timestamp, ax: ax, ay: ay, az: az, hr: hr)
        SeizureDetectionManager.shared.processSample(sample: sample)
    }
}

/*
 ─────────────────────────────────────────────────────────────────────
 EXAMPLE USAGE
 ─────────────────────────────────────────────────────────────────────

 // 1. Wire up callbacks once (e.g., in AppDelegate or a ViewModel):
 SeizureDetectionManager.shared.onPrediction = { probability in
     // Update a live probability gauge in your UI
     dashboardVC.updateSeizureProbability(probability)
 }

 SeizureDetectionManager.shared.onSeizureDetected = { probability in
     // Show an alert, start a recording, notify emergency contacts, etc.
     EmergencyService.shared.triggerWithCountdown()
 }

 // 2. Feed samples as they arrive from the Watch:
 //    In WatchConnectivityManager.handleIncomingPayload(_:), after the
 //    existing health-data handling, add:
 //
 //    forwardSensorPayloadToDetection(payload)
 //
 //    The Watch side should include keys: ax, ay, az, heartRate, timestamp.

 // 3. (Optional) Stand-alone test without a Watch — simulate a sample:
 let testSample = SensorSample(
     timestamp: Date().timeIntervalSince1970,
     ax: 0.1, ay: 0.2, az: 9.8,
     hr: 72.0
 )
 SeizureDetectionManager.shared.processSample(sample: testSample)

 ─────────────────────────────────────────────────────────────────────
*/
