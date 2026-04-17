// DecisionEngine.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Orchestrates the full two-stage detection pipeline.
//   1. Feature extraction
//   2. Artifact filter  → suppress if definite normal activity
//   3. Seizure inference → raw probability
//   4. Temporal smoothing → smoothed probability + confirmation vote
//   5. Sensitivity policy → final threshold comparison
//   6. HR confirmation (for Low sensitivity)
//   7. Produce a fully-explainable DetectionDecision
//
// RULES (from spec — strictly enforced here):
//   ❌  Never alert from raw model score alone
//   ❌  Never treat sensitivity level as a seizure class label
//   ❌  Never rely on motion alone
//   ✅  Always use artifact filtering + smoothing + context
//   ✅  Every decision must have a reason string
//   ✅  Full debug log on every cycle

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DecisionEngine
// ─────────────────────────────────────────────────────────────────────────────

final class DecisionEngine {

    // MARK: Singleton

    static let shared = DecisionEngine()

    // MARK: Dependencies
    // All are injected lazily via singletons to keep the engine testable.

    private let artifactFilter  = ArtifactInferenceService.shared
    private let seizureInference = SeizureInferenceService.shared
    private let smoother        = TemporalSmoothingEngine()

    // MARK: State

    private var previousSmoothedRisk: Double = 0

    // MARK: Callbacks

    /// Fired on the main thread for every confirmed seizure alert.
    var onSeizureAlertFired: ((DetectionDecision) -> Void)?

    // MARK: Init

