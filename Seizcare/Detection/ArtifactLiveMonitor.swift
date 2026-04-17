// ArtifactLiveMonitor.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Read-only observer to monitor ArtifactFilter output in real time.
// Used for displaying the model's live activity predictions on the dashboard
// and filtering console logs cleanly without dumping raw sensor arrays.

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ArtifactLiveMonitor
// ─────────────────────────────────────────────────────────────────────────────

final class ArtifactLiveMonitor {

    /// Singleton accessible from anywhere (e.g., UI dashboard).
    static let shared = ArtifactLiveMonitor()

    // ── Callbacks ──────────────────────────────────────────────────────────

    /// Fires whenever the pipeline classifies a new window (approx. every 2s).
    /// Used by the dashboard UI to update the "Current Activity" label.
    var onUpdate: ((ArtifactLiveSnapshot) -> Void)?

    // ── Session State ──────────────────────────────────────────────────────

    private(set) var sessionSnapshot: ArtifactLiveSnapshot?
    private(set) var totalWindowsAnalyzed: Int = 0
    private(set) var totalWindowsSuppressed: Int = 0

    // ── Private ────────────────────────────────────────────────────────────
    
    private let queue = DispatchQueue(label: "com.seizcare.artifactMonitor", qos: .userInteractive)

    private init() {}

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Input
    // ─────────────────────────────────────────────────────────────────────────

    /// Called by `ArtifactInferenceService` every time the ML model predicts a window.
    func record(result: ArtifactFilterResult) {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.totalWindowsAnalyzed += 1
            let isSuppressed = result.activityClass.isDefinitelyNormal
            if isSuppressed {
                self.totalWindowsSuppressed += 1
            }

            let snapshot = ArtifactLiveSnapshot(
                activityClass: result.activityClass,
                confidence:    result.normalActivityProbability,
                suppressed:    isSuppressed,
                timestamp:     Date()
            )

            self.sessionSnapshot = snapshot

            // Dispatch to UI
            DispatchQueue.main.async {
                self.onUpdate?(snapshot)
            }

            // ── Clean Console Observation Line ────────────────────────────────
            let confPct = Int(snapshot.confidence * 100)
            let suppText  = snapshot.suppressed
                          ? "🚨 suppressed (not a seizure candidate)"
                          : "— passed to seizure model"
            print(String(format: "▶ Activity: %@ (%02d%%)  %@",
                         snapshot.displayLabel, confPct, suppText))
            // ────────────────────────────────────────────────────────────────
        } 
    }

    /// Reset rolling counters (e.g. on session start).
    func reset() {
        queue.async {
            self.totalWindowsAnalyzed = 0
            self.totalWindowsSuppressed = 0
            self.sessionSnapshot = nil
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ArtifactLiveSnapshot Model
// ─────────────────────────────────────────────────────────────────────────────

struct ArtifactLiveSnapshot {
    /// The canonical activity class (e.g. .walking, .unknown)
    let activityClass: ActivityClass
    
    /// Normalised ML confidence probability (0.0 to 1.0)
    let confidence: Double
    
    /// Whether this window will be blocked from triggering a seizure alert
    let suppressed: Bool
    
    /// Precise time of inference
    let timestamp: Date

    /// Human-readable UI string (e.g. "Walking", "Still / Rest")
    var displayLabel: String {
        return activityClass.displayName
    }
}
