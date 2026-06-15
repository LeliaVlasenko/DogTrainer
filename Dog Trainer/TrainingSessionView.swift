import SwiftUI
import SwiftData

struct TrainingSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dog: Dog
    let commands: [Command]

    @State private var currentIndex = 0
    @State private var results: [CommandResult] = []
    @State private var sessionStart = Date()
    @State private var showSummary = false

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

        // Оновити лічильник команди
        if succeeded {
            command.successCount += 1
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
        guard !results.isEmpty else { return }
        let session = TrainingSession(
            date: sessionStart,
            durationSeconds: Int(Date().timeIntervalSince(sessionStart)),
            mood: .good,
            dog: dog
        )
        session.commandResults = results
        modelContext.insert(session)
        try? modelContext.save()
    }
}