    private init() {
        // print("⚙️ [DecisionEngine] Initialised")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Main Entry Point
    // ─────────────────────────────────────────────────────────────────────────

    /// Called by SeizureDetectionManager for every ready window of samples.
    /// Runs the full pipeline and returns an explainable DetectionDecision.
    @discardableResult
    func evaluate(samples: [SensorSample],
                  context: DetectionContext) -> DetectionDecision {

        let policy = SensitivityPolicy.policy(for: context.sensitivityLevel)
        let timestamp = Date()

        // -----------------------------------------------------------------
        // STAGE 0: Guard — insufficient data
        // -----------------------------------------------------------------
        guard samples.count >= 50 else {  // at minimum 1 second
            let reason = "Insufficient samples — \(samples.count) received, need ≥50"
            // print("ℹ️ [DecisionEngine] \(reason)")
            return makeDecision(
                outcome:          .insufficientData,
                artifactProb:     0,
                seizureProb:      0,
                smoothedProb:     0,
                activityClass:    .unknown,
                policy:           policy,
                context:          context,
                hrConfirmed:      false,
                reason:           reason,
                timestamp:        timestamp
            )
        }

        // -----------------------------------------------------------------
        // STAGE 1: Feature Extraction
        // -----------------------------------------------------------------
        let smoothingSnapshot = smoother.recentProbabilities()
        let positiveCount     = smoothingSnapshot.filter { $0 >= policy.seizureThreshold }.count

        guard let features = FeatureExtractor.extract(
            from:                samples,
            context:             context,
            previousRisk:        previousSmoothedRisk,
            positiveWindowCount: positiveCount,
            rhythmicDuration:    0,   // updated from smoother result below
            postEventStillness:  0
        ) else {
            let reason = "Feature extraction returned nil — empty sample array"
            // print("⚠️ [DecisionEngine] \(reason)")
            return makeDecision(
                outcome: .insufficientData, artifactProb: 0, seizureProb: 0,
                smoothedProb: 0, activityClass: .unknown, policy: policy,
                context: context, hrConfirmed: false, reason: reason, timestamp: timestamp
            )
        }

        // -----------------------------------------------------------------
        // STAGE 2: Artifact Filter (Model 1)
        // -----------------------------------------------------------------
        let artifactResult  = artifactFilter.classify(features: features)
        let artifactProb    = artifactResult.normalActivityProbability
        let activityClass   = artifactResult.activityClass

        // print(String(format: "🔍 [DecisionEngine] Artifact → %@ p=%.3f | %@",
        //              activityClass.rawValue, artifactProb, artifactResult.reason))

        // Suppress: ML model identified a definite normal-activity class
        // (walking, workout, stairs_motion, or sit — see ActivityClass.isDefinitelyNormal)
        if activityClass.isDefinitelyNormal {
            let reason = "SUPPRESSED by artifact filter — \(activityClass.rawValue) conf=\(String(format:"%.3f",artifactProb)) | \(artifactResult.reason)"
            // print("🚫 [DecisionEngine] \(reason)")

            // Still feed probability 0 into smoother to keep history coherent
            _ = smoother.feed(probability: 0, policy: policy,
                              accelMagMean: features.accelMagMean,
                              periodicityScore: features.periodicityScore)

            return makeDecision(
                outcome: .suppressedByArtifact, artifactProb: artifactProb,
                seizureProb: 0, smoothedProb: previousSmoothedRisk,
                activityClass: activityClass, policy: policy, context: context,
                hrConfirmed: false, reason: reason, timestamp: timestamp
            )
        }

        // -----------------------------------------------------------------
        // STAGE 3: Seizure Model (Model 2)
        // -----------------------------------------------------------------
        let seizureProb = seizureInference.predict(features: features)

        // print(String(format: "🔬 [DecisionEngine] Seizure inference → p=%.4f", seizureProb))

        // -----------------------------------------------------------------
        // STAGE 4: Temporal Smoothing + Confirmation Vote
        // -----------------------------------------------------------------
        let smoothing = smoother.feed(
            probability:      seizureProb,
            policy:           policy,
            accelMagMean:     features.accelMagMean,
            periodicityScore: features.periodicityScore
        )

        let smoothedProb = smoothing.smoothedProbability
        previousSmoothedRisk = smoothedProb

        // print(String(format: "⌛ [DecisionEngine] Smoothed → %.4f | positive=%d/%d rhythmic=%.1fs",
        //              smoothedProb, smoothing.positiveWindowCount,
        //              policy.windowPoolSize, smoothing.rhythmicDuration))

        // Low/soft artifact signal: downgrade but don't suppress
        // If artifact filter found a probable activity (0.5–0.85) — reduce seizure prob
        let adjustedSeizureProb: Double
        if artifactProb > 0.5 {
            let suppressionFactor = 1.0 - (artifactProb - 0.5) * 2.0  // 0.5→1.0, 0.85→0.30
            adjustedSeizureProb = smoothedProb * suppressionFactor
            // print(String(format: "⬇️ [DecisionEngine] Soft artifact suppression factor=%.2f → adjusted=%.4f",
            //              suppressionFactor, adjustedSeizureProb))
        } else {
            adjustedSeizureProb = smoothedProb
        }

        // -----------------------------------------------------------------
        // STAGE 5: Smoothing confirmation gate
        // -----------------------------------------------------------------
        guard smoothing.confirmationPassed else {
            let reason = String(format: "BELOW CONFIRMATION — smoothed=%.3f positive=%d/%d (need %d)",
                                adjustedSeizureProb, smoothing.positiveWindowCount,
                                policy.windowPoolSize, policy.requiredPositiveCount)
            // print("⬇️ [DecisionEngine] \(reason)")
            return makeDecision(
                outcome: .suppressedBySmoothing, artifactProb: artifactProb,
                seizureProb: seizureProb, smoothedProb: adjustedSeizureProb,
                activityClass: activityClass, policy: policy, context: context,
                hrConfirmed: false, reason: reason, timestamp: timestamp
            )
        }

        // -----------------------------------------------------------------
        // STAGE 6: Threshold + HR Confirmation
        // -----------------------------------------------------------------
        guard adjustedSeizureProb >= policy.seizureThreshold else {
            let reason = String(format: "BELOW THRESHOLD — smoothed=%.3f < threshold=%.2f",
                                adjustedSeizureProb, policy.seizureThreshold)
            // print("⬇️ [DecisionEngine] \(reason)")
            return makeDecision(
                outcome: .belowThreshold, artifactProb: artifactProb,
                seizureProb: seizureProb, smoothedProb: adjustedSeizureProb,
                activityClass: activityClass, policy: policy, context: context,
                hrConfirmed: false, reason: reason, timestamp: timestamp
            )
        }

        // HR confirmation (required for Low sensitivity)
        var hrConfirmed = false
        if policy.requireHRConfirmation {
            hrConfirmed = features.hrDeltaFromBaseline >= policy.hrConfirmationDelta
            if !hrConfirmed {
                let reason = String(format: "HR CONFIRMATION FAILED — delta=%.0f < required=%.0f | smoothed=%.3f > threshold=%.2f",
                                    features.hrDeltaFromBaseline, policy.hrConfirmationDelta,
                                    adjustedSeizureProb, policy.seizureThreshold)
                // print("⬇️ [DecisionEngine] \(reason)")
                return makeDecision(
                    outcome: .suppressedByContext, artifactProb: artifactProb,
                    seizureProb: seizureProb, smoothedProb: adjustedSeizureProb,
                    activityClass: activityClass, policy: policy, context: context,
                    hrConfirmed: false, reason: reason, timestamp: timestamp
                )
            }
        }

        // -----------------------------------------------------------------
        // STAGE 7: ALERT — all gates passed
        // -----------------------------------------------------------------
        let hrStr = policy.requireHRConfirmation
            ? String(format: " hrDelta=+%.0f (confirmed)", features.hrDeltaFromBaseline)
            : ""
        let reason = String(format: """
            🚨 SEIZURE SUSPECTED — artifact=%.3f seizure=%.3f smoothed=%.3f \
            threshold=%.2f (%d/%d windows) rhythmic=%.1fs%@
            """,
            artifactProb, seizureProb, adjustedSeizureProb,
            policy.seizureThreshold,
            smoothing.positiveWindowCount, policy.windowPoolSize,
            smoothing.rhythmicDuration, hrStr)

        print("🚨 [DecisionEngine] \(reason)")

        let decision = makeDecision(
            outcome: .seizureSuspected, artifactProb: artifactProb,
            seizureProb: seizureProb, smoothedProb: adjustedSeizureProb,
            activityClass: activityClass, policy: policy, context: context,
            hrConfirmed: hrConfirmed, reason: reason, timestamp: timestamp
        )

        DispatchQueue.main.async { [weak self] in
            self?.onSeizureAlertFired?(decision)
        }

        return decision
    }

    // MARK: - Reset

    /// Call when an alert is dismissed or monitoring restarts.
    func reset() {
        smoother.reset()
        previousSmoothedRisk = 0
        // print("🔄 [DecisionEngine] State reset")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Factory
    // ─────────────────────────────────────────────────────────────────────────

    private func makeDecision(outcome: DetectionOutcome,
                              artifactProb: Double,
                              seizureProb: Double,
                              smoothedProb: Double,
                              activityClass: ActivityClass,
                              policy: SensitivityPolicy,
                              context: DetectionContext,
                              hrConfirmed: Bool,
                              reason: String,
                              timestamp: Date) -> DetectionDecision {
        return DetectionDecision(
            artifactProbability: artifactProb,
            seizureProbability:  seizureProb,
            smoothedProbability: smoothedProb,
            activityClass:       activityClass,
            outcome:             outcome,
            sensitivityLevel:    context.sensitivityLevel,
            thresholdUsed:       policy.seizureThreshold,
            requiredPositive:    policy.requiredPositiveCount,
            windowPoolSize:      policy.windowPoolSize,
            isAsleep:            context.isCurrentlyAsleep,
            isWorkoutActive:     context.isWorkoutActive,
            hrConfirmed:         hrConfirmed,
            reason:              reason,
            timestamp:           timestamp
        )
    }
}
