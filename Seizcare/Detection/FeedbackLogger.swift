// FeedbackLogger.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Capture and persist user feedback after alerts.
// Feedback feeds ThresholdAdaptationManager for safe per-context threshold tuning.
// Labels are NEVER used for immediate model retraining.
//
// Storage: local JSON + Supabase sync (local-first).

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FeedbackLogger
// ─────────────────────────────────────────────────────────────────────────────

final class FeedbackLogger {

    // MARK: Singleton

    static let shared = FeedbackLogger()

    // MARK: State

    private let queue = DispatchQueue(label: "com.seizcare.feedbackLogger", qos: .background)

    /// UserDefaults key for pending immediate feedback (persists across launches)
    private let pendingFeedbackKey = "pendingFeedbackSessionID"

    // MARK: Init

    private init() {
        print("📝 [FeedbackLogger] Initialised")
    }

    // MARK: - Pending Feedback

    /// Session awaiting immediate post-alert feedback.
    var pendingFeedbackSessionID: UUID? {
        get {
            guard let str = UserDefaults.standard.string(forKey: pendingFeedbackKey),
                  let uuid = UUID(uuidString: str) else { return nil }
            return uuid
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: pendingFeedbackKey)
        }
    }

    func markPendingFeedback(sessionID: UUID) {
        pendingFeedbackSessionID = sessionID
        print("📝 [FeedbackLogger] Pending feedback marked for session \(sessionID)")
    }

    func clearPendingFeedback() {
        pendingFeedbackSessionID = nil
    }

    // MARK: - Submit Feedback

    /// Record user feedback for a detection session.
    /// Propagates label to:
    ///   1. DetectionSessionStore (updates the session record with history)
    ///   2. ThresholdAdaptationManager (for safe threshold tuning)
    func submitFeedback(sessionID: UUID, label: FeedbackLabel, confidence: FeedbackConfidence? = nil, source: String = "immediate") {
        queue.async {
            print("✅ [FeedbackLogger] Feedback submitted — session: \(sessionID) label: \(label.rawValue)")

            // 1. Update session store
            let provenance = FeedbackProvenance(label: label, confidence: confidence, timestamp: Date(), source: source)
            DetectionSessionStore.shared.addFeedback(sessionID: sessionID, provenance: provenance)

            // 2. Feed into threshold adaptation (only on first feedback, or override? We'll just pass the latest)
            if let session = DetectionSessionStore.shared.session(for: sessionID) {
                ThresholdAdaptationManager.shared.recordFeedback(
                    label: label,
                    activityClass: ActivityClass(rawValue: session.activityClass) ?? .unknown,
                    wasAsleep: session.isAsleep,
                    wasWorkout: session.isWorkoutActive,
                    sensitivityLevel: SensitivityLevel(rawValue: session.sensitivityLevel) ?? .medium
                )
            }

            // 3. Clear pending
            DispatchQueue.main.async {
                self.clearPendingFeedback()
            }
        }
    }

    // MARK: - Analytics

    /// Returns feedback distribution across all recorded sessions.
    func feedbackSummary() -> [FeedbackLabel: Int] {
        let sessions = DetectionSessionStore.shared.alertSessions()
        var summary: [FeedbackLabel: Int] = [:]
        for session in sessions {
            if let label = session.feedbackLabel {
                summary[label, default: 0] += 1
            }
        }
        return summary
    }

    func falseAlarmRate() -> Double {
        let alerts = DetectionSessionStore.shared.alertSessions()
        let labeled = alerts.filter { $0.feedbackLabel != nil }
        guard !labeled.isEmpty else { return 0 }
        let falseAlarms = labeled.filter { $0.feedbackLabel == .falseAlarm || $0.feedbackLabel == .runningWorkout || $0.feedbackLabel == .sleepJerk }.count
        return Double(falseAlarms) / Double(labeled.count)
    }
}
