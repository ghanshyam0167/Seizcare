// DetectionSessionStore.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Local-first persistence layer for detection sessions.
//   • Writes sessions as JSON to the app's Documents directory
//   • Queues Supabase sync for sessions that produced alerts
//   • Provides query methods for alert history and feedback lookup
//   • Never blocks the detection pipeline (all I/O is async)

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DetectionSessionStore
// ─────────────────────────────────────────────────────────────────────────────

final class DetectionSessionStore {

    // MARK: Singleton

    static let shared = DetectionSessionStore()

    // MARK: Storage

    private let queue = DispatchQueue(label: "com.seizcare.sessionStore", qos: .background)
    private var sessions: [DetectionSession] = []

    private var storeURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("detection_sessions.json")
    }

    // MARK: Init

    private init() {
        queue.async { self.loadFromDisk() }
        print("💾 [SessionStore] Initialised — store: detection_sessions.json")
    }

    // MARK: - Write

    /// Persist a new detection session asynchronously.
    func save(session: DetectionSession) {
        queue.async {
            self.sessions.append(session)
            self.writeToDisk()
            print("💾 [SessionStore] Saved session \(session.id) — outcome: \(session.decision.rawValue)")

            // Sync to Supabase if this was an actual alert
            if session.decision == .seizureSuspected {
                self.enqueueSyncToSupabase(session)
            }
        }
    }

    /// Append feedback provenance for a session by ID (called from FeedbackLogger).
    func addFeedback(sessionID: UUID, provenance: FeedbackProvenance) {
        queue.async {
            guard let i = self.sessions.firstIndex(where: { $0.id == sessionID }) else { return }
            
            self.sessions[i].labelHistory.append(provenance)
            self.sessions[i].syncStatus = .pending // Reset sync so feedback is pushed
            
            self.writeToDisk()
            print("✏️ [SessionStore] Added feedback for \(sessionID) → \(provenance.label.rawValue) [\(provenance.source)]")
            
            self.enqueueSyncToSupabase(self.sessions[i], index: i)
        }
    }

    // MARK: - Read

    func allSessions() -> [DetectionSession] {
        queue.sync { sessions.sorted { $0.timestamp > $1.timestamp } }
    }

    func alertSessions() -> [DetectionSession] {
        queue.sync {
            sessions
                .filter { $0.decision == .seizureSuspected }
                .sorted { $0.timestamp > $1.timestamp }
        }
    }

    func session(for id: UUID) -> DetectionSession? {
        queue.sync { sessions.first { $0.id == id } }
    }

    func unlabeledAlertSessions() -> [DetectionSession] {
        queue.sync {
            sessions.filter { $0.decision == .seizureSuspected && $0.feedbackLabel == nil }
        }
    }

    // MARK: - Disk I/O

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            sessions = []
            return
        }
        do {
            let data = try Data(contentsOf: storeURL)
            sessions = try JSONDecoder().decode([DetectionSession].self, from: data)
            print("💾 [SessionStore] Loaded \(sessions.count) sessions from disk")
        } catch {
            print("❌ [SessionStore] Load failed: \(error.localizedDescription)")
            sessions = []
        }
    }

    private func writeToDisk() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: storeURL, options: .atomicWrite)
        } catch {
            print("❌ [SessionStore] Write failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Supabase Sync

    /// Enqueues the session for sync. Safe to call on the storage queue only.
    private func enqueueSyncToSupabase(_ session: DetectionSession, index: Int? = nil) {
        let i = index ?? sessions.firstIndex(where: { $0.id == session.id })
        guard let index = i else { return }
        
        let targetSession = sessions[index]
        
        // Make sure it runs detached safely
        Task {
            // Must have auth
            guard let userId = await UserDataModel.shared.currentUser?.id else {
                print("🌐 [SessionStore] Sync paused — no active user")
                return
            }
            
            // Mark pending
            self.queue.async {
                self.sessions[index].syncStatus = .pending
                self.sessions[index].lastSyncAttempt = Date()
                self.writeToDisk()
            }
            
            let dto = DetectionSessionDTO(from: targetSession, userId: userId)
            
            do {
                print("🌐 [SessionStore] Pushing to Supabase for session \(targetSession.id)")
                try await SupabaseService.shared.upsertDetectionSession(dto)
                
                // Success
                self.queue.async {
                    if let idx = self.sessions.firstIndex(where: { $0.id == targetSession.id }) {
                        self.sessions[idx].syncStatus = .synced
                        self.sessions[idx].lastSyncAttempt = Date()
                        self.writeToDisk()
                        print("✅ [SessionStore] Sync succeeded for \(targetSession.id)")
                    }
                }
            } catch {
                // Failure
                self.queue.async {
                    if let idx = self.sessions.firstIndex(where: { $0.id == targetSession.id }) {
                        self.sessions[idx].syncStatus = .failed
                        self.sessions[idx].lastSyncAttempt = Date()
                        self.writeToDisk()
                        print("❌ [SessionStore] Sync failed for \(targetSession.id), will retry later")
                    }
                }
            }
        }
    }

    /// Retries pending or failed unsynced sessions. Call periodically or on app foreground.
    func syncPendingToSupabase() {
        queue.async {
            let now = Date()
            
            let unsynced = self.sessions.filter { session in
                guard session.decision == .seizureSuspected else { return false }
                
                switch session.syncStatus {
                case .pending:
                    return true
                case .failed:
                    // 5-minute cooldown before retry
                    if let lastAttempt = session.lastSyncAttempt {
                        return now.timeIntervalSince(lastAttempt) > 300 // 5 mins
                    }
                    return true
                case .synced:
                    return false
                }
            }
            
            guard !unsynced.isEmpty else { return }
            print("🌐 [SessionStore] Sweeping \(unsynced.count) sessions for Supabase sync")
            
            for session in unsynced {
                self.enqueueSyncToSupabase(session)
            }
        }
    }
}
