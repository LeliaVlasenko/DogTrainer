import SwiftUI

// MARK: - SectionCard
//
// Секція з заголовком і content-карткою. Використовується у Profile,
// Paywall, Progress, Library — всюди, де є "заголовок → cream-картка".

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            content()
                .cardStyle()
        }
    }
}

// MARK: - PrimaryButton
//
// Головна CTA-кнопка (accent-фон, білий текст, повна ширина).
// Використання:
//   PrimaryButton(String(localized: "some.cta"), isLoading: false) { action() }
//   PrimaryButton { Text("Custom label") } action: { ... }

struct PrimaryButton<Label: View>: View {
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    @ViewBuilder let label: () -> Label

    init(
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    SwiftUI.ProgressView().tint(.white)
                } else {
                    label()
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isDisabled ? Color.secondary.opacity(0.3) : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// Convenience-ініт для тексту-мітки.
extension PrimaryButton where Label == Text {
    init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        ) {
            Text(title)
        }
    }
}

// MARK: - SecondaryButton
//
// Другорядна кнопка (нейтральний фон, primary текст). Для action'ів
// типу "Skip" / "Cancel" / "Edit" поруч з PrimaryButton.

struct SecondaryButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    init(
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .font(.system(size: 15, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.secondary.opacity(0.12))
                .foregroundStyle(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

extension SecondaryButton where Label == Text {
    init(_ title: String, action: @escaping () -> Void) {
        self.init(action: action) { Text(title) }
    }
}
