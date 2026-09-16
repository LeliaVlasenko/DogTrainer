import Foundation
import SwiftData

@Model
final class Dog {
    var name: String
    var breed: String
    var birthDate: Date?
    var level: DogLevel
    var createdAt: Date

    /// Кастомний аватар, згенерований через Image Playground з фото собаки.
    /// `nil` → показуємо стандартну BrandIcon для рівня.
    var avatarData: Data?

    @Relationship(deleteRule: .cascade, inverse: \TrainingSession.dog)
    var sessions: [TrainingSession]

    init(
        name: String,
        breed: String,
        birthDate: Date? = nil,
        level: DogLevel = .puppy
    ) {
        self.name = name
        self.breed = breed
        self.birthDate = birthDate
        self.level = level
        self.createdAt = .now
        self.sessions = []
    }

    /// Кількість днів підряд (streak)
    var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = sessions
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)

        guard let first = sortedDates.first,
              calendar.isDateInToday(first) || calendar.isDateInYesterday(first)
        else { return 0 }

        var streak = 1
        var current = first
        for date in sortedDates.dropFirst() {
            let diff = calendar.dateComponents([.day], from: date, to: current).day ?? 0
            if diff == 1 {
                streak += 1
                current = date
            } else {
                break
            }
        }
        return streak
    }

    /// Чи тренувались сьогодні
    var trainedToday: Bool {
        sessions.contains { Calendar.current.isDateInToday($0.date) }
    }
}

enum DogLevel: String, Codable, CaseIterable {
    case puppy       = "puppy"
    case adult       = "adult"
    case behavioral  = "behavioral"

    var localizedTitle: String {
        switch self {
        case .puppy:      return String(localized: "level.puppy")
        case .adult:      return String(localized: "level.adult")
        case .behavioral: return String(localized: "level.behavioral")
        }
    }

    var emoji: String {
        switch self {
        case .puppy:      return "🐶"
        case .adult:      return "🐕"
        case .behavioral: return "🦮"
        }
    }

    var iconName: BrandIconName {
        switch self {
        case .puppy:      return .dogPuppy
        case .adult:      return .dogAdult
        case .behavioral: return .dogGuide
        }
    }
}
