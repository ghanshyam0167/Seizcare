import SwiftUI
import Charts
import UIKit

struct TriggerCorrelationChart: View {

    // MARK: - Input
    let data: [TriggerCorrelation]

    // MARK: - Interaction
    @State private var selected: TriggerCorrelation?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Layout
    // Fix: Explicitly cast to CGFloat to reduce compiler work
    private var chartHeight: CGFloat {
        let rowHeight: CGFloat = 36
        let count = CGFloat(data.count)
        return max(180, count * rowHeight)
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            chartView
        }
        .padding(20)
    }

    // MARK: - Subviews
    
    // 1. Extracted Header to reduce body complexity
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Trigger Correlation")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("What factors most often precede seizures")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    // 2. Extracted Chart logic
    private var chartView: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Percent", item.percent),
                    y: .value("Trigger", item.trigger) // Ensure SeizureTrigger is Plottable (String enum)
                )
                .foregroundStyle(barColor(for: item.trigger))
                .cornerRadius(6)
                .opacity(opacity(for: item))
            }
        }
        .frame(height: chartHeight)
        .chartXAxis {
            AxisMarks(position: .bottom) {
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.12))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks {
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(location, proxy, geo)
                    }

                if let selected {
                    tooltip(selected, geo: geo)
                }
            }
        }
    }

    // MARK: - Helpers
    
    // Extracted opacity logic to keep the view clean
    private func opacity(for item: TriggerCorrelation) -> Double {
        return (selected == nil || selected?.id == item.id) ? 1.0 : 0.35
    }

    // MARK: - Tooltip
    private func tooltip(
        _ item: TriggerCorrelation,
        geo: GeometryProxy
    ) -> some View {
        let accent = barColor(for: item.trigger)

        return VStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)

                Text(item.trigger.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("\(item.percent, specifier: "%.1f")%")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(accent)

            Text("of seizures")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: accent.opacity(0.25), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
        .position(
            x: geo.size.width * 0.65,
            y: geo.size.height * 0.15
        )
    }

    // MARK: - Interaction
    private func handleTap(
        _ location: CGPoint,
        _ proxy: ChartProxy,
        _ geo: GeometryProxy
    ) {
        let origin = geo[proxy.plotAreaFrame].origin
        let y = location.y - origin.y

        // UPDATED: Assuming 'trigger' is an Enum, we should cast to the Enum type, not String.
        // If your SeizureTrigger enum is String-backed, this is the safer way to decode the chart value.
        guard let triggerType = proxy.value(atY: y, as: SeizureTrigger.self) else {
            selected = nil
            return
        }
        
        // Find the matching data item
        guard let match = data.first(where: { $0.trigger == triggerType }) else {
            selected = nil
            return
        }

        if selected?.id != match.id {
            selected = match
            haptic.impactOccurred()
        }
    }

    // MARK: - Styling
    private func barColor(for trigger: SeizureTrigger) -> Color {
        switch trigger {
        case .stress: return .red
        case .sleepDeprivation: return .orange
        case .missedMedication: return .purple
        case .alcohol: return .blue
        case .flashingLights: return .yellow
        case .illness: return .green
        case .unknown: return .gray
        }
    }
}
