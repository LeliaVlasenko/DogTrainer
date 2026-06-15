import Foundation
import SwiftData

@Model
final class TrainingSession {
    var date: Date
    var durationSeconds: Int
    var notes: String
    var mood: SessionMood
    var commandResults: [CommandResult]   // результат по кожній команді

    var dog: Dog?

    init(
        date: Date = .now,
        durationSeconds: Int = 0,
        notes: String = "",
        mood: SessionMood = .good,
        dog: Dog? = nil
    ) {
        self.date = date
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.mood = mood
        self.commandResults = []
        self.dog = dog
    }

    var durationFormatted: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var successRate: Double {
        guard !commandResults.isEmpty else { return 0 }
        let succeeded = commandResults.filter { $0.succeeded }.count
        return Double(succeeded) / Double(commandResults.count)
    }

    var commandsDoneCount: Int {
        commandResults.filter { $0.succeeded }.count
    }
}

/// Результат однієї команди в рамках сесії
struct CommandResult: Codable {
    var commandId: UUID
    var commandTitle: String
    var succeeded: Bool
    var attempts: Int

    init(commandId: UUID, commandTitle: String, succeeded: Bool, attempts: Int = 1) {
        self.commandId = commandId
        self.commandTitle = commandTitle
        self.succeeded = succeeded
        self.attempts = attempts
    }
}

enum SessionMood: String, Codable, CaseIterable {
    case great = "great"
    case good  = "good"
    case okay  = "okay"
    case bad   = "bad"

    var emoji: String {
        switch self {
        case .great: return "🌟"
        case .good:  return "😊"
        case .okay:  return "😐"
        case .bad:   return "😔"
        }
    }

    var localizedTitle: String {
        String(localized: "mood.\(rawValue)")
    }
}
