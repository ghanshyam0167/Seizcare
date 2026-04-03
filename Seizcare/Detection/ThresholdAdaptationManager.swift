// ThresholdAdaptationManager.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Safely tune per-context detection thresholds based on accumulated feedback.
// This is NOT retraining — it adjusts decision-policy thresholds only.
//
// Rules:
//   • Too many false alarms during workouts → raise threshold during workout windows
//   • Too many false alarms during sleep → differentiate vs sleep movement better
//   • True seizures mostly at night → lower threshold slightly for nighttime windows
//   • Changes are small, bounded, and require N >5 labeled events before any adjustment
//   • History is persisted locally (never synced — privacy-sensitive)

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ThresholdAdaptationRecord
// ─────────────────────────────────────────────────────────────────────────────

private struct ThresholdAdaptationRecord: Codable {
    let label:             FeedbackLabel
    let activityClass:     String
    let wasAsleep:         Bool
    let wasWorkout:        Bool
    let sensitivityLevel:  String
    let timestamp:         Date
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ContextualThresholdOffset
// ─────────────────────────────────────────────────────────────────────────────

/// Per-context threshold offsets. Positive = raise threshold (harder to alert).
/// Negative = lower threshold (easier to alert). Bounded to [-0.15, +0.15].
struct ContextualThresholdOffset: Codable {
    var workoutOffset:   Double = 0.0
    var sleepOffset:     Double = 0.0
    var nighttimeOffset: Double = 0.0  // time 22:00–06:00
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ThresholdAdaptationManager
// ─────────────────────────────────────────────────────────────────────────────

final class ThresholdAdaptationManager {

    // MARK: Singleton

    static let shared = ThresholdAdaptationManager()

    // MARK: Configuration

    private let minEventsBeforeAdaptation = 5   // need N labeled events in context
    private let offsetStep                = 0.02 // each adaptation step
    private let maxOffset                 = 0.15 // maximum cumulative offset
    private let windowDays: Double        = 30   // look back 30 days

    // MARK: State

    private var records: [ThresholdAdaptationRecord] = []
    private(set) var offsets = ContextualThresholdOffset()
    private let queue = DispatchQueue(label: "com.seizcare.thresholdAdaptation", qos: .background)

    private var storeURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("threshold_adaptation.json")
    }

    // MARK: Init

    private init() {
        queue.async { self.loadFromDisk() }
        print("⚖️ [ThresholdAdaptation] Initialised")
    }

    // MARK: - Record Feedback

    func recordFeedback(label: FeedbackLabel,
                        activityClass: ActivityClass,
                        wasAsleep: Bool,
                        wasWorkout: Bool,
                        sensitivityLevel: SensitivityLevel) {
        let record = ThresholdAdaptationRecord(
            label:            label,
            activityClass:    activityClass.rawValue,
            wasAsleep:        wasAsleep,
            wasWorkout:       wasWorkout,
            sensitivityLevel: sensitivityLevel.rawValue,
            timestamp:        Date()
        )
        queue.async {
            self.records.append(record)
            self.recomputeOffsets()
            self.writeToDisk()
        }
    }

    // MARK: - Apply Offsets

    /// Returns an adjusted policy for the given context.
    func adjustedPolicy(_ base: SensitivityPolicy,
                        isWorkout: Bool,
                        isAsleep: Bool,
                        hourOfDay: Int) -> SensitivityPolicy {
        var adjustment = 0.0

        if isWorkout       { adjustment += offsets.workoutOffset   }
        if isAsleep        { adjustment += offsets.sleepOffset     }
        if hourOfDay >= 22 || hourOfDay < 6 { adjustment += offsets.nighttimeOffset }

        let adjusted = (base.seizureThreshold + adjustment)
            .clamped(to: 0.4...0.95)

        if abs(adjustment) > 0.001 {
            print(String(format: "⚖️ [ThresholdAdaptation] Base=%.2f offset=%+.3f → adjusted=%.2f",
                         base.seizureThreshold, adjustment, adjusted))
        }

        // Return a new policy with the adjusted threshold; other params unchanged
        return SensitivityPolicy(
            seizureThreshold:      adjusted,
            requiredPositiveCount: base.requiredPositiveCount,
            windowPoolSize:        base.windowPoolSize,
            requireHRConfirmation: base.requireHRConfirmation,
            hrConfirmationDelta:   base.hrConfirmationDelta
        )
    }

