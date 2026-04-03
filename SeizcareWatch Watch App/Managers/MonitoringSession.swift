// MonitoringSession.swift
// SeizcareWatch Watch App — Managers
//
// PURPOSE: Abstraction over HKWorkoutSession used to keep the Watch
// active for continuous heart rate and motion collection.
//
// WHY: Using HKWorkoutSession directly everywhere is brittle — if Apple changes
// the recommended keep-alive mechanism, only this file needs updating.
// All consumers use MonitoringSession.shared without caring about the mechanism.
//
// Current implementation: HKWorkoutSession (type: .other, location: .indoor)
// Future: May switch to background session app types or other approaches.

import Foundation
import HealthKit

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - MonitoringSessionDelegate
// ─────────────────────────────────────────────────────────────────────────────

protocol MonitoringSessionDelegate: AnyObject {
    /// Called when a new live heart rate reading arrives
    func monitoringSession(_ session: MonitoringSession, didReceiveHeartRate bpm: Double)
    /// Called when the session state changes
    func monitoringSession(_ session: MonitoringSession, didChangeState isActive: Bool)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - MonitoringSession
// ─────────────────────────────────────────────────────────────────────────────

final class MonitoringSession: NSObject {

    // MARK: Singleton

    static let shared = MonitoringSession()

    // MARK: State

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private(set) var isActive: Bool = false

    // MARK: Delegate

    weak var delegate: MonitoringSessionDelegate?

    // MARK: Init

    private override init() {
        super.init()
        print("⌚ [MonitoringSession] Initialised")
    }

    // MARK: - Start

    func start() {
        guard !isActive else {
            print("⌚ [MonitoringSession] Already active")
            return
        }

        let config = HKWorkoutConfiguration()
        config.activityType  = .other
        config.locationType  = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let buildr  = session.associatedWorkoutBuilder()

            session.delegate = self
            buildr.delegate  = self
            buildr.dataSource = HKLiveWorkoutDataSource(
                healthStore:           healthStore,
                workoutConfiguration:  config
            )

            let startDate = Date()
            session.startActivity(with: startDate)
            buildr.beginCollection(withStart: startDate) { success, error in
                if success {
                    print("✅ [MonitoringSession] HKWorkoutSession started — continuous monitoring active")
                } else {
                    print("❌ [MonitoringSession] beginCollection failed: \(error?.localizedDescription ?? "unknown")")
                }
            }

            workoutSession = session
            builder        = buildr
            isActive       = true
            delegate?.monitoringSession(self, didChangeState: true)

        } catch {
            print("❌ [MonitoringSession] Could not start HKWorkoutSession: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop

    func stop() {
        guard isActive, let session = workoutSession else { return }
        session.end()
        builder?.endCollection(withEnd: Date()) { _, _ in
            print("🛑 [MonitoringSession] HKWorkoutSession ended")
        }
        workoutSession = nil
        builder        = nil
        isActive       = false
        delegate?.monitoringSession(self, didChangeState: false)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HKWorkoutSessionDelegate
// ─────────────────────────────────────────────────────────────────────────────

extension MonitoringSession: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        print("⚡ [MonitoringSession] State: \(fromState.rawValue) → \(toState.rawValue)")
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ [MonitoringSession] Session failed: \(error.localizedDescription)")
        isActive = false
        delegate?.monitoringSession(self, didChangeState: false)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HKLiveWorkoutBuilderDelegate
// ─────────────────────────────────────────────────────────────────────────────

extension MonitoringSession: HKLiveWorkoutBuilderDelegate {

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(hrType),
              let qty = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity() else {
            return
        }
        let bpm = qty.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
        print(String(format: "💓 [MonitoringSession] Live HR: %.0f BPM", bpm))
        delegate?.monitoringSession(self, didReceiveHeartRate: bpm)
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
