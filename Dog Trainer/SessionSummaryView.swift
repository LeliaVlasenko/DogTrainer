import SwiftUI

struct SessionSummaryView: View {
    let dog: Dog
    let results: [CommandResult]
    let duration: Int
    let onDone: () -> Void

    @State private var appeared = false
    @State private var moodSelection: SessionMood = .good

    private var successCount: Int { results.filter { $0.succeeded }.count }
    private var totalCount: Int { results.count }
    private var successRate: Int { totalCount > 0 ? Int(Double(successCount) / Double(totalCount) * 100) : 0 }

    /// Streak, який буде після збереження цієї сесії. Сама сесія ще не в БД,
    /// тому dog.currentStreak ще не враховує сьогоднішнє тренування.
    private var projectedStreak: Int {
        dog.trainedToday ? dog.currentStreak : dog.currentStreak + 1
    }

    private var summaryIcon: BrandIconName {
        switch successRate {
        case 100:      return .trophy
        case 67...:    return .star
        case 34...:    return .thumbsUp
        default:       return .muscle
        }
    }

    private var summaryTitle: String {
        switch successRate {
        case 100:   return String(localized: "summary.perfect")
        case 67...: return String(localized: "summary.great")
        case 34...: return String(localized: "summary.good")
        default:    return String(localized: "summary.keepgoing")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trophy
                VStack(spacing: 8) {
                    BrandIcon(summaryIcon, size: 96)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

                    Text(summaryTitle)
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut.delay(0.3), value: appeared)

                    Text(String(localized: "summary.subtitle \(dog.name)"))
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut.delay(0.4), value: appeared)
                }
                .padding(.top, 20)

                // Stats row
                HStack(spacing: 12) {
                    StatCard(
                        value: "\(successCount)/\(totalCount)",
                        label: String(localized: "summary.stat.commands"),
                        icon: "checkmark.circle",
                        color: .green
                    )
                    StatCard(
                        value: "\(duration / 60):\(String(format: "%02d", duration % 60))",
                        label: String(localized: "summary.stat.time"),
                        icon: "clock",
                        color: .blue
                    )
                    StatCard(
                        value: "\(projectedStreak)🔥",
                        label: String(localized: "summary.stat.streak"),
                        icon: "flame",
                        color: .orange
                    )
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.5), value: appeared)

                // Results list
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(localized: "summary.results.title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ForEach(results, id: \.commandId) { result in
                        HStack(spacing: 12) {
                            Image(systemName: result.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(result.succeeded ? Color.appSage : Color.secondary.opacity(0.5))
                            Text(result.commandTitle)
                                .font(.system(size: 15))
                            Spacer()
                            Text(result.succeeded
                                 ? String(localized: "summary.result.success")
                                 : String(localized: "summary.result.skip"))
                                .font(.system(size: 12))
                                .foregroundStyle(result.succeeded ? Color.appSage : .secondary)
                        }
                        .padding(12)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.6), value: appeared)

                // Mood picker
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(localized: "summary.mood.title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(SessionMood.allCases, id: \.rawValue) { mood in
                            Button {
                                withAnimation(.spring(response: 0.3)) { moodSelection = mood }
                            } label: {
                                VStack(spacing: 4) {
                                    BrandIcon(mood.iconName, size: 36)
                                    Text(mood.localizedTitle)
                                        .font(.system(size: 10))
                                        .foregroundStyle(moodSelection == mood ? Color.accentColor : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(moodSelection == mood
                                            ? Color.accentColor.opacity(0.1)
                                            : Color.appCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(moodSelection == mood
                                                      ? Color.accentColor.opacity(0.5)
                                                      : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.7), value: appeared)

                // Done button
                Button(action: onDone) {
                    Text(String(localized: "summary.done"))
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.8), value: appeared)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            appeared = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .bold))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        SessionSummaryView(
            dog: Dog(name: "Рекс", breed: "Лабрадор", level: .adult),
            results: [
                CommandResult(commandId: UUID(), commandTitle: "Sit", succeeded: true),
                CommandResult(commandId: UUID(), commandTitle: "Stay", succeeded: false),
                CommandResult(commandId: UUID(), commandTitle: "Come", succeeded: true)
            ],
            duration: 287,
            onDone: {}
        )
    }
}
