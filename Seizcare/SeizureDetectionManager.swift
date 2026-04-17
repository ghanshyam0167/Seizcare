// SeizureDetectionManager.swift
// Seizcare — Detection Pipeline Coordinator
//
// PURPOSE: Thin façade / coordinator — the public entry point for the detection pipeline.
// All orchestration logic lives in DecisionEngine; this class:
//   1. Owns the SensorBufferManager
//   2. Maintains the current DetectionContext (sleep, workout, sensitivity)
//   3. Bridges incoming SensorSamples to the DecisionEngine
//   4. Updates baselines from non-alert windows
//   5. Routes confirmed alerts to AlertManager
//
// CALLERS: WatchConnectivityManager.swift (iPhone side)
//   SeizureDetectionManager.shared.processSample(sample:)
//   SeizureDetectionManager.shared.updateContext(...)

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SeizureDetectionManager
// ─────────────────────────────────────────────────────────────────────────────

final class SeizureDetectionManager {

    // MARK: Singleton

    static let shared = SeizureDetectionManager()

    // MARK: - Dependencies

    private let buffer     = SensorBufferManager()
    private let engine     = DecisionEngine.shared
    private let baselines  = BaselineAdaptationManager.shared
    private let thresholds = ThresholdAdaptationManager.shared

    // MARK: - Context

    /// Current live context — updated from HealthKit / WatchConnectivity / SensitivityDataModel
    private var currentContext = DetectionContext()
    private let contextLock = DispatchQueue(label: "com.seizcare.sdm.context", qos: .userInitiated)

    // MARK: - Callbacks (optional convenience hooks for UI layers)

    /// Called on main thread when a new detection decision is produced (every 2s).
    var onDecision: ((DetectionDecision) -> Void)?

    // MARK: - Init

    private init() {
        setupBuffer()
        setupDecisionEngine()
        // print("✅ [SeizureDetectionManager] Initialised and ready")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Setup
    // ─────────────────────────────────────────────────────────────────────────

    private func setupBuffer() {
        buffer.onWindowReady = { [weak self] samples in
            self?.handleWindow(samples: samples)
        }
    }

    private func setupDecisionEngine() {
        engine.onSeizureAlertFired = { [weak self] decision in
            // Already on main thread (DecisionEngine guarantees this)
            guard let self else { return }
            // print("🚨 [SDM] Alert received from DecisionEngine — routing to AlertManager")
            // We need the last window features for the session store.
            // AlertManager will use last features cached in engine.
            AlertManager.shared.handleConfirmedDecision(decision, features: WindowFeatures())
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Public API
    // ─────────────────────────────────────────────────────────────────────────

    /// Route a single sensor sample from the Watch into the pipeline.
    /// Safe to call from any thread.
    func processSample(sample: SensorSample) {
        buffer.add(sample: sample)
    }

    /// Route a batch of sensor samples (preferred — reduces overhead).
    func processBatch(_ samples: [SensorSample]) {
        buffer.addBatch(samples)
    }

    /// Update context when sleep/workout/sensitivity state changes.
    /// Call from WatchConnectivityManager, SleepManager, or workout session callbacks.
    func updateContext(sleepHours: Double? = nil,
                       sevenDayAvg: Double? = nil,
                       isAsleep: Bool? = nil,
                       isWorkout: Bool? = nil,
                       sensitivity: SensitivityLevel? = nil,
                       latestHR: Double? = nil,
                       latestMotionSMA: Double? = nil) {
        contextLock.async { [weak self] in
            guard let self else { return }

            if let h  = sleepHours  { self.currentContext.sleepHoursLastNight = h }
            if let a  = sevenDayAvg { self.currentContext.sevenDaySleepAvg    = a }
            if let s  = isAsleep    { self.currentContext.isCurrentlyAsleep    = s }
            if let w  = isWorkout   { self.currentContext.isWorkoutActive      = w }
            if let sv = sensitivity { self.currentContext.sensitivityLevel     = sv }

            // Rebuild time-of-day normalisation every context update
            let seconds = Date().timeIntervalSince(Calendar.current.startOfDay(for: Date()))
            self.currentContext.timeOfDayNorm = seconds / 86400.0

            // Pull fresh baselines into context
            let bl = self.baselines.currentBaselines()
            self.currentContext.baselineHR          = bl.restingHR
            self.currentContext.baselineMotion       = bl.normalMotionSMA
            self.currentContext.seizureFreqProfile   = bl.seizureFreqProfile
            self.currentContext.sevenDaySleepAvg     = bl.avgSleepHours

            // Update HR baseline in background if we have a fresh reading
            if let hr = latestHR {
                self.baselines.updateHR(
                    hr,
                    isWorkoutActive: self.currentContext.isWorkoutActive,
                    motionLevel:     latestMotionSMA ?? bl.normalMotionSMA
                )
            }
        }
    }

    /// Reset detection state (call on app foreground after an alert is dismissed)
    func resetState() {
        engine.reset()
        buffer.reset()
        // print("🔄 [SDM] Detection state reset")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Window Evaluation
    // ─────────────────────────────────────────────────────────────────────────

    private func handleWindow(samples: [SensorSample]) {
        let context = contextLock.sync { currentContext }

        // Apply context-aware threshold offsets
        let calendar = Calendar.current
        let hourOfDay = calendar.component(.hour, from: Date())
        let basePolicy = SensitivityPolicy.policy(for: context.sensitivityLevel)
        _ = thresholds.adjustedPolicy(
            basePolicy,
            isWorkout:  context.isWorkoutActive,
            isAsleep:   context.isCurrentlyAsleep,
            hourOfDay:  hourOfDay
        )
        // TODO: Pass adjusted policy into DecisionEngine when policy injection is added

        // Run the full pipeline
        let decision = engine.evaluate(samples: samples, context: context)

        // Update motion baseline from non-alert windows
        if !decision.isSeizureSuspected {
            let sma = samples.map { $0.accelMagnitude }.reduce(0, +) / Double(samples.count)
            baselines.updateMotion(sma: sma, isAlertWindow: false)
        }

        // Broadcast to any registered UI listener
        DispatchQueue.main.async { [weak self] in
            self?.onDecision?(decision)
        }
    }
}
