//
//  SpO2TimelineChart.swift
//  Seizcare
//

import SwiftUI
import Charts

struct SpO2TimelineChart: View {
    
    let data: [SpO2TimelinePoint]
    let seizureTime: Date
    let seizureDuration: TimeInterval
    
    @State private var selected: SpO2TimelinePoint?
    @State private var tooltipX: CGFloat = 0
    @State private var tooltipY: CGFloat = 0
    
    private let spo2Color = Color(red: 44/255, green: 62/255, blue: 221/255)
    
    private var minY: CGFloat {
        CGFloat(data.map { $0.spo2 }.min() ?? 0)
    }
    
    private var maxY: CGFloat {
        CGFloat(data.map { $0.spo2 }.max() ?? 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            VStack(alignment: .leading, spacing: 4) {
                Text("SpO₂ Pattern")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("2 hours before & after seizure")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            HStack(alignment: .center, spacing: 6) {
                VStack(spacing: 1) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    VStack(spacing: 0) {
                        ForEach(Array("SPO2"), id: \.self) { char in
                            Text(String(char))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Chart {
                    
                    // ─────────────────────────────
                    // DURING PHASE (SHADED BAND)
                    // ─────────────────────────────
                    let start = seizureTime
                    let end = seizureTime.addingTimeInterval(seizureDuration)
                    
                    RectangleMark(
                        xStart: .value("Start", start),
                        xEnd: .value("End", end)
                    )
                    .foregroundStyle(.red.opacity(0.10))
                    
                    // ─────────────────────────────
                    // SpO₂ LINE
                    // ─────────────────────────────
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("SpO₂", point.spo2)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .foregroundStyle(spo2Color)
                    }
                    
                    // ─────────────────────────────
                    // SEIZURE MOMENT (CENTER LINE)
                    // ─────────────────────────────
                    RuleMark(x: .value("Seizure", seizureTime))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                    
                    // ─────────────────────────────
                    // SELECTED POINT
                    // ─────────────────────────────
                    if let selected {
                        PointMark(
                            x: .value("Time", selected.timestamp),
                            y: .value("SpO₂", selected.spo2)
                        )
                        .symbolSize(130)
                        .foregroundStyle(spo2Color)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text(timeLabel(for: date))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .frame(height: 220)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let plot = geo[proxy.plotAreaFrame]
                                    let xInPlot = value.location.x - plot.origin.x
                                    tooltipX = value.location.x
                                    
                                    if let time: Date = proxy.value(atX: xInPlot),
                                       let nearest = nearestPoint(to: time) {
                                        
                                        selected = nearest
                                        
                                        let range = maxY - minY
                                        let normalized =
                                        range == 0
                                        ? 0
                                        : (CGFloat(nearest.spo2) - minY) / range
                                        
                                        tooltipY =
                                        plot.maxY -
                                        (normalized * plot.size.height) +
                                        plot.origin.y
                                    }
                                }
                                .onEnded { _ in
                                    selected = nil
                                }
                        )
                    
                    if let selected {
                        tooltipView(selected)
                            .position(
                                x: tooltipX.clamped(min: 60, max: geo.size.width - 60),
                                y: max(50, tooltipY - 60)
                            )
                    }
                }
            }
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text("Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(20)
    }
}

// MARK: - Helpers
extension SpO2TimelineChart {
    private func timeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"   // 3 PM, 4 PM
        return formatter.string(from: date)
    }

    private func nearestPoint(to date: Date) -> SpO2TimelinePoint? {
        data.min {
            abs($0.timestamp.timeIntervalSince(date)) <
            abs($1.timestamp.timeIntervalSince(date))
        }
    }

    @ViewBuilder
    private func tooltipView(_ point: SpO2TimelinePoint) -> some View {
        VStack(spacing: 4) {
            Text(
                point.phase == .during
                ? "During seizure"
                : point.phase == .before
                    ? "Before seizure"
                    : "After seizure"
            )
            .font(.caption2)
            .foregroundColor(.gray)

            Text("\(point.spo2)%")
                .font(.headline)
                .foregroundColor(spo2Color)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - CGFloat Clamp
extension CGFloat {
    func clamped(min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(self, max))
    }
}
