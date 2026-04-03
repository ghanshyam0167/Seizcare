// SeizureInferenceService.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Model 2 — Seizure probability estimator.
// Called ONLY after the artifact filter has NOT suppressed the window.
//
// Architecture:
//   1. Tries personalised CoreML model (if available and validated)
//   2. Falls back to LegacySeizureModelAdapter (wraps old SeizureModel.mlmodel)
//   3. Falls back to heuristic rule-based estimator
//
// TODO: Replace primary path with SeizureDetector.mlmodel when trained.
// The LegacySeizureModelAdapter maps the new WindowFeatures into the old 11-feature
// input format. It is NOT the primary architecture — only a fallback.

import Foundation
import CoreML

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SeizureInferenceService
// ─────────────────────────────────────────────────────────────────────────────

final class SeizureInferenceService {

    // MARK: Singleton

    static let shared = SeizureInferenceService()

    // MARK: State

    private var legacyAdapter: LegacySeizureModelAdapter?
    private var personalizedModelURL: URL?

    private init() {
        loadLegacyAdapter()
        // TODO: Load personalised model if ModelPersonalizationManager has one ready.
        print("🧠 [SeizureInference] Initialised (legacy adapter: \(legacyAdapter != nil ? "✅" : "❌"))")
    }

    // MARK: - Public API

    /// Predict seizure probability [0,1] from a feature window.
    /// Called only when artifact filter has NOT flagged the window as definite normal activity.
    func predict(features: WindowFeatures) -> Double {
        // Strategy order:
        //   1. Personalised CoreML model (future — see TODO below)
        //   2. Legacy SeizureModel.mlmodel adapter
        //   3. Heuristic fallback

        // TODO: Step 1 — personalised model
        // if let prob = predictWithPersonalisedModel(features: features) { return prob }

        // Step 2 — legacy adapter
        if let prob = legacyAdapter?.predict(features: features) {
            print(String(format: "🔬 [SeizureInference] Legacy adapter → p=%.4f", prob))
            return prob
        }

        // Step 3 — heuristic fallback (always available)
        let prob = heuristicEstimate(features: features)
        print(String(format: "🔬 [SeizureInference] Heuristic → p=%.4f", prob))
        return prob
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Legacy Adapter Loading
    // ─────────────────────────────────────────────────────────────────────────

    private func loadLegacyAdapter() {
        legacyAdapter = LegacySeizureModelAdapter()
        if legacyAdapter?.isLoaded == false {
            legacyAdapter = nil
            print("⚠️ [SeizureInference] Legacy model not available — will use heuristic fallback")
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Heuristic Fallback Estimator
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Used when no CoreML model loads. Scores windows based on features that
    // are well-supported by seizure semiology literature:
    //   • High-frequency rhythmic motion
    //   • Sudden HR surge uncoupled from gradual exercise HR rise
    //   • Post-event sudden stillness (tonic phase)
    //   • Motion + HR correlated spike (not exercise pattern)
    //
    // IMPORTANT: This heuristic is conservative by design. It will have low
    // sensitivity but low false-alarm rate — better than no filtering at all,
    // and the temporal smoother provides additional confirmation gating.

    private func heuristicEstimate(features: WindowFeatures) -> Double {
        var score = 0.0

        // Rhythmic motion in seizure-relevant frecuency band (3–10 Hz)
        if features.dominantFrequency >= 3.0 && features.dominantFrequency <= 10.0 {
            score += 0.25
        }

        // High spectral power in mid band + high periodicity = rhythmic clonic-like motion
        if features.spectralPowerMid > features.spectralPowerLow &&
           features.periodicityScore > 0.6 {
            score += 0.20
        }

        // Sudden HR surge (not gradual as in exercise): steep slope + high delta
        if features.hrSlope > 2.0 && features.hrDeltaFromBaseline > 20 {
            score += 0.20
        }

        // High SMA + high jerk variance = chaotic, non-periodic motion (tonic-like)
        if features.signalMagnitudeArea > 3.0 && features.jerkVariance > 0.5 {
            score += 0.15
        }

        // Post-event stillness from previous window (sudden drop after motion)
        if features.postEventStillness > 0.4 {
            score += 0.10
        }

        // Sleep context + rhythmic motion = elevated suspicion (nighttime seizures common)
        if features.isAsleepFlag > 0.5 && features.periodicityScore > 0.5 {
            score += 0.10
        }

        return min(score, 1.0)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Future: Personalised CoreML Model
    // ─────────────────────────────────────────────────────────────────────────

    // TODO: Uncomment when SeizureDetector.mlmodel is trained and
    // ModelPersonalizationManager can supply a personalised variant.
    //
    // private func predictWithPersonalisedModel(features: WindowFeatures) -> Double? {
    //     guard let url = personalizedModelURL,
    //           let compiledURL = try? MLModel.compileModel(at: url),
    //           let model = try? MLModel(contentsOf: compiledURL) else { return nil }
    //     // Build input MLFeatureProvider from WindowFeatures, run prediction
    //     // return output probability
    //     return nil
    // }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LegacySeizureModelAdapter
// ─────────────────────────────────────────────────────────────────────────────
//
// Wraps the original SeizureModel.mlmodel which expects an 11-feature input.
// Maps the new WindowFeatures struct into the old interface.
// This is FALLBACK ONLY — not the primary detection architecture.
// Keep until SeizureDetector.mlmodel replaces it.

final class LegacySeizureModelAdapter {

    private var model: SeizureModel?

    var isLoaded: Bool { model != nil }

    init() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            model = try SeizureModel(configuration: config)
            print("♻️ [LegacyAdapter] SeizureModel.mlmodel loaded as fallback")
        } catch {
            print("⚠️ [LegacyAdapter] Could not load SeizureModel.mlmodel: \(error.localizedDescription)")
            model = nil
        }
    }

    /// Map new WindowFeatures → old 11-feature input → run inference → return probability.
    func predict(features: WindowFeatures) -> Double? {
        guard let model = model else { return nil }

        // Map new rich features to the old 11-element interface:
        //   mean_acc, std_acc, max_acc, min_acc, sma,
        //   peak_count, zero_crossings, dominant_freq,
        //   hr_mean, hr_std, hr_slope
        //
        // max_acc is approximated from mean + peak-to-peak
        // min_acc is approximated from mean - peak-to-peak/2
        // peak_count is derived from jerkMean * approximate window count
        // zero_crossings placeholder remains 0.0

        let maxAcc    = features.accelMagMean + (features.accelPeakToPeak / 2.0)
        let minAcc    = max(0, features.accelMagMean - (features.accelPeakToPeak / 2.0))
        let peakCount = features.jerkMean * 10.0  // crude approximation
        let hrStd     = sqrt(features.jerkVariance) // repurpose jerk variance as HR std proxy

        do {
            let input = SeizureModelInput(
                mean_acc:       features.accelMagMean,
                std_acc:        features.accelMagStd,
                max_acc:        maxAcc,
                min_acc:        minAcc,
                sma:            features.signalMagnitudeArea,
                peak_count:     peakCount,
                zero_crossings: 0.0,
                dominant_freq:  features.dominantFrequency,
                hr_mean:        features.hrMean,
                hr_std:         hrStd,
                hr_slope:       features.hrSlope
            )
            let output = try model.prediction(input: input)
            // The old model outputs a `probabilities` dict; class 1 = seizure
            return output.probabilities[1] ?? 0.0
        } catch {
            print("❌ [LegacyAdapter] Prediction failed: \(error.localizedDescription)")
            return nil
        }
    }
}
