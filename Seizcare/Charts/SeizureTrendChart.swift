import SwiftUI
import Charts

struct SeizureTrendChart: View {

    var data: [SeizureTrend]

    @State private var selected: SeizureTrend? = nil
    @State private var tooltipX: CGFloat = 0
    @State private var tooltipY: CGFloat = 0

    let tooltipPadding: CGFloat = 60        // prevent left/right clipping
    let flipThreshold: CGFloat = 80         // if too close to top: flip tooltip
    let topSafeMargin: CGFloat = 50         // prevent tooltip from going behind card

    let spo2Color = Color(red: 44/255, green: 62/255, blue: 221/255)

    var minY: CGFloat { CGFloat(data.map { $0.count }.min() ?? 0) }
    var maxY: CGFloat { CGFloat(data.map { $0.count }.max() ?? 1) }

    var body: some View {
        ZStack {
            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Count", item.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .foregroundStyle(spo2Color)
                }

                if let selected = selected {
                    RuleMark(x: .value("Day", selected.day))
                        .foregroundStyle(spo2Color.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Day", selected.day),
                        y: .value("Count", selected.count)
                    )
                    .foregroundStyle(spo2Color)
                    .symbolSize(130)
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 240)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .chartOverlay { proxy in

                GeometryReader { geo in

                    // Drag detection region
                    Rectangle().fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in

                                    let plot = geo[proxy.plotAreaFrame]

                                    let xInPlot = value.location.x - plot.origin.x
                                    tooltipX = value.location.x

                                    if let day: String = proxy.value(atX: xInPlot),
                                       let nearest = data.first(where: { $0.day == day }) {

                                        selected = nearest

                                        let range = maxY - minY
                                        let normalized = range == 0 ? 0 : (CGFloat(nearest.count) - minY) / range

                                        let yInPlot = plot.maxY - (normalized * plot.size.height)
                                        tooltipY = yInPlot + plot.origin.y
                                    }
                                }
                                .onEnded { _ in
                                    selected = nil
                                }
                        )


                    // -------------------------------------------
                    // MARK: TOOLTIP (Bubble + Arrow, Auto Flip)
                    // -------------------------------------------

                    if let selected = selected {

                        // Should the tooltip flip BELOW?
                        let shouldFlip = (tooltipY - 70) < flipThreshold

                        VStack(spacing: 0) {

                            if !shouldFlip {
                                // Normal → Bubble above, arrow below
                                tooltipBubble(selected)
                                tooltipArrow(flip: false)
                            } else {
                                // Flipped → Arrow above, bubble below
                                tooltipArrow(flip: true)
                                tooltipBubble(selected)
                            }
                        }
                        .position(
                            x: max(tooltipPadding,
                                   min(geo.size.width - tooltipPadding, tooltipX)),
                            y: shouldFlip
                                ? (tooltipY + 60) 
                                : max(topSafeMargin, tooltipY - 60)
                        )
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
        .padding(.horizontal)
    }
}



// --------------------------------------------------------
// MARK: Tooltip Bubble & Arrow Helpers
// --------------------------------------------------------

extension SeizureTrendChart {

    @ViewBuilder
    func tooltipBubble(_ selected: SeizureTrend) -> some View {
        VStack(spacing: 4) {
            Text("Average this period")
                .font(.caption2)
                .foregroundColor(.gray)

            HStack(spacing: 4) {
                Text("\(selected.count)%")
                    .font(.headline)
                    .foregroundColor(spo2Color)

                Text("+1%")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    @ViewBuilder
    func tooltipArrow(flip: Bool) -> some View {
        Triangle()
            .fill(Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(Triangle())
            .frame(width: 14, height: 10)
            .rotationEffect(.degrees(flip ? 180 : 0))
            .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
    }
}



// --------------------------------------------------------
// MARK: Model & Triangle Shape
// --------------------------------------------------------

struct SeizureTrend: Identifiable {
    let id = UUID()
    let day: String
    let count: Int
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
