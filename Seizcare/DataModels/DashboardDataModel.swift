import Foundation





//  Sleep Data Model (Mock for now)

final class SleepDataModel {

    static let shared = SleepDataModel()

    /// In-memory cache populated by `refreshSleepData()`.
    private var cachedEntries: [SleepEntry] = []

    private init() {}

    // MARK: - SleepEntry (Codable so it maps to Supabase sleep_data table)
    struct SleepEntry: Codable {
        let date: Date
        let hours: Double
    }

    // MARK: - Async Refresh (call from ViewControllers / scene setup)

    /// Fetches sleep entries for the current user from Supabase and updates the cache.
    func refreshSleepData() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
        do {
            let dtos = try await SupabaseService.shared.fetchSleepEntries(userId: userId)
            cachedEntries = dtos.map { SleepEntry(date: $0.date, hours: $0.hours) }
                .sorted { $0.date < $1.date }
        } catch {
            print("⚠️ [SleepDataModel] refreshSleepData failed:", error.localizedDescription)
        }
    }

    /// Inserts a new sleep entry for the current user into Supabase.
    func addSleepEntry(date: Date, hours: Double) {
        let entry = SleepEntry(date: date, hours: hours)
        cachedEntries.append(entry)
        cachedEntries.sort { $0.date < $1.date }
        Task {
            guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
            do {
                let dto = SleepEntryDTO(userId: userId, date: date, hours: hours)
                try await SupabaseService.shared.insertSleepEntry(dto)
            } catch {
                print("⚠️ [SleepDataModel] addSleepEntry failed:", error.localizedDescription)
            }
        }
    }

    // MARK: - Synchronous Accessors (used by DashboardDataModel analytics – unchanged interface)

    /// Returns the cached sleep entries. Falls back to 30-day mock data if cache is empty.
    func getDailySleepData() -> [SleepEntry] {
        if !cachedEntries.isEmpty { return cachedEntries }
        // Fallback mock data so Dashboard charts always have something to render
        let cal = Calendar.current
        return (0..<30).map {
            SleepEntry(
                date: cal.date(byAdding: .day, value: -$0, to: Date())!,
                hours: Double.random(in: 5.0...8.5)
            )
        }
        .sorted { $0.date < $1.date }
    }

    func getAverageSleepLastMonth() -> Double {
        getDailySleepData()
            .map { $0.hours }
            .averageOrZero()
    }
}
// Dashboard Period
enum DashboardPeriod {
    case current   // daily
    case weekly
    case monthly
}



//  Dashboard Models

struct DashboardSummary {
    let avgMonthlySeizures: Double
    let mostCommonTime: SeizureTimeBucket
    let avgDuration: Double
    let avgSleepHours: Double
}

struct FrequencyPoint: Identifiable,Equatable {
    let id = UUID()
    let date: Date
    let count: Int
}


struct TimeOfDayPattern: Identifiable, Equatable {
    let id = UUID()
    let bucket: SeizureTimeBucket
    let count: Int
}

struct SleepSeizurePoint: Identifiable {
    let id = UUID()
    let date: Date
    let sleepHours: Double
    let seizureCount: Int
}

struct TriggerCorrelation: Identifiable {
    let id = UUID()
    let trigger: SeizureTrigger
    let percent: Double
}


//  Dashboard Data Model

final class DashboardDataModel {

    static let shared = DashboardDataModel()
    private init() {}

    private let recordModel = SeizureRecordDataModel.shared
    private let sleepModel = SleepDataModel.shared

    
    //  TOP 4 CARDS
  
    func getDashboardSummary(forPreviousMonth: Bool = false) -> DashboardSummary {

        let records = recordModel.getRecordsForCurrentUser()

        let filteredRecords: [SeizureRecord]

        if forPreviousMonth {
            filteredRecords = recordsLastMonths(records, months: 2)
                .filter { record in
                    
                    true
                }
        } else {
            filteredRecords = recordsLastMonths(records, months: 1)
        }

        guard !filteredRecords.isEmpty else {
            return getOnboardingFallbackSummary()
        }

        let avgMonthly = Double(filteredRecords.count)

        let mostCommonTime = Dictionary(
            grouping: filteredRecords.compactMap { $0.timeBucket },
            by: { $0 }
        )
        .mapValues { $0.count }
        .max(by: { $0.value < $1.value })?.key ?? .unknown

        let avgDuration = filteredRecords
            .compactMap { $0.duration }
            .averageOrZero()

        let avgSleep = forPreviousMonth
            ? sleepModel.getAverageSleepPreviousMonth()
            : sleepModel.getAverageSleepLastMonth()

        return DashboardSummary(
            avgMonthlySeizures: avgMonthly,
            mostCommonTime: mostCommonTime,
            avgDuration: avgDuration,
            avgSleepHours: avgSleep
        )
    }

