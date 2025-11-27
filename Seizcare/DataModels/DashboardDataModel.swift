import Foundation

// MARK: - Dashboard Period
enum DashboardPeriod: String, Codable {
    case current
    case weekly
    case monthly
}

// MARK: - Dashboard Metrics
struct DashboardMetrics: Codable {
    var sleepDuration: TimeInterval   // total sleep duration (seconds)
    var averageRecovery: Double
    var averageSpO2: Double
    var seizureCount: Int
    
    // Computed readable format
    var formattedSleepDuration: String {
        let hours = Int(sleepDuration) / 3600
        let minutes = (Int(sleepDuration) % 3600) / 60
        return String(format: "%02dh %02dm", hours, minutes)
    }
}

// MARK: - Daily and Monthly Breakdown
struct DailyMetrics: Codable {
    var date: Date
    var averageSpO2: Double
    var seizureCount: Int
}

struct MonthlyMetrics: Codable {
    var month: Date   // month start date
    var averageSpO2: Double
    var seizureCount: Int
}

// MARK: - Dashboard Data Model
class DashboardDataModel {
    
    static let shared = DashboardDataModel()
    private init() {}
    
    private var currentStats: DashboardMetrics?
    private var weeklyStats: DashboardMetrics?
    private var monthlyStats: DashboardMetrics?
    
    // MARK: - Public Summary Access
    func getCurrentStats() -> DashboardMetrics? {
        calculateCurrentStats()
        return currentStats
    }
    
    func getStats(for period: DashboardPeriod) -> DashboardMetrics? {
        switch period {
        case .current:
            return getCurrentStats()
        case .weekly:
            calculateWeeklyStats()
            return weeklyStats
        case .monthly:
            calculateMonthlyStats()
            return monthlyStats
        }
    }
    
    // MARK: - Additional Summary Methods (for upper-half cards)
    func getWeeklySummary() -> (avgSleep: TimeInterval, avgRecovery: Double) {
        // Replace these with real HealthKit data later
        let sleepDurations: [TimeInterval] = [7.2, 6.9, 7.1, 6.8, 7.3, 7.0, 7.4].map { $0 * 3600 }
        let avgSleep = sleepDurations.averageOrZero()
        let avgRecovery = 90.5  // mock average recovery %
        return (avgSleep, avgRecovery)
    }
    
    func getMonthlySummary() -> (avgSleep: TimeInterval, avgRecovery: Double) {
        // Replace with real HealthKit data later
        let sleepDurations = (1...30).map { _ in Double.random(in: 6.5...7.8) * 3600 }
        let avgSleep = sleepDurations.averageOrZero()
        let avgRecovery = 88.0 // mock monthly average recovery %
        return (avgSleep, avgRecovery)
    }
    
    // MARK: - Graph Data
    
    /// Weekly: Monday–Sunday average SpO₂ and seizure count
    func getWeeklyDailyBreakdown() -> [DailyMetrics] {
        let records = SeizureRecordDataModel.shared.getRecordsForCurrentUser()
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        
        var dailyData: [DailyMetrics] = []
        
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                let dayRecords = records.filter { calendar.isDate($0.dateTime, inSameDayAs: date) }
                let avgSpO2 = dayRecords.map { Double($0.spo2 ?? 0) }.averageOrZero()
                let count = dayRecords.count
                dailyData.append(DailyMetrics(date: date, averageSpO2: avgSpO2, seizureCount: count))
            }
        }
        return dailyData
    }
    
    /// Monthly: last 6 months (average SpO₂ & seizure count per month)
    func getMonthlyBreakdown() -> [MonthlyMetrics] {
        let records = SeizureRecordDataModel.shared.getRecordsForCurrentUser()
        let calendar = Calendar.current
        let now = Date()
        
        var monthlyData: [MonthlyMetrics] = []
        
        for i in 0..<6 {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now),
               let startOfMonth = calendar.dateInterval(of: .month, for: monthDate)?.start,
               let endOfMonth = calendar.dateInterval(of: .month, for: monthDate)?.end {
                
                let monthRecords = records.filter {
                    $0.dateTime >= startOfMonth && $0.dateTime < endOfMonth
                }
                
                let avgSpO2 = monthRecords.map { Double($0.spo2 ?? 0) }.averageOrZero()
                let count = monthRecords.count
                
                monthlyData.append(MonthlyMetrics(month: startOfMonth, averageSpO2: avgSpO2, seizureCount: count))
            }
        }
        
        // Sort oldest → newest
        return monthlyData.sorted { $0.month < $1.month }
    }
    
    // MARK: - Private Calculations
    
    private func calculateCurrentStats() {
        let records = SeizureRecordDataModel.shared.getRecordsForCurrentUser()
        guard !records.isEmpty else {
            currentStats = DashboardMetrics(sleepDuration: 0, averageRecovery: 0, averageSpO2: 0, seizureCount: 0)
            return
        }
        
        let avgSpO2 = records.map { Double($0.spo2 ?? 0) }.averageOrZero()
        let todayCount = records.filter { Calendar.current.isDateInToday($0.dateTime) }.count
        
        // Mock 7 hours sleep for demo
        let sleepStart = Calendar.current.date(byAdding: .hour, value: -7, to: Date())!
        let sleepEnd = Date()
        let sleepDuration = sleepEnd.timeIntervalSince(sleepStart)
        
        currentStats = DashboardMetrics(
            sleepDuration: sleepDuration,
            averageRecovery: 91.0,
            averageSpO2: avgSpO2,
            seizureCount: todayCount
        )
    }
    
    private func calculateWeeklyStats() {
        let records = SeizureRecordDataModel.shared.getRecordsForCurrentUser()
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return }
        
        let filtered = records.filter { $0.dateTime >= startOfWeek }
        let avgSpO2 = filtered.map { Double($0.spo2 ?? 0) }.averageOrZero()
        
        weeklyStats = DashboardMetrics(
            sleepDuration: 7.1 * 3600, // avg weekly sleep duration
            averageRecovery: 90.5,
            averageSpO2: avgSpO2,
            seizureCount: filtered.count
        )
    }
    
    private func calculateMonthlyStats() {
        let records = SeizureRecordDataModel.shared.getRecordsForCurrentUser()
        let calendar = Calendar.current
        guard let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start else { return }
        
        let filtered = records.filter { $0.dateTime >= startOfMonth }
        let avgSpO2 = filtered.map { Double($0.spo2 ?? 0) }.averageOrZero()
        
        monthlyStats = DashboardMetrics(
            sleepDuration: 7.0 * 3600, // avg monthly sleep duration
            averageRecovery: 88.0,
            averageSpO2: avgSpO2,
            seizureCount: filtered.count
        )
    }
}

// MARK: - Array Extension for Safe Average
extension Array where Element == Double {
    func averageOrZero() -> Double {
        guard !self.isEmpty else { return 0.0 }
        return self.reduce(0, +) / Double(self.count)
    }
}
