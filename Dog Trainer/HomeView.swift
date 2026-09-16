import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(AchievementManager.self) private var achievementManager
    @Query private var dogs: [Dog]
    @Query private var commands: [Command]
    @Query private var earnedBadges: [EarnedBadge]

    @State private var todayCommands: [Command] = []
    @State private var showTraining = false
    @State private var showAllBadges = false

    private var dog: Dog? { dogs.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let dog {
                        DogHeaderView(dog: dog)
                        StreakMilestoneView(streak: dog.currentStreak)
                        TodayPlanView(
                            commands: todayCommands,
                            trainedToday: dog.trainedToday
                        )
                        StartTrainingButton(
                            trainedToday: dog.trainedToday,
                            commandsReady: !todayCommands.isEmpty
                        ) {
                            showTraining = true
                        }
                        RecentBadgesRow(earned: earnedBadges) {
                            showAllBadges = true
                        }
                    } else {
                        // Edge case: немає собаки (не мало б статись)
                        ContentUnavailableView(
                            String(localized: "home.no_dog"),
                            systemImage: "pawprint",
                            description: Text(String(localized: "home.no_dog.desc"))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showTraining) {
                if let dog {
                    TrainingSessionView(dog: dog, commands: todayCommands)
                        .environment(notificationManager)
                        .environment(achievementManager)
                }
            }
            .navigationDestination(isPresented: $showAllBadges) {
                AllBadgesView()
            }
        }
        .onAppear { refreshTodayCommands() }
        .onChange(of: commands) { refreshTodayCommands() }
    }

    // MARK: - Логіка підбору команд

    private func refreshTodayCommands() {
        guard let dog else { return }

        // Команди що підходять для рівня і ще не вивчені
        let available = commands.filter { cmd in
            cmd.isUnlocked &&
            !cmd.isMastered &&
            isCompatible(cmd, with: dog.level)
        }

        // Якщо сьогодні вже тренувались — показуємо ті самі команди
        if dog.trainedToday, let lastSession = dog.sessions
            .filter({ Calendar.current.isDateInToday($0.date) })
            .sorted(by: { $0.date > $1.date })
            .first {
            let ids = Set(lastSession.commandResults.map { $0.commandId })
            todayCommands = commands.filter { ids.contains($0.id) }
            return
        }

        // Пріоритет: команди з частковим прогресом → нові
        let inProgress = available
            .filter { $0.successCount > 0 }
            .sorted { $0.successCount > $1.successCount }

        let fresh = available
            .filter { $0.successCount == 0 }
            .shuffled()

        let pool = (inProgress + fresh).prefix(3)
        todayCommands = Array(pool)
    }

    private func isCompatible(_ command: Command, with level: DogLevel) -> Bool {
        switch level {
        case .puppy:
            return command.difficulty == .beginner
        case .adult:
            return command.difficulty != .advanced || command.successCount > 2
        case .behavioral:
            return command.category == .behavioral || command.difficulty == .beginner
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(ModelContainer.preview)
}