    private func getOnboardingFallbackSummary() -> DashboardSummary {
        let defaults = UserDefaults.standard

        // 1. Avg Monthly Seizures
        let avgMonthly: Double = {
            let choice = defaults.string(forKey: "avgSeizuresPerMonth") ?? ""
            switch choice {
            case "Less than 1": return 0.5
            case "1–3": return 2.0
            case "4–10": return 7.0
            case "More than 10": return 15.0
            default: return 0.0
            }
        }()

        // 2. Most Common Time
        let commonTime: SeizureTimeBucket = {
            let choice = defaults.string(forKey: "commonSeizureTime") ?? ""
            return SeizureTimeBucket(rawValue: choice) ?? .unknown
        }()

        // 3. Avg Duration (seconds)
        let avgDur: Double = {
            let choice = defaults.string(forKey: "typicalSeizureDuration") ?? ""
            switch choice {
            case "Less than 30 sec": return 15.0
            case "30–60 sec": return 45.0
            case "1–3 min": return 120.0
            case "More than 3 min": return 240.0
            default: return 60.0
            }
        }()

        // 4. Avg Sleep Hours
        let avgSleep: Double = {
            let choice = defaults.string(forKey: "typicalSleepHours") ?? ""
            switch choice {
            case "Less than 5 hours": return 4.5
            case "5–6 hours": return 5.5
            case "6–8 hours": return 7.0
            case "More than 8 hours": return 9.0
            default: return SleepDataModel.shared.getAverageSleepLastMonth()
            }
        }()

        return DashboardSummary(
            avgMonthlySeizures: avgMonthly,
            mostCommonTime: commonTime,
            avgDuration: avgDur,
            avgSleepHours: avgSleep
        )
    }

    func getSeizureFrequency(period: DashboardPeriod) -> [FrequencyPoint] {
        switch period {
        case .current:
            return getDailyFrequencyFilled(days: 7)
        case .weekly:
            return getWeeklyFrequencyFilled(weeks: 4)
        case .monthly:
            return getMonthlyFrequencyFilled(months: 6)
        }
    }
    func getDailyFrequencyFilled(days: Int) -> [FrequencyPoint] {
        let raw = getDailyFrequency()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let daysArray = (0..<days).map {
            cal.date(byAdding: .day, value: -$0, to: today)!
        }
        .sorted()

        let map = Dictionary(grouping: raw, by: { cal.startOfDay(for: $0.date) })

        return daysArray.map {
            FrequencyPoint(
                date: $0,
                count: map[$0]?.first?.count ?? 0
            )
        }
    }
    func getWeeklyFrequencyFilled(weeks: Int) -> [FrequencyPoint] {
        let raw = getWeeklyFrequency()
        let cal = Calendar.current

        let weeksArray = (0..<weeks).map {
            cal.date(byAdding: .weekOfYear, value: -$0, to: Date())!
        }
        .map { cal.dateInterval(of: .weekOfYear, for: $0)!.start }
        .sorted()

        let map = Dictionary(grouping: raw, by: { $0.date })

        return weeksArray.map {
            FrequencyPoint(
                date: $0,
                count: map[$0]?.first?.count ?? 0
            )
        }
    }

    func getMonthlyFrequencyFilled(months: Int) -> [FrequencyPoint] {
        let raw = getMonthlyFrequency()
        let cal = Calendar.current

        let monthsArray = (0..<months).map {
            cal.date(byAdding: .month, value: -$0, to: Date())!
        }
        .map { cal.dateInterval(of: .month, for: $0)!.start }
        .sorted()

        let map = Dictionary(grouping: raw, by: { $0.date })

        return monthsArray.map {
            FrequencyPoint(
                date: $0,
                count: map[$0]?.first?.count ?? 0
            )
        }
    }

    func getCurrentPeriodAverage(period: DashboardPeriod) -> Double {
        let points = getSeizureFrequency(period: period)
        guard !points.isEmpty else { return 0 }

        return Double(points.map(\.count).reduce(0, +)) / Double(points.count)
    }

