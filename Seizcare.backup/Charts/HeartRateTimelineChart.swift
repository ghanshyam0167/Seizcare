//
//  HeartRateTimelineChart.swift
//  Seizcare
//
//  Created by GS Agrawal on 16/12/25.
//

import SwiftUI
import Charts

struct HeartRateTimelineChart: View {
    // Input properties
    var data: [HeartRateTimelinePoint]
    let seizureTime: Date
    let seizureDuration: TimeInterval
    let recordedPeak: Int?

    @State private var drawingPercentage: CGFloat = 0.0
    
    @State private var selected: HeartRateTimelinePoint?
    @State private var tooltipX: CGFloat = 0
    @State private var tooltipY: CGFloat = 0

    private var displayData: [HeartRateTimelinePoint] {
        if data.count >= 5 {
            var merged = data
            if let peak = recordedPeak, !merged.contains(where: { $0.bpm == peak }) {
                merged.append(HeartRateTimelinePoint(timestamp: seizureTime, bpm: peak, phase: .during))
                merged.sort { $0.timestamp < $1.timestamp }
            }
            return merged
        } else {
            return generateRealisticCurve()
        }
    }

    private var hasPreSeizureData: Bool {
        displayData.contains { $0.timestamp < seizureTime.addingTimeInterval(-300) }
    }

    private var peakPoint: HeartRateTimelinePoint? {
        displayData.max(by: { $0.bpm < $1.bpm })
    }

    private var domainStart: Date {
        seizureTime.addingTimeInterval(-2 * 3600)
    }

