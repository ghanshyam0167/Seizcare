import Foundation

//====================================================
// MARK: - Seizure Time Bucket
//====================================================


//====================================================
// MARK: - Sleep Data Model (Mock for now)
//====================================================
final class SleepDataModel {

    static let shared = SleepDataModel()
    private init() {}

    struct SleepEntry {
        let date: Date
        let hours: Double
    }

    func getDailySleepData() -> [SleepEntry] {
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
// MARK: - Dashboard Period
enum DashboardPeriod {
    case current   // daily
    case weekly
    case monthly
}


//====================================================
// MARK: - Dashboard Models
//====================================================
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

//====================================================
// MARK: - Dashboard Data Model
//====================================================
final class DashboardDataModel {

    static let shared = DashboardDataModel()
    private init() {}

    private let recordModel = SeizureRecordDataModel.shared
    private let sleepModel = SleepDataModel.shared

    //====================================================
    // MARK: TOP 4 CARDS
    //====================================================
    func getDashboardSummary() -> DashboardSummary {

        let records = recordModel.getRecordsForCurrentUser()

        guard !records.isEmpty else {
            return DashboardSummary(
                avgMonthlySeizures: 0,
                mostCommonTime: .unknown,
                avgDuration: 0,
                avgSleepHours: sleepModel.getAverageSleepLastMonth()
            )
        }

        let lastMonthRecords = recordsLastMonths(records, months: 1)

        let avgMonthly = Double(lastMonthRecords.count)

        let mostCommonTime: SeizureTimeBucket = {
            let buckets = records.compactMap { $0.timeBucket }
            let counts = Dictionary(grouping: buckets, by: { $0 })
                .mapValues { $0.count }
            return counts.max(by: { $0.value < $1.value })?.key ?? .unknown
        }()

        let avgDuration = records
            .compactMap { $0.duration }
            .averageOrZero()

        let avgSleep = sleepModel.getAverageSleepLastMonth()

        return DashboardSummary(
            avgMonthlySeizures: avgMonthly,
            mostCommonTime: mostCommonTime,
            avgDuration: avgDuration,
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

    //====================================================
    // MARK: SEIZURE FREQUENCY
    //====================================================
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

    //====================================================
    // MARK: TIME OF DAY PATTERN
    //====================================================
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

    //====================================================
    // MARK: SLEEP VS SEIZURE
    //====================================================
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

    //====================================================
    // MARK: TRIGGER CORRELATION
    //====================================================
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

    //====================================================
    // MARK: HELPERS
    //====================================================
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

//====================================================
// MARK: - Array Helpers
//====================================================
extension Array where Element == Double {
    func averageOrZero() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
    
}

