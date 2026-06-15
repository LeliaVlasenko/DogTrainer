import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query private var dogs: [Dog]
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query private var commands: [Command]

    @State private var selectedPeriod: ChartPeriod = .week

    private var dog: Dog? { dogs.first }

    // Сесії за вибраний період
    private var filteredSessions: [TrainingSession] {
        let cutoff = Calendar.current.date(
            byAdding: selectedPeriod == .week ? .day : .month,
            value: selectedPeriod == .week ? -7 : -1,
            to: .now
        ) ?? .now
        return sessions.filter { $0.date >= cutoff }
    }

    // Активність по днях для графіку
    private var activityData: [DayActivity] {
        let calendar = Calendar.current
        let days = selectedPeriod == .week ? 7 : 30
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: .now)!
            let day = calendar.startOfDay(for: date)
            let count = sessions.filter {
                calendar.startOfDay(for: $0.date) == day
            }.count
            return DayActivity(date: day, sessionCount: count)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let dog {
                        StreakBannerView(dog: dog, sessions: Array(sessions.prefix(30)))
                        ActivityChartView(
                            data: activityData,
                            period: $selectedPeriod,
                            sessions: filteredSessions
                        )
                        CommandsProgressView(commands: commands)
                        RecentSessionsView(sessions: Array(sessions.prefix(5)))
                    } else {
                        ContentUnavailableView(
                            String(localized: "progress.empty"),
                            systemImage: "chart.bar",
                            description: Text(String(localized: "progress.empty.desc"))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "tab.progress"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Supporting types

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let sessionCount: Int
}

enum ChartPeriod: String, CaseIterable {
    case week  = "7d"
    case month = "30d"

    var localizedTitle: String {
        switch self {
        case .week:  return String(localized: "progress.period.week")
        case .month: return String(localized: "progress.period.month")
        }
    }
}

#Preview {
    ProgressView()
        .modelContainer(ModelContainer.preview)
}
