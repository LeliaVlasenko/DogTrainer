import SwiftUI

// MARK: - Error recovery view
//
// Уніфікований UI для error-станів у застосунку.
// Використовується коли операція впала і юзер може retry (напр. products
// не завантажились у paywall, або permission-запит на нотіфікації fail).
//
// Приклад:
//   if let error = subscriptionManager.productsFetchError {
//       ErrorRecoveryView(
//           title: "Products unavailable",
//           message: error,
//           retryTitle: "Retry"
//       ) {
//           Task { await subscriptionManager.initialize() }
//       }
//   }

struct ErrorRecoveryView: View {
    let title: String
    let message: String?
    let icon: String
    let tint: Color
    let retryTitle: String
    let retry: () -> Void

    init(
        title: String,
        message: String? = nil,
        icon: String = "exclamationmark.triangle.fill",
        tint: Color = .appFlame,
        retryTitle: String,
        retry: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.tint = tint
        self.retryTitle = retryTitle
        self.retry = retry
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(tint)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.center)

            if let message, !message.isEmpty {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }

            Button(action: retry) {
                Label(retryTitle, systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(tint.opacity(0.15))
                    .foregroundStyle(tint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

#Preview {
    ErrorRecoveryView(
        title: "Products unavailable",
        message: "Check your internet connection and try again.",
        retryTitle: "Retry"
    ) {}
    .padding()
    .background(Color.appBackground)
}
