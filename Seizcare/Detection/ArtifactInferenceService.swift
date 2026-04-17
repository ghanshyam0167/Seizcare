// ArtifactInferenceService.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Model 1 — Artifact / Activity Filter.
// Determines whether the current window is explained by a normal daily activity.
// If yes, seizure detection is suppressed in DecisionEngine.
//
// Implementation: ArtifactFilter.mlmodel (Core ML, scikit-learn origin).
// Input:  30 named scalar Double features via MLDictionaryFeatureProvider.
// Output: activityLabel (String), activityScores ([String: Double])
//
// Emergency fallback: if the model fails to load, always returns .unknown
// (probability 0) — no suppression occurs.

import Foundation
import CoreML

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ArtifactInferenceService
// ─────────────────────────────────────────────────────────────────────────────

final class ArtifactInferenceService {

    // MARK: Singleton

    static let shared = ArtifactInferenceService()

    /// Loaded Core ML model. Nil only if bundle load fails (emergency fallback).
    private var artifactModel: MLModel?

    // MARK: - Init

    private init() {
        // Use a safe optional URL lookup — the stale generated ArtifactFilter class
        // force-unwraps bundle.url(forResource:) with !, which causes EXC_BAD_ACCESS
        // if the .mlmodelc is not yet compiled into the bundle. We guard safely here.
        guard let modelURL = Bundle.main.url(forResource: "ArtifactFilter",
                                             withExtension: "mlmodelc") else {
            // print("⚠️ [ArtifactFilter] ArtifactFilter.mlmodelc not found in bundle")
            // print("⚠️ [ArtifactFilter] Running in pass-through mode — no artifact suppression")
            artifactModel = nil
            return
        }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            artifactModel = model
            // print("🚀 [ArtifactFilter] CoreML model loaded successfully from \(modelURL.lastPathComponent)")
        } catch {
            // EMERGENCY FALLBACK: model file found but failed to load
            // print("⚠️ [ArtifactFilter] Model load failed: \(error.localizedDescription)")
            // print("⚠️ [ArtifactFilter] Running in pass-through mode — no artifact suppression")
            artifactModel = nil
        }
    }

    // MARK: - Public API

    /// Classify a feature window using ArtifactFilter.mlmodel.
    ///
    /// Returns an `ArtifactFilterResult` containing:
    ///   - `activityClass`              — mapped from the model's predicted label
    ///   - `normalActivityProbability`  — confidence for the predicted class
    ///   - `reason`                     — brief debug string
    ///
    /// If the model is unavailable (emergency fallback), returns `.unknown` with
    /// probability 0 so the caller never suppresses a window.
    func classify(features: WindowFeatures) -> ArtifactFilterResult {
        guard let model = artifactModel else {
            // EMERGENCY FALLBACK — model not loaded
            return ArtifactFilterResult(
                activityClass: .unknown,
                normalActivityProbability: 0,
                reason: "⚠️ ArtifactFilter unavailable — pass-through"
            )
        }

        do {
            let result = try runInference(model: model, features: features)
            // Feed every live result to the monitor (UI + console observer)
            ArtifactLiveMonitor.shared.record(result: result)
            return result
        } catch {
            // print("❌ [ArtifactFilter] Prediction error: \(error.localizedDescription)")
            return ArtifactFilterResult(
                activityClass: .unknown,
                normalActivityProbability: 0,
                reason: "❌ Prediction failed — pass-through"
            )
        }
    }

    // MARK: - Core ML Inference

    /// Runs inference using MLDictionaryFeatureProvider.
    private func runInference(model: MLModel, features: WindowFeatures) throws -> ArtifactFilterResult {

        // Build the 30-input feature dictionary
        let inputDict: [String: Any] = [
            "acc_mean_x":        features.accMeanX,
            "acc_mean_y":        features.accMeanY,
            "acc_mean_z":        features.accMeanZ,
            "acc_std_x":         features.accStdX,
            "acc_std_y":         features.accStdY,
            "acc_std_z":         features.accStdZ,
            "acc_min_x":         features.accMinX,
            "acc_min_y":         features.accMinY,
            "acc_min_z":         features.accMinZ,
            "acc_max_x":         features.accMaxX,
            "acc_max_y":         features.accMaxY,
            "acc_max_z":         features.accMaxZ,
            "acc_range_x":       features.accMaxX - features.accMinX,
            "acc_range_y":       features.accMaxY - features.accMinY,
            "acc_range_z":       features.accMaxZ - features.accMinZ,
            "acc_mean_mag":      features.accelMagMean,
            "acc_std_mag":       features.accelMagStd,
            "acc_min_mag":       features.accelMagMin,
            "acc_max_mag":       features.accelMagMax,
            "acc_rms_mag":       sqrt(features.accelEnergy),
            "acc_sma":           features.signalMagnitudeArea,
            "acc_energy":        features.accelEnergy,
            "acc_dom_freq":      features.dominantFrequency,
            "acc_zc_x":          features.accZcX,
            "acc_zc_y":          features.accZcY,
            "acc_zc_z":          features.accZcZ,
            "jerk_mean":         features.jerkMean,
            "jerk_std":          sqrt(features.jerkVariance),
            "jerk_rms":          features.jerkRms,
            "samples_in_window": features.samplesInWindow,
        ]

        let provider = try MLDictionaryFeatureProvider(dictionary: inputDict)
        let outProvider = try model.prediction(from: provider)

        // ── Step 1: Read the predicted label ─────────────────────────────────
        let labelFeature = outProvider.featureValue(for: "activityLabel")
                        ?? outProvider.featureValue(for: "classLabel")
        guard let labelFeature = labelFeature else {
            // print("❌ [ArtifactFilter] No label key found. Available output keys: \(outProvider.featureNames)")
            throw NSError(domain: "ArtifactFilter", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No label output found (tried activityLabel, classLabel)"])
        }
        let predictedLabel = labelFeature.stringValue

        // ── Step 2: Read scores / probabilities ─────────────────────────────
        let scoreFeature = outProvider.featureValue(for: "activityScores")
                        ?? outProvider.featureValue(for: "classProbability")
                        ?? outProvider.featureValue(for: "classLabel_probs")

        var rawScores: [String: Double] = [:]
        if let scoreFeature = scoreFeature {
            let nsDict = scoreFeature.dictionaryValue
            for (key, val) in nsDict {
                if let k = key as? String, let v = val as? NSNumber {
                    rawScores[k] = v.doubleValue
                }
            }
        }

        // Normalize to 0–1 (handles both raw vote counts and probabilities)
        let scoreSum = rawScores.values.reduce(0, +)
        let normalizedScores: [String: Double]
        if scoreSum > 1.01 {
            normalizedScores = rawScores.mapValues { $0 / scoreSum }
        } else {
            normalizedScores = rawScores
        }

        let confidence = normalizedScores[predictedLabel] ?? 0.0

        let activityClass = ActivityClass.from(modelLabel: predictedLabel)
        let suppressed = activityClass.isDefinitelyNormal

        return ArtifactFilterResult(
            activityClass: activityClass,
            normalActivityProbability: confidence,
            reason: String(format: "ML → %@ (%.3f)", predictedLabel, confidence)
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ActivityClass model label mapping
// ─────────────────────────────────────────────────────────────────────────────

private extension ActivityClass {
    /// Map ArtifactFilter.mlmodel predicted string labels to enum cases.
    /// "rest" maps to .unknown — resting is not a definitive artifact class
    /// (it can overlap with postictal stillness).
    static func from(modelLabel: String) -> ActivityClass {
        switch modelLabel {
        case "walking":        return .walking
        case "workout":        return .workout
        case "stairs_motion":  return .stairsMotion
        case "sit":            return .sit
        default:               return .unknown  // includes "rest" and any future unrecognised label
        }
    }
}
