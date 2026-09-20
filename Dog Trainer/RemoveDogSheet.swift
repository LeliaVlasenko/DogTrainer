import SwiftUI
import SwiftData

// MARK: - RemoveDogSheet
//
// Двоетапний sheet замість голого destructive-alert:
//   1) Вибір причини — «пам'ять» (собаки більше немає) або інша.
//   2) Відповідне підтвердження з тональністю та кольором під контекст.
// Мета — гідність у делікатний момент замість холодного "Delete".

struct RemoveDogSheet: View {
    let dog: Dog
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .pickReason

    enum Stage: Equatable {
        case pickReason
        case memorial
        case other
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch stage {
                case .pickReason: PickReasonView(dog: dog, onPick: pick, onCancel: dismissSheet)
                case .memorial:   MemorialConfirmView(dog: dog, onConfirm: confirm, onBack: back)
                case .other:      OtherConfirmView(dog: dog, onConfirm: confirm, onBack: back)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .presentationDetents([.height(600)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func pick(_ reason: Stage) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            stage = reason
        }
    }

    private func back() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            stage = .pickReason
        }
    }

    private func confirm() {
        // Спершу закриваємо цей sheet, а delete + dismiss батька виконуємо
        // після анімації, інакше iOS зависає на вкладених sheets.
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onConfirm()
        }
    }

    private func dismissSheet() {
        dismiss()
    }
}

// MARK: - Stage 1: Pick reason

private struct PickReasonView: View {
    let dog: Dog
    let onPick: (RemoveDogSheet.Stage) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            DogHeader(dog: dog)
                .padding(.top, 16)

            VStack(spacing: 6) {
                Text(String(localized: "profile.remove.title \(dog.name)"))
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(String(localized: "profile.remove.subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ReasonCard(
                    iconSystem: "heart.fill",
                    tint: .appSage,
                    title: String(localized: "profile.remove.option.memorial.title"),
                    subtitle: String(localized: "profile.remove.option.memorial.subtitle \(dog.name)"),
                    action: { onPick(.memorial) }
                )

                ReasonCard(
                    iconSystem: "house.fill",
                    tint: .appFlame,
                    title: String(localized: "profile.remove.option.other.title"),
                    subtitle: String(localized: "profile.remove.option.other.subtitle"),
                    action: { onPick(.other) }
                )
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)

            SecondaryButton(String(localized: "profile.edit.cancel"), action: onCancel)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }
}

private struct ReasonCard: View {
    let iconSystem: String
    let tint: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: iconSystem)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(tint.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stage 2a: Memorial confirmation

private struct MemorialConfirmView: View {
    let dog: Dog
    let onConfirm: () -> Void
    let onBack: () -> Void

    private var sessionCount: Int { dog.sessions.count }
    private var daysTogether: Int {
        max(1, Calendar.current.dateComponents([.day], from: dog.createdAt, to: .now).day ?? 1)
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appSage.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "heart.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.appSage)
            }
            .padding(.top, 24)

            VStack(spacing: 8) {
                Text(String(localized: "profile.remove.memorial.title \(dog.name)"))
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(String(localized: "profile.remove.memorial.body \(dog.name)"))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            // Соломинка спогадів — щоб момент був про життя, а не про видалення.
            HStack(spacing: 24) {
                StatBadge(
                    value: "\(sessionCount)",
                    label: String(localized: "profile.remove.memorial.stat.sessions")
                )
                Rectangle()
                    .fill(Color.appSage.opacity(0.2))
                    .frame(width: 1, height: 32)
                StatBadge(
                    value: "\(daysTogether)",
                    label: String(localized: "profile.remove.memorial.stat.days")
                )
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.appSage.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                PrimaryButton(
                    action: onConfirm,
                    label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart")
                                .font(.system(size: 15, weight: .semibold))
                            Text(String(localized: "profile.remove.memorial.cta"))
                        }
                    }
                )
                SecondaryButton(String(localized: "profile.remove.back"), action: onBack)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

private struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.appSageDark)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stage 2b: Other reason confirmation

private struct OtherConfirmView: View {
    let dog: Dog
    let onConfirm: () -> Void
    let onBack: () -> Void

    private var sessionCount: Int { dog.sessions.count }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appCoral.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.appCoral)
            }
            .padding(.top, 24)

            VStack(spacing: 8) {
                Text(String(localized: "profile.remove.other.title \(dog.name)"))
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(String(localized: "profile.remove.other.body"))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            if sessionCount > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appCoral)
                    Text(String(localized: "profile.remove.other.stat \(sessionCount)"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appCoral.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text(String(localized: "profile.remove.other.cta \(dog.name)"))
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.appCoral)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                SecondaryButton(String(localized: "profile.remove.back"), action: onBack)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Dog header

private struct DogHeader: View {
    let dog: Dog

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 72, height: 72)
                DogAvatar(dog: dog, size: 72)
            }
            Text(dog.name)
                .font(.system(size: 17, weight: .semibold))
            Text(dog.breed)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Pick reason") {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            RemoveDogSheet(
                dog: Dog(name: "Buddy", breed: "Labrador", level: .adult),
                onConfirm: {}
            )
        }
}
