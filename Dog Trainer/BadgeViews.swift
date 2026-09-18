import SwiftUI

// MARK: - Badge toast (показується поверх будь-якого екрану)

struct BadgeToastOverlay: View {
    @Bindable var achievements: AchievementManager

    var body: some View {
        if let badge = achievements.newlyEarned {
            VStack {
                Spacer()
                BadgeToast(badge: badge) {
                    achievements.newlyEarned = nil
                }
                .padding(.bottom, 100)  // вище tab bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: achievements.newlyEarned?.id)
            }
            .allowsHitTesting(true)
            .zIndex(999)
        }
    }
}

private struct BadgeToast: View {
    let badge: BadgeDefinition
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            Text(badge.emoji)
                .font(.system(size: 36))
                .scaleEffect(appeared ? 1 : 0.3)
                .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1), value: appeared)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "badge.toast.title"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(String(localized: badge.titleKey))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(String(localized: badge.descriptionKey))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "xmark")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .onTapGesture { onDismiss() }
        }
        .cardStyle(radius: 18)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .onAppear { appeared = true }
    }
}

// MARK: - Badge card (для AllBadgesView)

struct BadgeCard: View {
    let definition: BadgeDefinition
    let isEarned: Bool
    let earnedAt: Date?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isEarned
                          ? Color.accentColor.opacity(0.1)
                          : Color.secondary.opacity(0.06))
                    .frame(width: 64, height: 64)

                Text(definition.emoji)
                    .font(.system(size: 32))
                    .grayscale(isEarned ? 0 : 1)
                    .opacity(isEarned ? 1 : 0.35)

                if isEarned {
                    Circle()
                        .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 2)
                        .frame(width: 64, height: 64)
                }
            }

            Text(String(localized: definition.titleKey))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isEarned ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let date = earnedAt {
                Text(date.formatted(.dateTime.day().month()))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else {
                Text(String(localized: "badge.locked"))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isEarned ? Color.accentColor.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - View modifier для підключення toast

extension View {
    /// Додає bottom-overlay з toast-сповіщенням про новий бейдж.
    /// Менеджер передається явно, щоб уникнути проблем з пропагуванням
    /// `@Environment(_ : Observable)` у overlay-замиканні.
    func badgeToastOverlay(_ manager: AchievementManager) -> some View {
        overlay(alignment: .bottom) {
            BadgeToastOverlay(achievements: manager)
        }
    }
}
