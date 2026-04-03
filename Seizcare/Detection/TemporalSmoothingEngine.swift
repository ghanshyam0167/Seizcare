// TemporalSmoothingEngine.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Prevents alerting on a single high-probability window.
// Implements a configurable majority-vote confirmation over recent windows.
//
// Key properties:
//   • Thread-safe via serial queue
//   • Configurable pool size and required positive count (from SensitivityPolicy)
//   • Also tracks: positive window count, rhythmic motion duration, post-event stillness
//   • Returns both smoothed probability AND whether confirmation threshold is met

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - WindowRecord
// ─────────────────────────────────────────────────────────────────────────────

private struct WindowRecord {
    let probability: Double
    let timestamp:   Date
    let isPositive:  Bool  // exceeded seizure threshold
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - TemporalSmoothingEngine
// ─────────────────────────────────────────────────────────────────────────────

final class TemporalSmoothingEngine {

    // MARK: Configuration

    /// Maximum history depth (covers ~30 seconds at 2s stride)
    private let maxHistorySize = 15

    // MARK: State

    private var history: [WindowRecord] = []
    private var rhythmicStartTime: Date?
    private var lastHighMotionTimestamp: Date?
    private let queue = DispatchQueue(label: "com.seizcare.temporalSmoothing", qos: .userInitiated)

    // MARK: Init

    init() {
        print("⌛ [TemporalSmoothing] Initialised — max history: \(maxHistorySize) windows")
    }

    // MARK: - Public API

    struct SmoothingResult {
        /// Exponential moving average of recent probabilities
        let smoothedProbability:     Double
        /// Number of windows in the pool that exceeded the threshold
        let positiveWindowCount:     Int
        /// Seconds of continuous rhythmic motion detected
        let rhythmicDuration:        Double
        /// Whether motion recently dropped after elevated activity (post-event stillness)
        let postEventStillness:      Double
        /// Whether the majority-vote confirmation rule passes for the given policy
        let confirmationPassed:      Bool
    }

    /// Feed a new window probability and evaluate smoothing.
    /// - Parameters:
    ///   - probability: Raw seizure probability from SeizureInferenceService
    ///   - policy: Active sensitivity policy (determines vote threshold)
    ///   - accelMagMean: Mean acceleration magnitude for the current window
    func feed(probability: Double,
              policy: SensitivityPolicy,
              accelMagMean: Double = 0,
              periodicityScore: Double = 0) -> SmoothingResult {
        return queue.sync {
            let now = Date()
            let isPositive = probability >= policy.seizureThreshold

            // Add to history
            let record = WindowRecord(probability: probability, timestamp: now, isPositive: isPositive)
            history.append(record)
            if history.count > maxHistorySize {
                history.removeFirst()
            }

            // -- Smoothed probability: exponential moving average (α = 0.4) ---
            let alpha = 0.4
            var ema = history.first?.probability ?? 0
            for record in history.dropFirst() {
                ema = alpha * record.probability + (1 - alpha) * ema
            }

            // -- Pool window for majority vote ---------------------------------
            let pool = Array(history.suffix(policy.windowPoolSize))
            let positiveInPool = pool.filter { $0.isPositive }.count
            let confirmationPassed = positiveInPool >= policy.requiredPositiveCount

            // -- Rhythmic motion duration -------------------------------------
            let highMotionThreshold = 0.6  // accel magnitude considered elevated
            if accelMagMean > highMotionThreshold && periodicityScore > 0.4 {
                if rhythmicStartTime == nil { rhythmicStartTime = now }
                lastHighMotionTimestamp = now
            } else if let last = lastHighMotionTimestamp, now.timeIntervalSince(last) > 4.0 {
                // Motion has stopped for >4s — reset rhythmic timer
                rhythmicStartTime = nil
                lastHighMotionTimestamp = nil
            }

            let rhythmicDuration: Double
            if let start = rhythmicStartTime {
                rhythmicDuration = now.timeIntervalSince(start)
            } else {
                rhythmicDuration = 0
            }

            // -- Post-event stillness -----------------------------------------
            // Detect if motion just dropped after sustained high motion (tonic-clonic → postictal)
            var postEventStillness = 0.0
            if history.count >= 3 {
                let recent = Array(history.suffix(3))
                let prevMean = recent.prefix(2).map { $0.probability }.reduce(0, +) / 2.0
                let current  = recent.last?.probability ?? 0
                // Stillness = previous windows were positive, current dropped sharply
                if prevMean > 0.5 && current < 0.3 {
                    postEventStillness = 1.0 - (current / max(prevMean, 0.01))
                }
            }

            return SmoothingResult(
                smoothedProbability:   ema,
                positiveWindowCount:   positiveInPool,
                rhythmicDuration:      rhythmicDuration,
                postEventStillness:    postEventStillness,
                confirmationPassed:    confirmationPassed
            )
        }
    }

    /// Reset all history. Call when the user dismisses an alert or monitoring restarts.
    func reset() {
        queue.sync {
            history.removeAll()
            rhythmicStartTime = nil
            lastHighMotionTimestamp = nil
            print("🔄 [TemporalSmoothing] History cleared")
        }
    }

    /// Returns the last N raw probabilities for debug logging.
    func recentProbabilities(n: Int = 5) -> [Double] {
        queue.sync { history.suffix(n).map { $0.probability } }
    }
}
