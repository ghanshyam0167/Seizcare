//
//  SleepDataModel.swift
//  Seizcare
//

import Foundation

// MARK: - SleepEntry Domain Model

struct SleepEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var date: Date
    var hours: Double

    /// Convenience init for creating new entries (generates a new UUID).
    init(userId: UUID, date: Date, hours: Double) {
        self.id     = UUID()
        self.userId = userId
        self.date   = date
        self.hours  = hours
    }

    /// Full memberwise init used by DTO → domain conversion.
    init(id: UUID, userId: UUID, date: Date, hours: Double) {
        self.id     = id
        self.userId = userId
        self.date   = date
        self.hours  = hours
    }

    static func == (lhs: SleepEntry, rhs: SleepEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - SleepDataModel

extension Notification.Name {
    static let didSyncSleepData = Notification.Name("didSyncSleepData")
}

final class SleepDataModel {

    static let shared = SleepDataModel()

    /// In-memory cache – populated by refreshSleepEntries().
    private var cachedEntries: [SleepEntry] = []

    private init() {}

    // MARK: - Refresh (async, Supabase → cache)

    /// Fetches sleep entries for the current user from Supabase and updates the cache.
    func refreshSleepEntries() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
        do {
            let dtos = try await SupabaseService.shared.fetchSleepEntries(userId: userId)
            cachedEntries = dtos.map { dto in
                SleepEntry(id: dto.id, userId: dto.userId, date: dto.date, hours: dto.hours)
            }
        } catch {
            print("⚠️ [SleepDataModel] refreshSleepEntries failed:", error.localizedDescription)
        }
    }

    // MARK: - Public Accessors

    /// Returns all cached sleep entries.
    func getAllSleepEntries() -> [SleepEntry] {
        return cachedEntries
    }

    /// Returns sleep entries for the currently logged-in user from the cache.
    func getSleepEntriesForCurrentUser() -> [SleepEntry] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            return []
        }
        return cachedEntries.filter { $0.userId == currentUser.id }
    }

    // MARK: - Add Entry

    /// Adds a new sleep entry for the currently logged-in user and persists it to Supabase.
    func addSleepEntry(date: Date, hours: Double) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("Cannot add sleep entry — no user logged in.")
            return
        }
        let entry = SleepEntry(userId: currentUser.id, date: date, hours: hours)
        cachedEntries.append(entry)
        Task {
            do {
                let dto = SleepEntryDTO(userId: currentUser.id, date: date, hours: hours)
                try await SupabaseService.shared.insertSleepEntry(dto)
            } catch {
                print("⚠️ [SleepDataModel] addSleepEntry failed:", error.localizedDescription)
            }
        }
    }

    // MARK: - Synchronous Accessors (used by DashboardDataModel analytics)

    func getDailySleepData() -> [SleepEntry] {
        return cachedEntries.sorted { $0.date < $1.date }
    }

    func getAverageSleepLastMonth() -> Double {
        let data = getDailySleepData().map { $0.hours }
        guard !data.isEmpty else { return 0 }
        return data.reduce(0, +) / Double(data.count)
    }

    // MARK: - Sync
    
    /// Syncs local daily totals (e.g. from HealthKit) to Supabase, avoiding duplicates for the same day.
    func syncSleepData(dailyTotals: [Date: Double]) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else { return }
        let calendar = Calendar.current
        
        Task {
            // 1. Fetch existing entries to avoid duplicates
            await refreshSleepEntries()
            let existingEntries = getSleepEntriesForCurrentUser()
            
            // Map existing entries to startOfDay to easily compare
            let existingDays = Set(existingEntries.map { calendar.startOfDay(for: $0.date) })
            
            for (date, hours) in dailyTotals {
                let day = calendar.startOfDay(for: date)
                
                // 2. Only insert if this day doesn't exist yet
                if !existingDays.contains(day) {
                    print("💾 [SleepDataModel] Syncing new sleep entry to Supabase: \(day) -> \(String(format: "%.1f", hours)) hrs")
                    addSleepEntry(date: day, hours: hours)
                }
            }
            
            // 3. Notify that the daily history is now ready for charts
            DispatchQueue.main.async {
                print("📣 [SleepDataModel] Posting NotificationCenter broadcast: didSyncSleepData")
                NotificationCenter.default.post(name: .didSyncSleepData, object: nil)
            }
        }
    }
}
