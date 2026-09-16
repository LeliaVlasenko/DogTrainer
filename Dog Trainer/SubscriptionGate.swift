import SwiftUI

// MARK: - Gate modifier

/// Використання:
/// SomeView()
///     .subscriptionGate(reason: "Unlock all commands")
struct SubscriptionGateModifier: ViewModifier {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    let reason: String

    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if subscriptionManager.isPremium {
            content
        } else {
            content
                .blur(radius: 4)
                .overlay {
                    GateLockView(reason: reason) {
                        showPaywall = true
                    }
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
        }
    }
}

extension View {
    func subscriptionGate(reason: String = "") -> some View {
        modifier(SubscriptionGateModifier(reason: reason))
    }
}

// MARK: - Lock overlay

private struct GateLockView: View {
    let reason: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            if !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text(String(localized: "paywall.unlock"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Status banner (для Home Screen)

/// Показуємо у HomeView якщо trial закінчується скоро
struct TrialReminderBanner: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false

    var body: some View {
        if case .trial(let days) = subscriptionManager.status, days <= 3 {
            Button { showPaywall = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(Color.appFlame)
                    Text(days == 0
                         ? String(localized: "trial.ends.today")
                         : String(localized: "trial.ends.days \(days)"))
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text(String(localized: "trial.subscribe"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(14)
                .background(Color.appFlame.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.appFlame.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}
