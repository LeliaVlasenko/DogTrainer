import SwiftUI

struct OnboardingNameView: View {
    @Binding var dogName: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Illustration
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                    BrandIcon(.paw, size: 80)
                }
                .padding(.top, 24)

                // Title
                VStack(spacing: 8) {
                    Text(String(localized: "onboarding.name.title"))
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(String(localized: "onboarding.name.subtitle"))
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "onboarding.name.label"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextField(String(localized: "onboarding.name.placeholder"), text: $dogName)
                        .font(.system(size: 20, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .focused($isFocused)
                        .submitLabel(.next)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                .padding(.horizontal, 4)

                // Character preview
                if !dogName.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.appSage)
                        Text(String(localized: "onboarding.name.preview \(dogName)"))
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.spring(response: 0.4), value: dogName.isEmpty)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { isFocused = true }
    }
}

#Preview {
    OnboardingNameView(dogName: .constant("Рекс"))
}
