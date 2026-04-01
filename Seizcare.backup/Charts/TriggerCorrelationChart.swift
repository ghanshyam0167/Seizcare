//
//  TriggerCorrelationChart.swift
//  Seizcare

import SwiftUI
import Charts
import UIKit

struct TriggerCorrelationChart: View {
    let data: [TriggerCorrelation]
    @State private var selected: TriggerCorrelation?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Frequency %", item.percent),
                        y: .value("Trigger", item.trigger.displayName)
                    )
                    .foregroundStyle(Color.orange)
                    .cornerRadius(4)
                    .opacity(selected == nil || selected?.id == item.id ? 1.0 : 0.4)
                }
            }
            .frame(height: 240)
            .chartXAxis {
                AxisMarks(position: .bottom) {
                    AxisGridLine().foregroundStyle(.gray.opacity(0.1))
                    AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in handleTap(value.location, proxy, geo) }
                                .onEnded   { _ in selected = nil }
                        )
                    if let selected {
                        tooltip(selected, geo: geo)
                    }
                }
            }
        }
        .padding(20)
    }

    private func tooltip(_ item: TriggerCorrelation, geo: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            Text(item.trigger.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(item.percent, specifier: "%.1f")%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.orange)
            Text("of seizures")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        )
        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.2)
    }

    private func handleTap(_ location: CGPoint, _ proxy: ChartProxy, _ geo: GeometryProxy) {
        let origin = geo[proxy.plotAreaFrame].origin
        let y = location.y - origin.y
        guard let label = proxy.value(atY: y, as: String.self),
              let trigger = SeizureTrigger.allCases.first(where: { $0.displayName == label }),
              let match = data.first(where: { $0.trigger == trigger })
        else { selected = nil; return }
        if selected?.id != match.id { selected = match; haptic.impactOccurred() }
    }
}
