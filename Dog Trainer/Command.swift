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
        switch self {
        case .beginner:     return String(localized: "difficulty.beginner")
        case .intermediate: return String(localized: "difficulty.intermediate")
        case .advanced:     return String(localized: "difficulty.advanced")
        }
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
        switch self {
        case .obedience:  return String(localized: "category.obedience")
        case .social:     return String(localized: "category.social")
        case .tricks:     return String(localized: "category.tricks")
        case .behavioral: return String(localized: "category.behavioral")
        }
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

// MARK: - Seed versioning

extension Command {
    /// Поточна версія seed-набору.
    /// Інкрементуй при додаванні нових команд + додай їх у новий extras-метод.
    static let currentSeedVersion: Int = 2

    /// Ключ у UserDefaults для збереження останньої seed-версії.
    static let seedVersionKey = "commands.seedVersion"

    /// Top-up: при апгрейді з v1 додає лише ті команди, які з'явилися у v2+.
    /// Викликається при старті застосунку. Для нових юзерів (без жодної
    /// команди) нічого не робить — їх seed повністю встановлює онбординг.
    @MainActor
    static func topUpSeedIfNeeded(in context: ModelContext) {
        let defaults = UserDefaults.standard
        let currentVersion = defaults.integer(forKey: seedVersionKey)
        guard currentVersion < currentSeedVersion else { return }

        // Якщо жодної команди немає — онбординг ще не пройдено,
        // він сам викличе seedCommands() і проставить версію.
        let count = (try? context.fetchCount(FetchDescriptor<Command>())) ?? 0
        guard count > 0 else { return }

        if currentVersion < 2 {
            for cmd in extraCommandsV2() {
                context.insert(cmd)
            }
        }

        try? context.save()
        defaults.set(currentSeedVersion, forKey: seedVersionKey)
    }
}

// MARK: - Seed data

extension Command {
    /// Повний стартовий набір (для нового користувача): v1 core + v2 extras.
    static func seedCommands() -> [Command] {
        coreCommandsV1() + extraCommandsV2()
    }

    /// Команди, які існували у версії 1 seed (sit, stay, come, down, leave).
    /// Не змінюй цей набір — він фіксує "старий" стан для логіки top-up.
    private static func coreCommandsV1() -> [Command] {
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

    /// V2: 21 нова команда (2 free + 19 premium).
    /// Викликається для top-up юзерів з v1 та як частина seedCommands().
    static func extraCommandsV2() -> [Command] {
        [
            // MARK: Beginner / Free (нові базові)

            Command(
                title: String(localized: "command.name.title"),
                commandDescription: String(localized: "command.name.desc"),
                difficulty: .beginner,
                category: .obedience,
                isPremium: false,
                steps: [
                    String(localized: "command.name.step1"),
                    String(localized: "command.name.step2"),
                    String(localized: "command.name.step3")
                ]
            ),
            Command(
                title: String(localized: "command.watch.title"),
                commandDescription: String(localized: "command.watch.desc"),
                difficulty: .beginner,
                category: .obedience,
                isPremium: false,
                steps: [
                    String(localized: "command.watch.step1"),
                    String(localized: "command.watch.step2"),
                    String(localized: "command.watch.step3")
                ]
            ),

            // MARK: Intermediate / Premium

            Command(
                title: String(localized: "command.heel.title"),
                commandDescription: String(localized: "command.heel.desc"),
                difficulty: .intermediate,
                category: .obedience,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.place.title"),
                commandDescription: String(localized: "command.place.desc"),
                difficulty: .intermediate,
                category: .obedience,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.stand.title"),
                commandDescription: String(localized: "command.stand.desc"),
                difficulty: .intermediate,
                category: .obedience,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.drop.title"),
                commandDescription: String(localized: "command.drop.desc"),
                difficulty: .intermediate,
                category: .behavioral,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.wait.title"),
                commandDescription: String(localized: "command.wait.desc"),
                difficulty: .intermediate,
                category: .behavioral,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.shake.title"),
                commandDescription: String(localized: "command.shake.desc"),
                difficulty: .intermediate,
                category: .tricks,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.high_five.title"),
                commandDescription: String(localized: "command.high_five.desc"),
                difficulty: .intermediate,
                category: .tricks,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.greet.title"),
                commandDescription: String(localized: "command.greet.desc"),
                difficulty: .intermediate,
                category: .social,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.settle.title"),
                commandDescription: String(localized: "command.settle.desc"),
                difficulty: .intermediate,
                category: .social,
                isPremium: true
            ),

            // MARK: Advanced / Premium

            Command(
                title: String(localized: "command.recall.title"),
                commandDescription: String(localized: "command.recall.desc"),
                difficulty: .advanced,
                category: .obedience,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.heel_off.title"),
                commandDescription: String(localized: "command.heel_off.desc"),
                difficulty: .advanced,
                category: .obedience,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.rollover.title"),
                commandDescription: String(localized: "command.rollover.desc"),
                difficulty: .advanced,
                category: .tricks,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.play_dead.title"),
                commandDescription: String(localized: "command.play_dead.desc"),
                difficulty: .advanced,
                category: .tricks,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.spin.title"),
                commandDescription: String(localized: "command.spin.desc"),
                difficulty: .advanced,
                category: .tricks,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.crawl.title"),
                commandDescription: String(localized: "command.crawl.desc"),
                difficulty: .advanced,
                category: .tricks,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.fetch.title"),
                commandDescription: String(localized: "command.fetch.desc"),
                difficulty: .advanced,
                category: .tricks,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.crowds.title"),
                commandDescription: String(localized: "command.crowds.desc"),
                difficulty: .advanced,
                category: .social,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.ignore_dogs.title"),
                commandDescription: String(localized: "command.ignore_dogs.desc"),
                difficulty: .advanced,
                category: .behavioral,
                isPremium: true
            ),
            Command(
                title: String(localized: "command.quiet.title"),
                commandDescription: String(localized: "command.quiet.desc"),
                difficulty: .advanced,
                category: .behavioral,
                isPremium: true
            ),
        ]
    }
}