    // MARK: - Offset Computation

    private func recomputeOffsets() {
        let since = Date().addingTimeInterval(-windowDays * 86400)
        let recent = records.filter { $0.timestamp >= since }

        // --- Workout false alarm offset ---
        let workoutEvents = recent.filter { $0.wasWorkout }
        if workoutEvents.count >= minEventsBeforeAdaptation {
            let falseAlarms = workoutEvents.filter {
                $0.label == .falseAlarm || $0.label == .runningWorkout
            }.count
            let falseAlarmRate = Double(falseAlarms) / Double(workoutEvents.count)
            if falseAlarmRate > 0.6 {
                offsets.workoutOffset = min(maxOffset, offsets.workoutOffset + offsetStep)
                print(String(format: "⚖️ [ThresholdAdaptation] Workout false alarm rate=%.0f%% → raised threshold +%.2f (now %+.3f)",
                             falseAlarmRate * 100, offsetStep, offsets.workoutOffset))
            } else if falseAlarmRate < 0.2 && offsets.workoutOffset > 0 {
                offsets.workoutOffset = max(0, offsets.workoutOffset - offsetStep * 0.5)
            }
        }

        // --- Sleep false alarm offset ---
        let sleepEvents = recent.filter { $0.wasAsleep }
        if sleepEvents.count >= minEventsBeforeAdaptation {
            let sleepFalseAlarms = sleepEvents.filter { $0.label == .sleepJerk || $0.label == .falseAlarm }.count
            let sleepFalseRate = Double(sleepFalseAlarms) / Double(sleepEvents.count)
            if sleepFalseRate > 0.6 {
                offsets.sleepOffset = min(maxOffset, offsets.sleepOffset + offsetStep)
            }
        }

        // --- Nighttime seizure offset (lower threshold) ---
        let nightEvents = recent.filter {
            let hour = Calendar.current.component(.hour, from: $0.timestamp)
            return hour >= 22 || hour < 6
        }
        if nightEvents.count >= minEventsBeforeAdaptation {
            let trueSeizures = nightEvents.filter { $0.label == .trueSeizure }.count
            let trueRate = Double(trueSeizures) / Double(nightEvents.count)
            if trueRate > 0.7 {
                // Many confirmed nighttime events → lower threshold slightly
                offsets.nighttimeOffset = max(-maxOffset, offsets.nighttimeOffset - offsetStep)
                print(String(format: "⚖️ [ThresholdAdaptation] Nighttime true rate=%.0f%% → lowered threshold %.2f (now %+.3f)",
                             trueRate * 100, offsetStep, offsets.nighttimeOffset))
            }
        }
    }

    // MARK: - Disk

    private struct AdaptationState: Codable {
        var records: [ThresholdAdaptationRecord]
        var offsets: ContextualThresholdOffset
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storeURL.path),
              let data = try? Data(contentsOf: storeURL),
              let state = try? JSONDecoder().decode(AdaptationState.self, from: data) else { return }
        records = state.records
        offsets = state.offsets
        print("⚖️ [ThresholdAdaptation] Loaded \(records.count) records — workout offset: \(offsets.workoutOffset)")
    }

    private func writeToDisk() {
        let state = AdaptationState(records: records, offsets: offsets)
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: storeURL, options: .atomicWrite)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Comparable Clamped Helper
// ─────────────────────────────────────────────────────────────────────────────

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
