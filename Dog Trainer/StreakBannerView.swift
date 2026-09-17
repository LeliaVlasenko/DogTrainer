import SwiftUI
import SwiftData

struct StreakBannerView: View {
    let dog: Dog
    let sessions: [TrainingSession]

    private var totalSessions: Int { sessions.count }

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var masteredCount: Int {
        // Запитуємо через dog.sessions всі команди — тут передаємо через sessions
        0 // оновлюється в CommandsProgressView
    }

    private var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDays = Set(
            sessions.map { calendar.startOfDay(for: $0.date) }
        ).sorted(by: >)

        guard !sortedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i], to: sortedDays[i-1]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    var body: some View {
        VStack(spacing: 16) {
            // Streak hero
            HStack(spacing: 12) {
                // Fire circle
                ZStack {
                    Circle()
                        .fill(dog.currentStreak > 0
                              ? Color.appFlame.opacity(0.15)
                              : Color.secondary.opacity(0.08))
                        .frame(width: 64, height: 64)
                    BrandIcon(dog.currentStreak > 0 ? .flame : .sleep, size: 48)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(dog.currentStreak)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(dog.currentStreak > 0 ? Color.appFlame : .secondary)
                            .contentTransition(.numericText())
                        Text(String(localized: "progress.streak.days"))
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                    }
                    Text(streakSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Best streak
                VStack(spacing: 2) {
                    BrandIcon(.trophy, size: 26)
                    Text("\(longestStreak)")
                        .font(.system(size: 18, weight: .bold))
                    Text(String(localized: "progress.streak.best"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 52)
            }

            Divider()

            // Stats row
            HStack(spacing: 0) {
                StatPill(
                    value: "\(totalSessions)",
                    label: String(localized: "progress.stat.sessions"),
                    icon: "figure.walk.dog"
                )
                Divider().frame(height: 32)
                StatPill(
                    value: "\(totalMinutes)",
                    label: String(localized: "progress.stat.minutes"),
                    icon: "clock"
                )
                Divider().frame(height: 32)
                StatPill(
                    value: dog.trainedToday
                           ? String(localized: "progress.stat.today.yes")
                           : String(localized: "progress.stat.today.no"),
                    label: String(localized: "progress.stat.today"),
                    icon: dog.trainedToday ? "checkmark.circle.fill" : "circle"
                )
            }
        }
        .cardStyle(radius: 18)
        // Success-haptic коли streak долає milestone. Тригер спрацьовує
        // при зміні числа — якщо нове = 3/7/14/30, віддаємо feedback.
        .sensoryFeedback(trigger: dog.currentStreak) { _, newValue in
            [3, 7, 14, 30].contains(newValue) ? .success : nil
        }
    }

    private var streakSubtitle: String {
        if dog.currentStreak == 0 {
            return String(localized: "progress.streak.start")
        } else if dog.currentStreak == longestStreak && longestStreak > 1 {
            return String(localized: "progress.streak.record")
        } else {
            return String(localized: "progress.streak.keep")
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
