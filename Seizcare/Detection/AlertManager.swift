// AlertManager.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Receives confirmed DetectionDecision and handles the alert lifecycle:
//   1. Triggers EmergencyService countdown
//   2. Saves a DetectionSession record
//   3. Schedules the post-alert feedback prompt
//
// Alert de-duplication: once an alert fires, a cooldown period prevents
// another immediate alert (prevents repeated alerts during extended events).

import Foundation
import UIKit

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AlertManager
// ─────────────────────────────────────────────────────────────────────────────

final class AlertManager {

    // MARK: Singleton

    static let shared = AlertManager()

    // MARK: Configuration

    /// Minimum time between successive confirmed alerts (seconds)
    private let alertCooldownSeconds: TimeInterval = 120

    // MARK: State

    private var lastAlertDate: Date?
    private var currentSessionID: UUID?

    // MARK: Init

    private init() {
        print("🔔 [AlertManager] Initialised — cooldown: \(alertCooldownSeconds)s")
    }

    // MARK: - Public API

    /// Called by DecisionEngine when a seizure is suspected.
    /// Main-thread safe (DecisionEngine dispatches callback on main thread).
    func handleConfirmedDecision(_ decision: DetectionDecision,
                                 features: WindowFeatures) {
        guard decision.isSeizureSuspected else { return }

        // Cooldown guard
        if let last = lastAlertDate,
           Date().timeIntervalSince(last) < alertCooldownSeconds {
            print("⏳ [AlertManager] Alert suppressed — in cooldown (\(Int(alertCooldownSeconds))s)")
            return
        }

        lastAlertDate = Date()

        // 1. Save detection session locally
        let session = DetectionSession(decision: decision, features: features)
        currentSessionID = session.id
        DetectionSessionStore.shared.save(session: session)

        // 2. Trigger emergency countdown
        print("🚨 [AlertManager] Triggering emergency countdown — session: \(session.id)")
        EmergencyService.shared.triggerWithCountdown()

        // 3. Schedule feedback prompt after alert resolves
        //    We listen for the countdown dismissal notification and then present feedback.
        schedulePostAlertFeedback(for: session.id)
    }

    // MARK: - Post-Alert Feedback

    /// Registers to present the immediate feedback UI after the alert dismisses.
    private func schedulePostAlertFeedback(for sessionID: UUID) {
        // FeedbackViewController will be presented once the app returns to foreground
        // after the alert. We store the pending session ID and check on next app activation.
        FeedbackLogger.shared.markPendingFeedback(sessionID: sessionID)
    }

    /// Called by AppDelegate / SceneDelegate on foreground transition.
    /// Presents the lightweight feedback sheet if there's a pending unresolved alert.
    func presentPendingFeedbackIfNeeded(from viewController: UIViewController) {
        guard let sessionID = FeedbackLogger.shared.pendingFeedbackSessionID else { return }

        let feedbackVC = FeedbackViewController(sessionID: sessionID)
        feedbackVC.modalPresentationStyle = .pageSheet
        if let sheet = feedbackVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        viewController.present(feedbackVC, animated: true)
    }
}
