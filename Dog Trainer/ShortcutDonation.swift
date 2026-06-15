import AppIntents
import SwiftData

// MARK: - Shortcut donation
// Викликати після кожного тренування — Siri стає розумнішою

@MainActor
func donateTrainingShortcut(dogName: String) {
    let intent = StartTrainingIntent()
    intent.dogName = dogName

    // iOS 17+ donation через AppShortcutsProvider автоматична,
    // але явний donate дає Siri більше сигналів про частоту
    Task {
        await AppShortcutsProvider.updateAppShortcutParameters()
    }
}

// MARK: - Widget / Spotlight entity donation

@MainActor
func donateProgressShortcut() {
    Task {
        await AppShortcutsProvider.updateAppShortcutParameters()
    }
}
