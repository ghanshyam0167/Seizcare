//
//  HeartRateTimelineChart.swift
//  Seizcare
//
//  Created by GS Agrawal on 16/12/25.
//


import SwiftUI
import Charts

struct HeartRateTimelineChart: View {

    let data: [HeartRateTimelinePoint]
    let seizureTime: Date
    let seizureDuration: TimeInterval

    @State private var selected: HeartRateTimelinePoint?
    @State private var tooltipX: CGFloat = 0
    @State private var tooltipY: CGFloat = 0

    private let hrColor = Color.red

    private var minY: CGFloat {
        CGFloat(data.map { $0.bpm }.min() ?? 0)
    }

    private var maxY: CGFloat {
        CGFloat(data.map { $0.bpm }.max() ?? 200)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ======================
            // Header
            // ======================
            VStack(alignment: .leading, spacing: 4) {
                Text("Heart Rate Pattern")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("2 hours before & after seizure")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // ======================
            // Chart + Y label
            // ======================
            HStack(alignment: .center, spacing: 6) {

                // Y-axis label
                VStack(spacing: 1) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(Array("BPM"), id: \.self) { char in
                        Text(String(char))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Chart {

                    // DURING PHASE
                    let start = seizureTime
                    let end = seizureTime.addingTimeInterval(seizureDuration)

                    RectangleMark(
                        xStart: .value("Start", start),
                        xEnd: .value("End", end)
                    )
                    .foregroundStyle(.red.opacity(0.10))

                    // HR LINE
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Heart Rate", point.bpm)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .foregroundStyle(hrColor)
                    }

                    // Seizure moment
                    RuleMark(x: .value("Seizure", seizureTime))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))

                    // Selected point
                    if let selected {
                        PointMark(
                            x: .value("Time", selected.timestamp),
                            y: .value("Heart Rate", selected.bpm)
                        )
                        .symbolSize(130)
                        .foregroundStyle(hrColor)
                    }
                }
                .frame(height: 220)
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
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
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
                                                : (CGFloat(nearest.bpm) - minY) / range

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
            }

            // X-axis label
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
extension HeartRateTimelineChart {

    private func timeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    private func nearestPoint(to date: Date) -> HeartRateTimelinePoint? {
        data.min {
            abs($0.timestamp.timeIntervalSince(date)) <
            abs($1.timestamp.timeIntervalSince(date))
        }
    }

    @ViewBuilder
    private func tooltipView(_ point: HeartRateTimelinePoint) -> some View {
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

            Text("\(point.bpm) bpm")
                .font(.headline)
                .foregroundColor(hrColor)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

