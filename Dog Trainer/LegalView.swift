import SwiftUI

// MARK: - Legal document types

enum LegalDocument: Identifiable {
    case privacy
    case terms

    var id: String {
        switch self {
        case .privacy: return "privacy"
        case .terms:   return "terms"
        }
    }

    var titleKey: LocalizedStringResource {
        switch self {
        case .privacy: return "paywall.privacy"
        case .terms:   return "paywall.terms"
        }
    }

    var subtitle: String {
        switch self {
        case .privacy: return "How Dog Academy handles your data"
        case .terms:   return "Rules for using Dog Academy"
        }
    }

    var icon: String {
        switch self {
        case .privacy: return "lock.shield.fill"
        case .terms:   return "doc.text.fill"
        }
    }

    var tint: Color {
        switch self {
        case .privacy: return .appSage
        case .terms:   return .accentColor
        }
    }

    var sections: [LegalSection] {
        switch self {
        case .privacy: return LegalContent.privacy
        case .terms:   return LegalContent.terms
        }
    }
}

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

// MARK: - LegalView

struct LegalView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    private static let lastUpdated: String = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        // Дата останнього оновлення документів — оновлюй при змінах тексту.
        let comps = DateComponents(year: 2026, month: 9, day: 16)
        return df.string(from: Calendar.current.date(from: comps) ?? .now)
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HeroBlock(document: document)

                    ForEach(document.sections) { section in
                        SectionCard(title: section.title, text: section.text)
                    }

                    FooterBlock(lastUpdated: Self.lastUpdated)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: document.titleKey))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }
}

// MARK: - Hero

private struct HeroBlock: View {
    let document: LegalDocument

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(document.tint.opacity(0.15))
                    .frame(width: 84, height: 84)
                Image(systemName: document.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(document.tint)
            }
            Text(String(localized: document.titleKey))
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
            Text(document.subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Section card

private struct SectionCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appSageDark)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Footer

private struct FooterBlock: View {
    let lastUpdated: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("Last updated: \(lastUpdated)")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.secondary)

            Text("Questions? Contact us at lelyakupina@gmail.com")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}

// MARK: - Content

private enum LegalContent {

    static let privacy: [LegalSection] = [
        LegalSection(
            title: "1. Overview",
            text: "Dog Academy is a personal dog training companion. We designed the app to work primarily on your device — your training data stays with you unless you explicitly choose otherwise. This document explains what we collect, why, and what we don't."
        ),
        LegalSection(
            title: "2. Data stored on your device",
            text: "The app stores your dog's profile (name, breed, age, level, avatar), training sessions, learned commands, streak progress, and earned badges locally using Apple's SwiftData. This information never leaves your device."
        ),
        LegalSection(
            title: "3. Data we do NOT collect",
            text: "We do not use third-party analytics, advertising SDKs, or crash reporting services. We do not track your location, contacts, or browsing activity. We do not build a profile of you across apps or websites."
        ),
        LegalSection(
            title: "4. Subscriptions and payments",
            text: "Purchases are handled entirely by Apple through the App Store. Dog Academy receives only a receipt confirming your subscription status — never your payment details. Refer to Apple's privacy policy for how they handle transactions."
        ),
        LegalSection(
            title: "5. Photos and Image Playground",
            text: "If you generate a dog avatar, you pick a photo from your library. The photo is processed on-device by Apple's Image Playground and never uploaded to our servers. The generated image is stored locally with your dog profile."
        ),
        LegalSection(
            title: "6. Notifications",
            text: "Reminders and streak alerts are scheduled locally by the app. We do not send push notifications from any server and cannot see when or how you use them."
        ),
        LegalSection(
            title: "7. Siri and Shortcuts",
            text: "The app exposes App Intents to Siri and the Shortcuts app so you can log sessions by voice. These interactions are handled entirely by Apple on your device."
        ),
        LegalSection(
            title: "8. Children's privacy",
            text: "Dog Academy is intended for adult dog owners. We do not knowingly collect information from children under 13."
        ),
        LegalSection(
            title: "9. Data deletion",
            text: "You can delete all locally stored data at any time by removing the app. There is no server-side account to close."
        ),
        LegalSection(
            title: "10. Changes to this policy",
            text: "If we ever change what data the app handles, we will update this document and bump the last-updated date shown at the bottom. Continued use of the app after such an update means you accept the new terms."
        )
    ]

    static let terms: [LegalSection] = [
        LegalSection(
            title: "1. Acceptance",
            text: "By downloading and using Dog Academy, you agree to these terms. If you do not agree, please stop using the app and delete it from your device."
        ),
        LegalSection(
            title: "2. What Dog Academy provides",
            text: "Dog Academy offers dog training exercises, progress tracking, streaks, badges, and a library of commands. The app is a supportive tool — not a substitute for professional veterinary advice or certified dog behaviorists."
        ),
        LegalSection(
            title: "3. Subscriptions",
            text: "Premium features are unlocked through auto-renewing subscriptions billed by Apple. Prices, billing periods, and free-trial eligibility are shown on the paywall before you confirm the purchase."
        ),
        LegalSection(
            title: "4. Free trial",
            text: "New subscribers may receive a 14-day free trial. If you do not cancel at least 24 hours before the trial ends, the subscription renews automatically at the standard price. Only users who have never used a trial for this app are eligible."
        ),
        LegalSection(
            title: "5. Auto-renewal and cancellation",
            text: "Your subscription renews automatically for the same period at the same price unless you cancel. You can cancel at any time from Settings → your Apple ID → Subscriptions. Cancellation takes effect at the end of the current period."
        ),
        LegalSection(
            title: "6. Refunds",
            text: "All refunds are handled by Apple according to App Store policies. Dog Academy cannot issue refunds directly. Requests can be submitted at reportaproblem.apple.com."
        ),
        LegalSection(
            title: "7. Acceptable use",
            text: "Use the app for lawful, personal purposes. Do not attempt to reverse-engineer, resell, or redistribute the app or its content. Do not use the app in ways that could harm your dog or others."
        ),
        LegalSection(
            title: "8. Content and intellectual property",
            text: "All illustrations, text, and code in Dog Academy are owned by us or licensed to us. You receive a personal, non-transferable license to use the app on devices you own or control."
        ),
        LegalSection(
            title: "9. Disclaimer",
            text: "Training advice is offered as-is with no guarantees of results. Every dog is different — if your dog shows signs of anxiety, aggression, or medical issues, consult a veterinarian or certified trainer."
        ),
        LegalSection(
            title: "10. Limitation of liability",
            text: "To the maximum extent permitted by law, Dog Academy is not liable for indirect or consequential damages arising from your use of the app, including any harm to pets, property, or relationships."
        ),
        LegalSection(
            title: "11. Changes to these terms",
            text: "We may update these terms from time to time. Material changes will be reflected in the last-updated date. Continued use after an update means you accept the new terms."
        ),
        LegalSection(
            title: "12. Contact",
            text: "For questions about these terms, reach out at lelyakupina@gmail.com."
        )
    ]
}

// MARK: - Preview

#Preview("Privacy") {
    LegalView(document: .privacy)
}

#Preview("Terms") {
    LegalView(document: .terms)
}
