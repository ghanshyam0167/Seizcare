import SwiftUI
import Charts
import UIKit

struct SeizureFrequencyChart: View {

    // MARK: - Input
    let data: [FrequencyPoint]
    let period: DashboardPeriod

    // MARK: - Interaction
    @State private var selectedPoint: FrequencyPoint?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            frequencyChart
        }
        // =======================
        // Card Styling (Balanced)
        // =======================
        .padding(20)

    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titleText)
                .font(.callout)
                .foregroundColor(.secondary)

            Spacer()

            if average > 0 {
                Text("\("Avg".localized()) \(average)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var frequencyChart: some View {
        Chart {
            chartContent
            // Selection highlight only
            if let selected = selectedPoint {
                RuleMark(x: .value("Selected", selected.date, unit: xUnit))
                    .foregroundStyle(.gray.opacity(0.1))
                    .offset(yStart: -10)
                    .zIndex(-1)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.12))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: xUnit)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(xLabel(for: date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXScale(range: .plotDimension(padding: 28))
        .frame(height: 260)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let origin = geo[proxy.plotAreaFrame].origin
                                let location = CGPoint(
                                    x: value.location.x - origin.x,
                                    y: value.location.y - origin.y
                                )
                                // Find date at x
                                if let date: Date = proxy.value(atX: location.x) {
                                    // Find nearest point
                                    if let nearest = nearestPoint(to: date) {
                                        selectedPoint = nearest
                                    }
                                }
                            }
                            .onEnded { _ in
                                // Optional: deselect on end?
                                selectedPoint = nil
                            }
                    )
                
                if let point = selectedPoint,
                   let x = proxy.position(forX: point.date) {
                    
                    tooltip(point: point, x: x, geo: geo)
                }
            }
        }
    }

    @ChartContentBuilder
    private var chartContent: some ChartContent {
        ForEach(data) { point in
            BarMark(
                x: .value("Date".localized(), point.date, unit: xUnit),
                y: .value("Seizures".localized(), point.count)
            )
            .cornerRadius(8)
            .foregroundStyle(barGradient(for: point))
            .opacity(
                selectedPoint == nil || selectedPoint?.id == point.id ? 1 : 0.45
            )
        }
        RuleMark(y: .value("Average".localized(), average))
            .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [6]))
            .foregroundStyle(.secondary.opacity(0.5))
    }

    // MARK: - Tooltip
    private func tooltip(
        point: FrequencyPoint,
        x: CGFloat,
        geo: GeometryProxy
    ) -> some View {
        
        VStack(spacing: 4) {
            Text(tooltipDateLabel(for: point.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text("\(point.count) \(point.count == 1 ? "seizure".localized() : "seizures".localized())")
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(radius: 3)
        .position(
            x: min(max(x, 60), geo.size.width - 60),
            y: 40 // Fixed height from top, similar to other charts
        )
    }


    // MARK: - Tooltip Date Label
    private func tooltipDateLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageManager.shared.currentLanguage.code)
        switch period {
        case .current:
            f.dateFormat = "EEEE, MMM d"
        case .weekly:
            // Show week range e.g. "Feb 10 – Feb 16"
            let cal = Calendar.current
            if let end = cal.date(byAdding: .day, value: 6, to: date) {
                let f2 = DateFormatter()
                f2.locale = Locale(identifier: LanguageManager.shared.currentLanguage.code)
                f.dateFormat = "MMM d"
                f2.dateFormat = "MMM d"
                return "\(f.string(from: date)) – \(f2.string(from: end))"
            }
            f.dateFormat = "'\("Week of".localized())' MMM d"
        case .monthly:
            f.dateFormat = "MMMM yyyy"
        }
        return f.string(from: date)
    }

    // MARK: - Helpers

    private func nearestPoint(to date: Date) -> FrequencyPoint? {
        data.min {
            abs($0.date.timeIntervalSince(date)) <
            abs($1.date.timeIntervalSince(date))
        }
    }

    private var average: Int {
        guard !data.isEmpty else { return 0 }
        let avg = Double(data.map(\.count).reduce(0, +)) / Double(data.count)
        return Int(ceil(avg))
    }


    private func barGradient(for point: FrequencyPoint) -> LinearGradient {
        let colors: [Color] = [.purple, .teal, .blue, .indigo, .cyan, .mint]
        let idx = data.firstIndex(of: point) ?? 0
        let base = colors[idx % colors.count]

        return LinearGradient(
            colors: [base.opacity(0.65), base],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // MARK: - Labels

    private var titleText: String {
        switch period {
        case .current: return "Last 7 Days".localized()
        case .weekly:  return "Last 4 Weeks".localized()
        case .monthly: return "Last 6 Months".localized()
        }
    }

    private func xLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageManager.shared.currentLanguage.code)
        switch period {
        case .current: f.dateFormat = "E"
        case .weekly:  f.dateFormat = "'W'w"
        case .monthly: f.dateFormat = "MMM"
        }
        return f.string(from: date)
    }

    private var xUnit: Calendar.Component {
        switch period {
        case .current: return .day
        case .weekly:  return .weekOfYear
        case .monthly: return .month
        }
    }
}