    func getPreviousPeriodAverage(period: DashboardPeriod) -> Double {

        let cal = Calendar.current
        let records = recordModel.getRecordsForCurrentUser()

        let (start, end): (Date, Date) = {
            switch period {
            case .current:
                let end = cal.startOfDay(for: Date())
                let start = cal.date(byAdding: .day, value: -7, to: end)!
                return (start, end)

            case .weekly:
                let end = cal.date(byAdding: .weekOfYear, value: -4, to: Date())!
                let start = cal.date(byAdding: .weekOfYear, value: -8, to: Date())!
                return (start, end)

            case .monthly:
                let end = cal.date(byAdding: .month, value: -6, to: Date())!
                let start = cal.date(byAdding: .month, value: -12, to: Date())!
                return (start, end)
            }
        }()

        let filtered = records.filter {
            $0.dateTime >= start && $0.dateTime < end
        }

        return Double(filtered.count)
    }

    
    //  SEIZURE FREQUENCY
  
    func getDailyFrequency() -> [FrequencyPoint] {
        groupBy(.day)
    }

    func getWeeklyFrequency() -> [FrequencyPoint] {
        groupBy(.weekOfYear)
    }

    func getMonthlyFrequency() -> [FrequencyPoint] {
        groupBy(.month)
    }

    private func groupBy(_ component: Calendar.Component) -> [FrequencyPoint] {
        let records = recordModel.getRecordsForCurrentUser()
        let cal = Calendar.current

        let grouped = Dictionary(grouping: records) {
            cal.dateInterval(of: component, for: $0.dateTime)!.start
        }

        return grouped.map {
            FrequencyPoint(date: $0.key, count: $0.value.count)
        }
        .sorted { $0.date < $1.date }
    }

    
    //  TIME OF DAY PATTERN
 
    func getTimeOfDayPattern(months: Int = 3) -> [TimeOfDayPattern] {

        let records = recordsLastMonths(months)

        let buckets = records.compactMap { $0.timeBucket }
        let counts = Dictionary(grouping: buckets, by: { $0 })
            .mapValues { $0.count }

        return SeizureTimeBucket.allCases.map {
            TimeOfDayPattern(
                bucket: $0,
                count: counts[$0] ?? 0
            )
        }
    }

    
    //  SLEEP VS SEIZURE
    
    func getSleepVsSeizure() -> [SleepSeizurePoint] {

        let sleepEntries = sleepModel.getDailySleepData()
        let records = recordModel.getRecordsForCurrentUser()

        return sleepEntries.map { entry in
            let count = records.filter {
                Calendar.current.isDate($0.dateTime, inSameDayAs: entry.date)
            }.count

            return SleepSeizurePoint(
                date: entry.date,
                sleepHours: entry.hours,
                seizureCount: count
            )
        }
    }

        //  TRIGGER CORRELATION
   
    func getTriggerCorrelation() -> [TriggerCorrelation] {

        let records = recordModel.getRecordsForCurrentUser()
        let total = max(records.count, 1)

        let triggers = records
            .compactMap { $0.triggers }
            .flatMap { $0 }

        let counts = Dictionary(grouping: triggers, by: { $0 })
            .mapValues { $0.count }

        return counts.map {
            TriggerCorrelation(
                trigger: $0.key,
                percent: Double($0.value) / Double(total) * 100
            )
        }
        .sorted { $0.percent > $1.percent }
    }

  
    //  HELPERS
    
    private func recordsLastMonths(_ records: [SeizureRecord], months: Int) -> [SeizureRecord] {
        let cal = Calendar.current
        let cut = cal.date(byAdding: .month, value: -months, to: Date())!
        return records.filter { $0.dateTime >= cut }
    }
    private func recordsLastMonths(_ months: Int) -> [SeizureRecord] {
        let cal = Calendar.current
        let cut = cal.date(byAdding: .month, value: -months, to: Date())!
        return recordModel
            .getRecordsForCurrentUser()
            .filter { $0.dateTime >= cut }
    }

}


// Array Helpers

extension Array where Element == Double {
    func averageOrZero() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
    
}

extension SleepDataModel {

    func getAverageSleepPreviousMonth() -> Double {

        let cal = Calendar.current
        let now = Date()

        guard
            let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)),
            let startOfPreviousMonth = cal.date(byAdding: .month, value: -1, to: startOfThisMonth)
        else {
            return 0
        }

        return getDailySleepData()
            .filter { $0.date >= startOfPreviousMonth && $0.date < startOfThisMonth }
            .map { $0.hours }
            .averageOrZero()
    }
}
