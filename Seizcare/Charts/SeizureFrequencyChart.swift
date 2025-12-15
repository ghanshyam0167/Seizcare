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

            // =======================
            // Header (Title + Avg)
            // =======================
            HStack(alignment: .firstTextBaseline) {
                Text(titleText)
                    .font(.callout)
                    .foregroundColor(.secondary)

                Spacer()

                if average > 0 {
                    Text("Avg \(average)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // =======================
            // Chart
            // =======================
            Chart {
                ForEach(data) { point in
                    BarMark(
                        x: .value("Date", xLabel(for: point.date)),
                        y: .value("Seizures", point.count)
                    )
                    .cornerRadius(8)
                    .foregroundStyle(barGradient(for: point))
                    .opacity(
                        selectedPoint == nil || selectedPoint?.id == point.id ? 1 : 0.45
                    )
                }
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [6]))
                    .foregroundStyle(.secondary.opacity(0.5))

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
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXScale(range: .plotDimension(padding: 28))
            .frame(height: 260)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleTap(location, proxy, geo)
                        }

                    if let point = selectedPoint,
                       let x = proxy.position(forX: point.date),
                       let y = proxy.position(forY: point.count) {

                        tooltip(point: point, x: x, y: y, geo: geo)
                    }
                }
            }
        }
        

        // =======================
        // Card Styling (Balanced)
        // =======================
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .systemBackground))
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 6)
    }

    // MARK: - Tooltip
    private func tooltip(
        point: FrequencyPoint,
        x: CGFloat,
        y: CGFloat,
        geo: GeometryProxy
    ) -> some View {

        let w: CGFloat = 56
        let h: CGFloat = 34

        let cx = min(max(x, w / 2 + 8), geo.size.width - w / 2 - 8)
        let cy = max(y - 26, h)

        return Text("\(point.count)")
            .font(.headline)
            .frame(width: w, height: h)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .shadow(radius: 3)
            .position(x: cx, y: cy)
    }

    // MARK: - Helpers

    private func handleTap(
        _ location: CGPoint,
        _ proxy: ChartProxy,
        _ geo: GeometryProxy
    ) {
        let origin = geo[proxy.plotAreaFrame].origin
        let x = location.x - origin.x

        guard let date: Date = proxy.value(atX: x),
              let nearest = nearestPoint(to: date)
        else { return }

        selectedPoint = nearest
        haptic.impactOccurred()
    }

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
        case .current: return "Last 7 Days"
        case .weekly:  return "Last 4 Weeks"
        case .monthly: return "Last 6 Months"
        }
    }

    private func xLabel(for date: Date) -> String {
        let f = DateFormatter()
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

