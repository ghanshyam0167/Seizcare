// ArtifactInferenceService.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Model 1 — Artifact / Activity Filter.
// Determines whether the current window is explained by normal activity.
// If yes, seizure detection is suppressed.
//
// Current implementation: Rule-based heuristics (placeholder).
// TODO: Replace with ArtifactFilter.mlmodel (Core ML) when trained.
// The public API is identical whether using rules or a real model —
// swap the implementation inside classify() without changing callers.

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ArtifactInferenceService
// ─────────────────────────────────────────────────────────────────────────────

final class ArtifactInferenceService {

    // MARK: Singleton

    static let shared = ArtifactInferenceService()
    private init() {
        // TODO: Load ArtifactFilter.mlmodel here when available.
        // let config = MLModelConfiguration()
        // artifactModel = try? ArtifactFilter(configuration: config)
        print("🔍 [ArtifactFilter] Initialised — using rule-based placeholder")
    }

    // MARK: - Public API

    /// Classify a feature window.
    /// Returns an `ArtifactFilterResult` with probability + class + debug reason.
    func classify(features: WindowFeatures, context: DetectionContext) -> ArtifactFilterResult {
        // TODO: When ArtifactFilter.mlmodel is available, call it here:
        // return classifyWithModel(features: features)

        return classifyWithRules(features: features, context: context)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Rule-Based Heuristics (Placeholder)
    // ─────────────────────────────────────────────────────────────────────────
    //
    // DESIGN NOTES:
    //   • Each rule sets a candidate probability and reason string.
    //   • We take the HIGHEST probability from all rules (most-confident explanation).
    //   • Rules are independent and use features extracted from the same window.
    //   • All thresholds here are initial/tunable constants.
    //   • False-alarm suppression logic is HERE, not in the seizure model.
    //
    // IMPORTANT: These rules intentionally over-suppress to reduce false alarms
    // during the bootstrap period when no trained model exists. Once
    // ArtifactFilter.mlmodel is trained on real labeled data, these rules are retired.

    private func classifyWithRules(features: WindowFeatures,
                                   context: DetectionContext) -> ArtifactFilterResult {

        var bestProb   = 0.0
        var bestClass  = ActivityClass.unknown
        var bestReason = "No artifact pattern matched"

        // -----------------------------------------------------------------
        // Rule 1: Running
        // High SMA + high jerk + dominant frequency in cadence range (1.5–4 Hz)
        // + gradual HR elevation
        // -----------------------------------------------------------------
        let runLikelihood = runningScore(features: features, context: context)
        if runLikelihood > bestProb {
            bestProb   = runLikelihood
            bestClass  = .running
            bestReason = String(format: "Running pattern — SMA=%.2f jerk=%.2f freq=%.1f Hz hr_slope=%.1f",
                                features.signalMagnitudeArea, features.jerkMean,
                                features.dominantFrequency, features.hrSlope)
        }

        // -----------------------------------------------------------------
        // Rule 2: Walking
        // Moderate SMA + low-frequency dominant (0.8–2.0 Hz) + low jerk variance
        // -----------------------------------------------------------------
        let walkLikelihood = walkingScore(features: features)
        if walkLikelihood > bestProb {
            bestProb   = walkLikelihood
            bestClass  = .walking
            bestReason = String(format: "Walking pattern — SMA=%.2f freq=%.1f Hz periodicity=%.2f",
                                features.signalMagnitudeArea, features.dominantFrequency,
                                features.periodicityScore)
        }

        // -----------------------------------------------------------------
        // Rule 3: Active workout (context flag + sustained elevated HR)
        // Suppresses when user explicitly started a workout session.
        // -----------------------------------------------------------------
        if context.isWorkoutActive {
            let workoutLikelihood = workoutScore(features: features, context: context)
            if workoutLikelihood > bestProb {
                bestProb   = workoutLikelihood
                bestClass  = .workout
                bestReason = String(format: "Active workout session — HR=%.0f baseline=%.0f delta=%.0f",
                                    features.hrMean, features.userBaselineHR,
                                    features.hrDeltaFromBaseline)
            }
        }

        // -----------------------------------------------------------------
        // Rule 4: Sleep movement
        // Low SMA + high periodicity + low HR + asleep context
        // -----------------------------------------------------------------
        let sleepMoveLikelihood = sleepMovementScore(features: features, context: context)
        if sleepMoveLikelihood > bestProb {
            bestProb   = sleepMoveLikelihood
            bestClass  = .sleepMovement
            bestReason = String(format: "Sleep movement — asleep=%d SMA=%.2f periodicity=%.2f",
                                context.isCurrentlyAsleep ? 1 : 0,
                                features.signalMagnitudeArea, features.periodicityScore)
        }

        // -----------------------------------------------------------------
        // Rule 5: Brushing teeth
        // Very fast periodic oscillation (7–15 Hz) + wrist-local, brief
        // -----------------------------------------------------------------
        let brushLikelihood = brushingScore(features: features)
        if brushLikelihood > bestProb {
            bestProb   = brushLikelihood
            bestClass  = .brushingTeeth
            bestReason = String(format: "Brushing teeth pattern — freq=%.1f Hz SMA=%.2f",
                                features.dominantFrequency, features.signalMagnitudeArea)
        }

        // -----------------------------------------------------------------
        // Apply context override: if workout is ACTIVE AND motion is high,
        // always boost artifact probability to at least 0.65 to prevent
        // false alarms from workout intensity spikes.
        // -----------------------------------------------------------------
        if context.isWorkoutActive && features.signalMagnitudeArea > 4.0 && bestProb < 0.65 {
            bestProb   = max(bestProb, 0.65)
            bestClass  = .workout
            bestReason += " [workout-context boost]"
        }

        return ArtifactFilterResult(
            activityClass:             bestClass,
            normalActivityProbability: bestProb,
            reason:                    bestReason
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Individual Rule Scorers
    // ─────────────────────────────────────────────────────────────────────────

    /// Running score [0,1]
    private func runningScore(features: WindowFeatures, context: DetectionContext) -> Double {
        var score = 0.0
        // SMA: running typically > 2.5 g
        if features.signalMagnitudeArea > 2.5  { score += 0.30 }
        if features.signalMagnitudeArea > 4.0  { score += 0.15 }
        // Dominant frequency in running cadence 1.5–4 Hz (stride frequency)
        if features.dominantFrequency >= 1.5 && features.dominantFrequency <= 4.0 { score += 0.25 }
        // Jerk elevated but consistent
        if features.jerkMean > 0.3             { score += 0.10 }
        // HR elevation — gradual (running not sudden spike)
        if features.hrSlope >= 0.0 && features.hrSlope < 2.0 && features.hrDeltaFromBaseline > 10 { score += 0.10 }
        // Moderate periodicity (running is rhythmic)
        if features.periodicityScore > 0.4     { score += 0.10 }
        return min(score, 1.0)
    }

    /// Walking score [0,1]
    private func walkingScore(features: WindowFeatures) -> Double {
        var score = 0.0
        if features.signalMagnitudeArea > 0.8 && features.signalMagnitudeArea < 3.0 { score += 0.30 }
        if features.dominantFrequency >= 0.8 && features.dominantFrequency <= 2.0   { score += 0.35 }
        if features.periodicityScore > 0.5     { score += 0.20 }
        if features.jerkVariance < 0.15        { score += 0.15 }
        return min(score, 1.0)
    }

    /// Workout score [0,1]
    private func workoutScore(features: WindowFeatures, context: DetectionContext) -> Double {
        var score = 0.0
        if context.isWorkoutActive            { score += 0.35 }
        if features.hrDeltaFromBaseline > 20  { score += 0.20 }
        if features.hrDeltaFromBaseline > 40  { score += 0.15 }
        if features.hrSlope > 0               { score += 0.10 }
        if features.signalMagnitudeArea > 1.5 { score += 0.20 }
        return min(score, 1.0)
    }

    /// Sleep movement score [0,1]
    private func sleepMovementScore(features: WindowFeatures,
                                    context: DetectionContext) -> Double {
        var score = 0.0
        if context.isCurrentlyAsleep          { score += 0.40 }
        if features.signalMagnitudeArea < 1.5 { score += 0.20 }
        // Sleep movement is often somewhat periodic (tossing/turning)
        if features.periodicityScore > 0.3 && features.periodicityScore < 0.8 { score += 0.20 }
        // Low HR at rest
        if features.hrMean < context.baselineHR + 10 { score += 0.20 }
        return min(score, 1.0)
    }

    /// Brushing teeth score [0,1]
    private func brushingScore(features: WindowFeatures) -> Double {
        var score = 0.0
        // Brushing is a fast back-and-forth: 7–15 Hz dominant
        if features.dominantFrequency >= 7.0 && features.dominantFrequency <= 15.0 { score += 0.50 }
        // Moderate but not extreme amplitude
        if features.signalMagnitudeArea > 0.5 && features.signalMagnitudeArea < 3.0 { score += 0.25 }
        // High spectral power in high frequency band
        if features.spectralPowerHigh > features.spectralPowerLow { score += 0.25 }
        return min(score, 1.0)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Future: CoreML Model Classifier
    // ─────────────────────────────────────────────────────────────────────────

    // TODO: Uncomment and implement when ArtifactFilter.mlmodel is trained.
    //
    // private var artifactModel: ArtifactFilter?
    //
    // private func classifyWithModel(features: WindowFeatures) -> ArtifactFilterResult {
    //     guard let model = artifactModel else {
    //         return classifyWithRules(features: features, context: .init())
    //     }
    //     let input = ArtifactFilterInput(
    //         accel_mag_mean: features.accelMagMean,
    //         sma: features.signalMagnitudeArea,
    //         dominant_freq: features.dominantFrequency,
    //         periodicity: features.periodicityScore,
    //         hr_delta: features.hrDeltaFromBaseline,
    //         is_workout: features.isWorkoutFlag,
    //         is_asleep: features.isAsleepFlag
    //         // ... all features ...
    //     )
    //     guard let output = try? model.prediction(input: input) else {
    //         return classifyWithRules(features: features, context: .init())
    //     }
    //     let cls = ActivityClass(rawValue: output.activity_class) ?? .unknown
    //     let prob = output.classProbability[output.activity_class] ?? 0.0
    //     return ArtifactFilterResult(
    //         activityClass: cls,
    //         normalActivityProbability: prob,
    //         reason: "ArtifactFilter.mlmodel → \(output.activity_class) p=\(prob)"
    //     )
    // }
}
