import Foundation
import SwiftData

// MARK: - Badge definition (статичний каталог)

struct BadgeDefinition: Identifiable {
    let id: String
    let emoji: String
    let titleKey: LocalizedStringResource
    let descriptionKey: LocalizedStringResource
    let category: BadgeCategory

    enum BadgeCategory {
        case streak, mastery, sessions, special
    }
}

// MARK: - Earned badge (зберігається в SwiftData)

@Model
final class EarnedBadge {
    var badgeId: String
    var earnedAt: Date

    init(badgeId: String, earnedAt: Date = .now) {
        self.badgeId = badgeId
        self.earnedAt = earnedAt
    }
}

// MARK: - Badge catalog

enum BadgeCatalog {
    static let all: [BadgeDefinition] = [

        // MARK: Streak
        BadgeDefinition(
            id: "streak_3",
            emoji: "🔥",
            titleKey: "badge.streak3.title",
            descriptionKey: "badge.streak3.desc",
            category: .streak
        ),
        BadgeDefinition(
            id: "streak_7",
            emoji: "🔥🔥",
            titleKey: "badge.streak7.title",
            descriptionKey: "badge.streak7.desc",
            category: .streak
        ),
        BadgeDefinition(
            id: "streak_14",
            emoji: "⚡️",
            titleKey: "badge.streak14.title",
            descriptionKey: "badge.streak14.desc",
            category: .streak
        ),
        BadgeDefinition(
            id: "streak_30",
            emoji: "🏆",
            titleKey: "badge.streak30.title",
            descriptionKey: "badge.streak30.desc",
            category: .streak
        ),

        // MARK: Sessions
        BadgeDefinition(
            id: "sessions_1",
            emoji: "🐾",
            titleKey: "badge.sessions1.title",
            descriptionKey: "badge.sessions1.desc",
            category: .sessions
        ),
        BadgeDefinition(
            id: "sessions_5",
            emoji: "⭐️",
            titleKey: "badge.sessions5.title",
            descriptionKey: "badge.sessions5.desc",
            category: .sessions
        ),
        BadgeDefinition(
            id: "sessions_10",
            emoji: "🌟",
            titleKey: "badge.sessions10.title",
            descriptionKey: "badge.sessions10.desc",
            category: .sessions
        ),
        BadgeDefinition(
            id: "sessions_25",
            emoji: "💎",
            titleKey: "badge.sessions25.title",
            descriptionKey: "badge.sessions25.desc",
            category: .sessions
        ),
        BadgeDefinition(
            id: "sessions_50",
            emoji: "👑",
            titleKey: "badge.sessions50.title",
            descriptionKey: "badge.sessions50.desc",
            category: .sessions
        ),

        // MARK: Mastery
        BadgeDefinition(
            id: "mastery_1",
            emoji: "🎯",
            titleKey: "badge.mastery1.title",
            descriptionKey: "badge.mastery1.desc",
            category: .mastery
        ),
        BadgeDefinition(
            id: "mastery_3",
            emoji: "🎓",
            titleKey: "badge.mastery3.title",
            descriptionKey: "badge.mastery3.desc",
            category: .mastery
        ),
        BadgeDefinition(
            id: "mastery_5",
            emoji: "🏅",
            titleKey: "badge.mastery5.title",
            descriptionKey: "badge.mastery5.desc",
            category: .mastery
        ),

        // MARK: Special
        BadgeDefinition(
            id: "perfect_session",
            emoji: "✨",
            titleKey: "badge.perfect.title",
            descriptionKey: "badge.perfect.desc",
            category: .special
        ),
        BadgeDefinition(
            id: "weekend_warrior",
            emoji: "🌅",
            titleKey: "badge.weekend.title",
            descriptionKey: "badge.weekend.desc",
            category: .special
        ),
        BadgeDefinition(
            id: "early_bird",
            emoji: "🌄",
            titleKey: "badge.earlybird.title",
            descriptionKey: "badge.earlybird.desc",
            category: .special
        ),
    ]

    static func definition(for id: String) -> BadgeDefinition? {
        all.first { $0.id == id }
    }
}
