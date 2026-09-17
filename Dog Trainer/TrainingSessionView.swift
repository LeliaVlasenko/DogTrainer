import SwiftUI
import SwiftData

struct TrainingSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(AchievementManager.self) private var achievements
    @Query private var allSessions: [TrainingSession]
    @Query private var allCommands: [Command]
    @Query private var earnedBadges: [EarnedBadge]

    let dog: Dog
    let commands: [Command]

    @State private var currentIndex = 0
    @State private var results: [CommandResult] = []
    @State private var sessionStart = Date()
    @State private var showSummary = false
    @State private var hasBeenSaved = false

    private var currentCommand: Command? {
        guard currentIndex < commands.count else { return nil }
        return commands[currentIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if showSummary {
                    SessionSummaryView(
                        dog: dog,
                        results: results,
                        duration: Int(Date().timeIntervalSince(sessionStart))
                    ) {
                        saveSession()
                        dismiss()
                    }
                } else if let command = currentCommand {
                    LessonView(
                        command: command,
                        commandIndex: currentIndex,
                        totalCommands: commands.count
                    ) { succeeded in
                        handleResult(command: command, succeeded: succeeded)
                    }
                    // Свіжий інстанс на кожну команду — інакше @State (currentStep,
                    // timerSeconds, clickCount) переносяться з попередньої команди.
                    .id(command.id)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "training.quit")) {
                        saveSession()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            Telemetry.log(.sessionStarted(commandCount: commands.count))
        }
    }

    // MARK: - Logic

    private func handleResult(command: Command, succeeded: Bool) {
        // Зберегти результат
        results.append(CommandResult(
            commandId: command.id,
            commandTitle: command.title,
            succeeded: succeeded,
            attempts: 1
        ))

        // Оновити лічильник команди — і одразу зберегти, бо інакше зміна
        // SwiftData-моделі живе лише в пам'яті і губиться між сесіями.
        if succeeded {
            command.successCount += 1
            try? modelContext.save()
        }

        // Наступна команда або підсумок
        if currentIndex + 1 < commands.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        } else {
            withAnimation {
                showSummary = true
            }
        }
    }

    private func saveSession() {
        // Guard від дубля: якщо юзер натискає Quit після завершення сесії
        // (з summary), не хочемо створювати другий TrainingSession в БД.
        guard !hasBeenSaved, !results.isEmpty else { return }
        hasBeenSaved = true
        let successCount = results.filter { $0.succeeded }.count
        Telemetry.log(.sessionCompleted(
            duration: Int(Date().timeIntervalSince(sessionStart)),
            successCount: successCount,
            totalCount: results.count
        ))
        let session = TrainingSession(
            date: sessionStart,
            durationSeconds: Int(Date().timeIntervalSince(sessionStart)),
            mood: .good,
            dog: dog
        )
        session.commandResults = results
        modelContext.insert(session)
        try? modelContext.save()

        // Donate shortcut — Siri вчиться на частоті використання
        donateTrainingShortcut(dogName: dog.name)

        // Перепланувати нагадування (зняти streak-at-risk на сьогодні)
        Task { await notificationManager.rescheduleAll(dog: dog) }

        // Перевірити досягнення — toast з'явиться через AchievementManager
        achievements.checkAfterSession(
            session: session,
            dog: dog,
            allSessions: allSessions,
            allCommands: allCommands,
            earnedBadges: earnedBadges,
            context: modelContext
        )
    }
}
