import SwiftData
import SwiftUI

// MARK: - AchievementManager

@MainActor
@Observable
final class AchievementManager {

    // Новий бейдж щойно отриманий — показуємо toast
    var newlyEarned: BadgeDefinition? = nil

    // MARK: - Check after every session

    /// Викликати одразу після збереження TrainingSession.
    /// Повертає всі нові бейджі отримані за цю сесію.
    func checkAfterSession(
        session: TrainingSession,
        dog: Dog,
        allSessions: [TrainingSession],
        allCommands: [Command],
        earnedBadges: [EarnedBadge],
        context: ModelContext
    ) {
        // Читаємо свіжі бейджі з контексту, а не з @Query-snapshot.
        // Snapshot може відставати між швидкими викликами (дві сесії підряд),
        // і той самий бейдж буде вставлений двічі.
        let fresh = (try? context.fetch(FetchDescriptor<EarnedBadge>())) ?? earnedBadges
        let earnedIds = Set(fresh.map { $0.badgeId })
        var newBadges: [BadgeDefinition] = []

        // Streak badges
        let streak = dog.currentStreak
        for threshold in [3, 7, 14, 30] {
            let id = "streak_\(threshold)"
            if streak >= threshold, !earnedIds.contains(id),
               let def = BadgeCatalog.definition(for: id) {
                newBadges.append(def)
                context.insert(EarnedBadge(badgeId: id))
            }
        }

        // Session count badges
        let totalSessions = allSessions.count
        for threshold in [1, 5, 10, 25, 50] {
            let id = "sessions_\(threshold)"
            if totalSessions >= threshold, !earnedIds.contains(id),
               let def = BadgeCatalog.definition(for: id) {
                newBadges.append(def)
                context.insert(EarnedBadge(badgeId: id))
            }
        }

        // Mastery badges
        let mastered = allCommands.filter { $0.isMastered }.count
        for threshold in [1, 3, 5] {
            let id = "mastery_\(threshold)"
            if mastered >= threshold, !earnedIds.contains(id),
               let def = BadgeCatalog.definition(for: id) {
                newBadges.append(def)
                context.insert(EarnedBadge(badgeId: id))
            }
        }

        // Perfect session (100% success rate)
        if session.successRate == 1.0,
           !session.commandResults.isEmpty,
           !earnedIds.contains("perfect_session"),
           let def = BadgeCatalog.definition(for: "perfect_session") {
            newBadges.append(def)
            context.insert(EarnedBadge(badgeId: "perfect_session"))
        }

        // Weekend warrior (trained on Saturday or Sunday)
        let weekday = Calendar.current.component(.weekday, from: session.date)
        if [1, 7].contains(weekday),
           !earnedIds.contains("weekend_warrior"),
           let def = BadgeCatalog.definition(for: "weekend_warrior") {
            newBadges.append(def)
            context.insert(EarnedBadge(badgeId: "weekend_warrior"))
        }

        // Early bird (trained before 8am)
        let hour = Calendar.current.component(.hour, from: session.date)
        if hour < 8,
           !earnedIds.contains("early_bird"),
           let def = BadgeCatalog.definition(for: "early_bird") {
            newBadges.append(def)
            context.insert(EarnedBadge(badgeId: "early_bird"))
        }

        try? context.save()

        // Показати toast для першого нового бейджу
        // (якщо їх кілька — покажемо по одному з затримкою)
        showSequentially(newBadges)
    }

    // MARK: - Toast queue

    private func showSequentially(_ badges: [BadgeDefinition]) {
        guard !badges.isEmpty else { return }
        var delay = 0.5
        for badge in badges {
            let b = badge
            let d = delay
            Task {
                try? await Task.sleep(for: .seconds(d))
                newlyEarned = b
                try? await Task.sleep(for: .seconds(3))
                if newlyEarned?.id == b.id { newlyEarned = nil }
            }
            delay += 3.5
        }
    }
}
