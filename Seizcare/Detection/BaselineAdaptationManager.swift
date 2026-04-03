// BaselineAdaptationManager.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Maintain per-user rolling baselines.
// Uses Exponential Weighted Moving Average (EWMA) so baselines shift
// gradually and are never reset by a single noisy reading.
//
// Updated from:
//   • Heart rate data from HealthKit / WatchConnectivity
//   • Motion data from incoming sensor windows
//   • Sleep data from SleepManager
//   • Confirmed true-seizure events (updates frequency profile)
//
// Persisted locally (JSON) and NOT synced to Supabase (privacy-sensitive).

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - BaselineAdaptationManager
// ─────────────────────────────────────────────────────────────────────────────

final class BaselineAdaptationManager {

    // MARK: Singleton

    static let shared = BaselineAdaptationManager()

    // MARK: EWMA Alpha Parameters
    //   Lower α → slower adaptation (more inertia, harder to shift)
    //   Higher α → faster adaptation

    private let hrAlpha:     Double = 0.05   // resting HR — very slow (days)
    private let motionAlpha: Double = 0.10   // normal motion — moderate
    private let sleepAlpha:  Double = 0.08   // sleep avg — slow

    // MARK: State

    private(set) var baselines = BaselineStats()
    private let queue = DispatchQueue(label: "com.seizcare.baselines", qos: .background)
    private var storeURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("user_baselines.json")
    }

    // MARK: Init

    private init() {
        queue.async { self.loadFromDisk() }
        print("📊 [BaselineManager] Initialised — restingHR: \(baselines.restingHR) BPM")
    }

    // MARK: - Update Baselines

    /// Update resting heart rate baseline. Call from calm-period HR readings.
    /// Only update when: no workout active + low motion + time of day is rest period.
    func updateHR(_ hr: Double, isWorkoutActive: Bool, motionLevel: Double) {
        guard !isWorkoutActive, motionLevel < baselines.normalMotionSMA * 1.5, hr > 30, hr < 130 else { return }
        queue.async {
            let old = self.baselines.restingHR
            self.baselines.restingHR = self.ewma(old: old, new: hr, alpha: self.hrAlpha)
            self.baselines.lastUpdated = Date()
            print(String(format: "💓 [BaselineManager] HR baseline updated: %.1f → %.1f", old, self.baselines.restingHR))
            self.writeToDisk()
        }
    }

    /// Update normal motion baseline. Call from non-workout, non-alert windows.
    func updateMotion(sma: Double, isAlertWindow: Bool) {
        guard !isAlertWindow, sma > 0 else { return }
        queue.async {
            let old = self.baselines.normalMotionSMA
            self.baselines.normalMotionSMA = self.ewma(old: old, new: sma, alpha: self.motionAlpha)
            self.writeToDisk()
        }
    }

    /// Update rolling 7-day sleep average from SleepManager.
    func updateSleepAverage(_ nightly: Double) {
        guard nightly > 0, nightly < 16 else { return }
        queue.async {
            let old = self.baselines.avgSleepHours
            self.baselines.avgSleepHours = self.ewma(old: old, new: nightly, alpha: self.sleepAlpha)
            print(String(format: "🛌 [BaselineManager] Sleep avg updated: %.1f → %.1f hrs", old, self.baselines.avgSleepHours))
            self.writeToDisk()
        }
    }

    /// Update seizure frequency profile from a confirmed true seizure event.
    /// Raises the profile score gradually (used to raise sensitivity slightly in future).
    func recordConfirmedSeizureEvent() {
        queue.async {
            let old = self.baselines.seizureFreqProfile
            // Nudge frequency profile up — will decay naturally if no events occur
            let nudged = min(1.0, old + 0.1)
            self.baselines.seizureFreqProfile = nudged
            print(String(format: "📈 [BaselineManager] Seizure freq profile: %.2f → %.2f", old, nudged))
            self.writeToDisk()
        }
    }

    /// Returns current snapshot of baselines. Thread-safe.
    func currentBaselines() -> BaselineStats {
        queue.sync { baselines }
    }

    // MARK: - Disk

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }
        do {
            let data = try Data(contentsOf: storeURL)
            baselines = try JSONDecoder().decode(BaselineStats.self, from: data)
            print("📊 [BaselineManager] Loaded baselines — HR: \(baselines.restingHR) motion: \(baselines.normalMotionSMA)")
        } catch {
            print("❌ [BaselineManager] Load failed: \(error.localizedDescription)")
        }
    }

    private func writeToDisk() {
        do {
            let data = try JSONEncoder().encode(baselines)
            try data.write(to: storeURL, options: .atomicWrite)
        } catch {
            print("❌ [BaselineManager] Write failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Math

    private func ewma(old: Double, new: Double, alpha: Double) -> Double {
        return alpha * new + (1 - alpha) * old
    }
}