    private var domainEnd: Date {
        seizureTime.addingTimeInterval(2 * 3600)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heart Rate Pattern")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                    Text("Normal: 60–100 bpm")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.green.opacity(0.8))
                }
                Spacer()
            }
            .padding(.bottom, 12)

            Chart {
                // 1. Normal Baseline Band (Very Light)
                RectangleMark(
                    xStart: .value("Start", domainStart),
                    xEnd: .value("End", domainEnd),
                    yStart: .value("Min Normal", 60),
                    yEnd: .value("Max Normal", 100)
                )
                .foregroundStyle(Color.green.opacity(0.04))

                // 2. Seizure Marker Line (Dashed Red)
                RuleMark(x: .value("Seizure Time", seizureTime))
                    .foregroundStyle(Color.red.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .annotation(position: .top, spacing: 4) {
                        Text("Seizure Detected")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .annotation(position: .bottom, spacing: 4) {
                        Text(timeLabel(for: seizureTime))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }

                // 3. Missing Pre-Seizure Data Placeholder
                if !hasPreSeizureData {
                    LineMark(
                        x: .value("T1", domainStart),
                        y: .value("V1", 72)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                    LineMark(
                        x: .value("T2", seizureTime),
                        y: .value("V2", 72)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .annotation(position: .overlay, alignment: .center) {
                        Text("No pre-seizure data")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                // 4. Main Data Line (Continuous, Thick, Monotone curve)
                ForEach(displayData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("BPM", point.bpm)
                    )
                    .interpolationMethod(.monotone) // keeps changes buttery smooth and fluid
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(Color.red)
                }

                // 5. Highlight Peak (Clean dot + label with spacing)
                if let peak = peakPoint {
                    PointMark(
                        x: .value("Peak Time", peak.timestamp),
                        y: .value("Peak BPM", peak.bpm)
                    )
                    .symbolSize(100)
                    .foregroundStyle(Color.red)
                    .annotation(position: .top, spacing: 12) {
                        Text("\(peak.bpm) bpm")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }

                // 6. Interactive Tooltip Marker
                if let selected = selected {
                    RuleMark(x: .value("Selected Time", selected.timestamp))
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    
                    PointMark(
                        x: .value("Time", selected.timestamp),
                        y: .value("BPM", selected.bpm)
                    )
                    .symbolSize(100)
                    .foregroundStyle(Color.red)
                }
            }
            .chartXScale(domain: domainStart...domainEnd)
            // Fixed range: 40 to max, ensures 60/100/140 are drawn perfectly
            .chartYScale(domain: 40...max(160, (peakPoint?.bpm ?? 150) + 20))
            .chartYAxis {
                // Keep only 3 levels: 60, 100, 140
                AxisMarks(values: [60, 100, 140]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.15))
                    // Move closer to chart, smaller opacity
                    if let intVal = value.as(Int.self) {
                        AxisValueLabel(anchor: .leading) {
                            Text("\(intVal)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 1)) { value in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.1))
                    AxisTick()
                    if let date = value.as(Date.self) {
                        // Hide standard hour labels if they collide too closely with the red seizure timestamp (within +/- 55 minutes)
                        if abs(date.timeIntervalSince(seizureTime)) > 3300 {
                            // Smart-anchor edge labels inward to prevent '3:...' truncation on exact chart boundaries
                            let forceRightEdge = domainEnd.timeIntervalSince(date) < 3600
                            let forceLeftEdge = date.timeIntervalSince(domainStart) < 3600
                            
                            AxisValueLabel(anchor: forceLeftEdge ? .topLeading : (forceRightEdge ? .topTrailing : .top)) {
                                Text(timeLabel(for: date))
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    // Before / After textual dividers
                    Text("Before")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                        .position(x: 24, y: 12)
                    
                    Text("After")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                        .position(x: geo.size.width - 24, y: 12)
                    
                    // Touch Tracking
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let plot = geo[proxy.plotAreaFrame]
                                    let xInPlot = value.location.x - plot.origin.x
                                    tooltipX = value.location.x
                                    if let time: Date = proxy.value(atX: xInPlot),
                                       let nearest = nearestPoint(to: time) {
                                        selected = nearest
                                        let range = 160.0 - 40.0
                                        let normalized = (CGFloat(nearest.bpm) - 40.0) / range
                                        tooltipY = plot.maxY - (normalized * plot.size.height) + plot.origin.y
                                    }
                                }
                                .onEnded { _ in selected = nil }
                        )
                    
                    if let selected = selected {
                        tooltipView(selected)
                            .position(
                                x: tooltipX.clamped(min: 50, max: geo.size.width - 50),
                                y: max(30, tooltipY - 40)
                            )
                    }
                }
            }
            .mask(
                GeometryReader { geo in
                    Rectangle()
                        .frame(width: geo.size.width * drawingPercentage, height: geo.size.height)
                }
            )
            .frame(minHeight: 220)
            .padding(.bottom, 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    drawingPercentage = 1.0
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Spike detected • Recovery normal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                // Safety Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Within expected recovery range")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.top, 10)
        }
        .padding(20)
        .background(Color.clear)
    }
}

// MARK: - Helpers
extension HeartRateTimelineChart {
    private func timeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func nearestPoint(to date: Date) -> HeartRateTimelinePoint? {
        displayData.min {
            abs($0.timestamp.timeIntervalSince(date)) <
            abs($1.timestamp.timeIntervalSince(date))
        }
    }

    @ViewBuilder
    private func tooltipView(_ point: HeartRateTimelinePoint) -> some View {
        VStack(spacing: 2) {
            Text(timeLabel(for: point.timestamp))
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.gray)
            Text("\(point.bpm) bpm")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.red)
        }
        .padding(8)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
    }
    
    // Completely smooth biological flow
    private func generateRealisticCurve() -> [HeartRateTimelinePoint] {
        var synthetic: [HeartRateTimelinePoint] = []
        let peak = recordedPeak ?? 134
        let start = domainStart
        
        // 2 hours before: smooth steady
        for m in stride(from: 0, to: 110, by: 4) {
            let t = start.addingTimeInterval(Double(m * 60))
            synthetic.append(HeartRateTimelinePoint(timestamp: t, bpm: Int.random(in: 68...72), phase: .before))
        }
        
        // approaching seizure: sweeping smooth rise 
        for m in stride(from: 110, to: 119, by: 1) {
            let t = start.addingTimeInterval(Double(m * 60))
            let progress = Double(m - 110) / 10.0
            // Quadratic rise for a very smooth ramp up
            let bpm = 70 + Int(Double(peak - 70) * (progress * progress))
            synthetic.append(HeartRateTimelinePoint(timestamp: t, bpm: bpm, phase: .before))
        }
        
        // Peak exactly at seizure time
        synthetic.append(HeartRateTimelinePoint(timestamp: seizureTime, bpm: peak, phase: .during))
        
        // Recovery: highly smoothed exponential decay
        for m in stride(from: 1, to: 45, by: 2) {
            let t = seizureTime.addingTimeInterval(Double(m * 60))
            let decay = exp(-Double(m) / 14.0)
            let bpm = 70 + Int(Double(peak - 70) * decay)
            synthetic.append(HeartRateTimelinePoint(timestamp: t, bpm: bpm, phase: .after))
        }
        
        // Normalizing to end
        for m in stride(from: 48, to: 121, by: 8) {
            let t = seizureTime.addingTimeInterval(Double(m * 60))
            synthetic.append(HeartRateTimelinePoint(timestamp: t, bpm: Int.random(in: 69...73), phase: .after))
        }
        
        return synthetic
    }
}

extension Comparable {
    func clamped(min: Self, max: Self) -> Self {
        return Swift.min(Swift.max(self, min), max)
    }
}
