import SwiftUI

struct OnboardingLevelView: View {
    @Binding var dogLevel: DogLevel
    let dogName: String

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Illustration
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Text("🎓")
                        .font(.system(size: 56))
                }
                .padding(.top, 24)

                // Title
                VStack(spacing: 8) {
                    Text(String(localized: "onboarding.level.title \(dogName)"))
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(String(localized: "onboarding.level.subtitle"))
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Level cards
                VStack(spacing: 12) {
                    ForEach(DogLevel.allCases, id: \.rawValue) { level in
                        LevelCard(level: level, isSelected: dogLevel == level) {
                            withAnimation(.spring(response: 0.35)) {
                                dogLevel = level
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Tip
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 14))
                    Text(String(localized: "onboarding.level.tip"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.yellow.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 4)

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Level card

private struct LevelCard: View {
    let level: DogLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji circle
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? Color.accentColor.opacity(0.15)
                              : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 52, height: 52)
                    Text(level.emoji)
                        .font(.system(size: 26))
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.localizedTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(levelDescription(level))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func levelDescription(_ level: DogLevel) -> String {
        switch level {
        case .puppy:
            return String(localized: "onboarding.level.puppy.desc")
        case .adult:
            return String(localized: "onboarding.level.adult.desc")
        case .behavioral:
            return String(localized: "onboarding.level.behavioral.desc")
        }
    }
}

#Preview {
    OnboardingLevelView(dogLevel: .constant(.puppy), dogName: "Рекс")
}
