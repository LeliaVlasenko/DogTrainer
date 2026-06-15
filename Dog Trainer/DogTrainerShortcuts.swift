import AppIntents

// MARK: - App Shortcuts Provider
// Цей клас реєструє Siri фрази автоматично — без дій користувача.
// iOS показує їх у Settings → Siri & Search і в Spotlight.

struct DogTrainerShortcuts: AppShortcutsProvider {

    // Акцентний колір для Siri UI
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {

        AppShortcut(
            intent: StartTrainingIntent(),
            phrases: [
                // EN
                "Start training in \(.applicationName)",
                "Train my dog in \(.applicationName)",
                "Begin a session in \(.applicationName)",
                // ES
                "Empezar entrenamiento en \(.applicationName)",
                "Entrenar al perro en \(.applicationName)",
                // CA
                "Iniciar entrenament a \(.applicationName)",
                "Entrenar el gos a \(.applicationName)"
            ],
            shortTitle: "intent.start.short",
            systemImageName: "figure.walk.dog"
        )

        AppShortcut(
            intent: ShowProgressIntent(),
            phrases: [
                // EN
                "Show my dog's progress in \(.applicationName)",
                "How is my dog doing in \(.applicationName)",
                "Check streak in \(.applicationName)",
                // ES
                "Ver progreso de mi perro en \(.applicationName)",
                "Cómo va mi perro en \(.applicationName)",
                // CA
                "Veure progrés del meu gos a \(.applicationName)",
                "Com va el meu gos a \(.applicationName)"
            ],
            shortTitle: "intent.progress.short",
            systemImageName: "chart.bar.fill"
        )
    }
}
