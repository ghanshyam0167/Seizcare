import UIKit

// MARK: - Insight Model
struct SeizureInsight {
    let text: String
    let iconName: String
    let color: UIColor
}

// MARK: - Insight Generator
final class SeizureInsightGenerator {

    static func generate(
        current: Double,
        previous: Double,
        period: DashboardPeriod
    ) -> SeizureInsight {

        // No comparison possible
        guard previous > 0 else {
            return SeizureInsight(
                text: "No previous data available for comparison",
                iconName: "minus",
                color: .systemGray
            )
        }

        let delta = current - previous
        let percent = Int(ceil(abs(delta) / previous * 100))

        let periodText: String = {
            switch period {
            case .current: return "yesterday"
            case .weekly:  return "last week"
            case .monthly: return "last month"
            }
        }()

        // Improvement
        if delta < 0 {
            return SeizureInsight(
                text: "Seizures reduced by \(percent)% compared to \(periodText)",
                iconName: "chart.line.downtrend.xyaxis",
                color: .systemGreen
            )
        }

        // Worsening
        if delta > 0 {
            return SeizureInsight(
                text: "Seizures increased by \(percent)% compared to \(periodText)",
                iconName: "chart.line.uptrend.xyaxis",
                color: .systemRed
            )
        }

        // No change
        return SeizureInsight(
            text: "Seizure activity remained stable compared to \(periodText)",
            iconName: "chart.line.flattrend.xyaxis",
            color: .systemGray
        )
    }
}
