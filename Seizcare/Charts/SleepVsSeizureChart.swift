import SwiftUI
import Charts
import UIKit

struct SleepVsSeizureChart: View {

    let data: [SleepSeizurePoint]

    @State private var selectedPoint: SleepSeizurePoint?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            // ======================
            // Header
            // ======================
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Sleep vs Seizures")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(uiColor: .darkGray))
                    .lineLimit(1)

                Spacer()
            }


            // ======================
            // Legend
            // ======================
            HStack(spacing: 12) {

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: 8, height: 8)

                    Text("Seizures")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)

                    Text("Sleep")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // ======================
            // Chart + Y-axis unit
            // ======================
            HStack(alignment: .top, spacing: 2) {

                // ⬅️ Y-axis unit
               
                
                VStack(spacing: 1) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    VStack(spacing: 0) {
                        ForEach(Array("Hours"), id: \.self) { char in
                            Text(String(char))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 16, height: 260)
                .offset(y: 8)
                .allowsHitTesting(false)

                // 📊 Chart
                Chart {

                    // ---- Seizure Bars ----
                    ForEach(data) { point in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Seizures", point.seizureCount)
                        )
                        .foregroundStyle(.red.opacity(0.35))
                        .opacity(
                            selectedPoint == nil || selectedPoint?.id == point.id ? 1 : 0.35
                        )
                    }

                    // ---- Sleep Line ----
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Sleep", point.sleepHours)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Sleep", point.sleepHours)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 260)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                            .foregroundStyle(.gray.opacity(0.12))
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        AxisValueLabel(format: .dateTime.day())
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

                        if let point = selectedPoint,
                           let x = proxy.position(forX: point.date) {
                            tooltip(point: point, x: x, geo: geo)
                        }
                    }
                }
            }

            // ======================
            // X-axis hint
            // ======================
            HStack {
                Spacer()

                HStack(spacing: 4) {
                    Text("Dates")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.top, -15)
            .padding(.trailing, 10)
            .allowsHitTesting(false)
        }
        .padding(20)
    }


    // ======================
    // MARK: - Tooltip
    // ======================
    private func tooltip(
        point: SleepSeizurePoint,
        x: CGFloat,
        geo: GeometryProxy
    ) -> some View {

        VStack(spacing: 6) {

            // 📅 Date
            Text(
                Self.tooltipDateFormatter.string(from: point.date)
            )
            .font(.caption2)
            .foregroundColor(.secondary)

            Divider()
                .frame(width: 60)

            // 😴 Sleep
            Text("\(point.sleepHours, specifier: "%.1f") hrs")
                .font(.caption)
                .foregroundColor(.blue)

            // 🚨 Seizures
            Text("\(point.seizureCount) seizures")
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(radius: 3)
        .position(
            x: min(max(x, 60), geo.size.width - 60),
            y: 24
        )
    }


    // ======================
    // MARK: - Interaction Logic
    // ======================
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

    private func nearestPoint(to date: Date) -> SleepSeizurePoint? {
        data.min {
            abs($0.date.timeIntervalSince(date)) <
            abs($1.date.timeIntervalSince(date))
        }
    }
    private static let tooltipDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM"
        return df
    }()

}


