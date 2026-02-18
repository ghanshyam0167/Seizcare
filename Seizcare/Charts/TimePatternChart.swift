import SwiftUI
import Charts
import UIKit

struct TimePatternChart: View {

    // MARK: - Input
    let data: [TimeOfDayPattern]

    // MARK: - Interaction
    @State private var selected: TimeOfDayPattern?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Derived
    private var total: Int {
        data.map(\.count).reduce(0, +)
    }

    // MARK: - Body
    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            // ======================
            // Header
            // ======================
            VStack(alignment: .leading, spacing: 4) {
                Text("Time of Day Pattern")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("Last 3 months")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // ======================
            // Donut Chart
            // ======================
            Chart {
                ForEach(data) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.2
                    )
                    .cornerRadius(4)
                    .foregroundStyle(color(for: item.bucket))
                    .opacity(
                        selected == nil || selected?.id == item.id ? 1 : 0.35
                    )
                }
            }
            .frame(height: 220)
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        handleTap(value.location, proxy, geo)
                                    }
                                    .onEnded { _ in
                                        selected = nil
                                    }
                            )

                    if let selected {
                        tooltip(for: selected, in: geo)
                    }
                }
            }

            // ======================
            // Legend
            // ======================
            VStack(spacing: 10) {
                ForEach(data) { item in
                    HStack(spacing: 8) {

                        Circle()
                            .fill(color(for: item.bucket))
                            .frame(width: 8, height: 8)

                        Text(item.bucket.rawValue.capitalized)
                            .font(.caption)

                        Spacer()

                        Text("\(percentage(of: item))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
    }

    // MARK: - Tooltip
    private func tooltip(
        for item: TimeOfDayPattern,
        in geo: GeometryProxy
    ) -> some View {

        let accent = color(for: item.bucket)

        return VStack(spacing: 10) {

            // 🟢 Accent indicator + title
            HStack(spacing: 6) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)

                Text(item.bucket.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 🔢 Main value
            Text("\(item.count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(accent)

            Text("Seizures")
                .font(.caption)
                .foregroundStyle(.secondary)

            // 📊 Percentage pill
            Text("\(percentage(of: item))% of total")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(accent.opacity(0.12))
                )
                .foregroundStyle(accent)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: accent.opacity(0.25), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
        .position(
            x: geo.size.width / 2,
            y: geo.size.height / 2
        )
    }


    // MARK: - Tap Handling
    private func handleTap(
        _ location: CGPoint,
        _ proxy: ChartProxy,
        _ geo: GeometryProxy
    ) {
        let frame = geo[proxy.plotAreaFrame]
        let center = CGPoint(x: frame.midX, y: frame.midY)

        let dx = location.x - center.x
        let dy = center.y - location.y

        var angle = atan2(dx, dy) * 180 / .pi
        if angle < 0 { angle += 360 }

        guard total > 0 else { return }

        var currentAngle: Double = 0

        for item in data {
            let sliceAngle = Double(item.count) / Double(total) * 360
            let endAngle = currentAngle + sliceAngle

            if angle >= currentAngle && angle < endAngle {
                selected = item
                haptic.impactOccurred()
                return
            }

            currentAngle = endAngle
        }

        selected = nil
    }

    // MARK: - Helpers
    private func percentage(of item: TimeOfDayPattern) -> Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(item.count) / Double(total) * 100))
    }

    private func color(for bucket: SeizureTimeBucket) -> Color {
        switch bucket {
        case .morning:   return .yellow
        case .afternoon: return .orange
        case .evening:   return .purple
        case .night:     return .indigo
        case .unknown:   return .gray
        }
    }
}
