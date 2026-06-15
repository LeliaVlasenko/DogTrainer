import Foundation
import SwiftData

@Model
final class Command {
    var id: UUID
    var title: String
    var commandDescription: String
    var difficulty: CommandDifficulty
    var category: CommandCategory
    var isPremium: Bool
    var steps: [String]        // покрокові інструкції
    var successCount: Int      // скільки разів виконано успішно
    var isUnlocked: Bool

    @Relationship(deleteRule: .nullify)
    var sessions: [TrainingSession]

    init(
        title: String,
        commandDescription: String,
        difficulty: CommandDifficulty,
        category: CommandCategory,
        isPremium: Bool = false,
        steps: [String] = [],
        isUnlocked: Bool = true
    ) {
        self.id = UUID()
        self.title = title
        self.commandDescription = commandDescription
        self.difficulty = difficulty
        self.category = category
        self.isPremium = isPremium
        self.steps = steps
        self.successCount = 0
        self.isUnlocked = isUnlocked
        self.sessions = []
    }

    /// Вивчена команда = 5+ успішних повторень
    var isMastered: Bool { successCount >= 5 }

    /// Прогрес 0.0 – 1.0
    var progress: Double { min(Double(successCount) / 5.0, 1.0) }
}

enum CommandDifficulty: String, Codable, CaseIterable {
    case beginner     = "beginner"
    case intermediate = "intermediate"
    case advanced     = "advanced"

    var localizedTitle: String {
        String(localized: "difficulty.\(rawValue)")
    }

    var color: String {
        switch self {
        case .beginner:     return "green"
        case .intermediate: return "orange"
        case .advanced:     return "red"
        }
    }
}

enum CommandCategory: String, Codable, CaseIterable {
    case obedience  = "obedience"   // слухняність: sit, stay, down
    case social     = "social"      // соціалізація
    case tricks     = "tricks"      // трюки
    case behavioral = "behavioral"  // корекція поведінки

    var localizedTitle: String {
        String(localized: "category.\(rawValue)")
    }

    var systemImage: String {
        switch self {
        case .obedience:  return "hand.raised"
        case .social:     return "person.2"
        case .tricks:     return "star"
        case .behavioral: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Seed data

extension Command {
    /// Базові команди (безкоштовні)
    static func seedCommands() -> [Command] {
        [
            Command(
                title: String(localized: "command.sit.title"),
                commandDescription: String(localized: "command.sit.desc"),
                difficulty: .beginner,
                category: .obedience,
                isPremium: false,
                steps: [
                    String(localized: "command.sit.step1"),
                    String(localized: "command.sit.step2"),
                    String(localized: "command.sit.step3")
                ]
            ),
            Command(
                title: String(localized: "command.stay.title"),
                commandDescription: String(localized: "command.stay.desc"),
                difficulty: .beginner,
                category: .obedience,
                isPremium: false,
                steps: [
                    String(localized: "command.stay.step1"),
                    String(localized: "command.stay.step2"),
                    String(localized: "command.stay.step3")
                ]
            ),
            Command(
                title: String(localized: "command.come.title"),
                commandDescription: String(localized: "command.come.desc"),
                difficulty: .beginner,
                category: .obedience,
                isPremium: false,
                steps: [
                    String(localized: "command.come.step1"),
                    String(localized: "command.come.step2")
                ]
            ),
            // Premium команди
            Command(
                title: String(localized: "command.down.title"),
                commandDescription: String(localized: "command.down.desc"),
                difficulty: .intermediate,
                category: .obedience,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.leave.title"),
                commandDescription: String(localized: "command.leave.desc"),
                difficulty: .intermediate,
                category: .behavioral,
                isPremium: true
            ),
        ]
    }
}
