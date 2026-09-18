import SwiftUI
import Charts

struct ActivityChartView: View {
    let data: [DayActivity]
    @Binding var period: ChartPeriod
    let sessions: [TrainingSession]

    private var totalThisPeriod: Int { sessions.count }
    private var avgSuccessRate: Int {
        guard !sessions.isEmpty else { return 0 }
        let avg = sessions.map { $0.successRate }.reduce(0, +) / Double(sessions.count)
        return Int(avg * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "progress.chart.title"))
                        .font(.system(size: 15, weight: .semibold))
                    Text(String(localized: "progress.chart.subtitle \(totalThisPeriod)"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Period picker
                Picker("", selection: $period) {
                    ForEach(ChartPeriod.allCases, id: \.rawValue) {
                        Text($0.localizedTitle).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            // Bar chart
            Chart(data) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Sessions", day.sessionCount)
                )
                .foregroundStyle(
                    day.sessionCount > 0
                    ? AnyShapeStyle(Color.accentColor.gradient)
                    : AnyShapeStyle(Color.secondary.opacity(0.15))
                )
                .cornerRadius(4)
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    AxisValueLabel(format: period == .week
                                   ? .dateTime.weekday(.narrow)
                                   : .dateTime.day())
                        .font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 1)) { value in
                    if let v = value.as(Int.self), v > 0 {
                        AxisValueLabel {
                            Text("\(v)")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.secondary.opacity(0.2))
                    }
                }
            }
            .chartYScale(domain: 0...maxY)
            .animation(.easeInOut(duration: 0.4), value: period)

            // Mini stats under chart
            if totalThisPeriod > 0 {
                HStack(spacing: 16) {
                    Label(
                        String(localized: "progress.chart.avg \(avgSuccessRate)"),
                        systemImage: "target"
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                    Label(
                        String(localized: "progress.chart.active \(activeDays)"),
                        systemImage: "calendar"
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle(radius: 18)
    }

    private var maxY: Int {
        max(3, (data.map { $0.sessionCount }.max() ?? 1) + 1)
    }

    private var activeDays: Int {
        data.filter { $0.sessionCount > 0 }.count
    }

    private var xAxisValues: [Date] {
        if period == .week {
            return data.map { $0.date }
        } else {
            // Для місяця — кожні 7 днів
            return stride(from: 0, to: data.count, by: 7).compactMap {
                data.indices.contains($0) ? data[$0].date : nil
            }
        }
    }
}
