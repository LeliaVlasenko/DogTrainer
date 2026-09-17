import SwiftUI
import SwiftData

struct LibraryCommandDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(AchievementManager.self) private var achievementManager
    @Query private var dogs: [Dog]
    @AppStorage(DogSelection.key) private var selectedID: String = ""

    let command: Command

    @State private var showPaywall = false
    @State private var trainingCommand: Command? = nil

    private var dog: Dog? {
        DogSelection.resolve(from: dogs, selectedIDString: selectedID)
    }

    private var isLocked: Bool {
        command.isPremium && !subscriptionManager.isPremium
    }

    private var categoryColor: Color {
        switch command.category {
        case .obedience:  return Color.appSage
        case .social:     return Color.appRose
        case .tricks:     return Color.appFlame
        case .behavioral: return Color.appCoral
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: command.category.systemImage)
                                .font(.system(size: 36))
                                .foregroundStyle(categoryColor)
                        }

                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                Text(command.title)
                                    .font(.system(size: 24, weight: .bold))
                                if command.isPremium {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.appGold)
                                }
                            }

                            HStack(spacing: 10) {
                                Label(command.category.localizedTitle,
                                      systemImage: command.category.systemImage)
                                Text("·")
                                Label(command.difficulty.localizedTitle,
                                      systemImage: "signal")
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Progress (якщо не locked)
                    if !isLocked && command.successCount > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(String(localized: "library.detail.progress"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(command.isMastered
                                     ? String(localized: "command.mastered")
                                     : "\(command.successCount)/5")
                                    .font(.system(size: 13))
                                    .foregroundStyle(command.isMastered ? Color.appSage : .secondary)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(command.isMastered ? Color.appSage : categoryColor)
                                        .frame(width: geo.size.width * command.progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(16)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "library.detail.about"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(command.commandDescription)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Steps
                    if !command.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "lesson.steps.title"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            if isLocked {
                                LockedStepsView()
                            } else {
                                ForEach(Array(command.steps.enumerated()), id: \.offset) { idx, step in
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(categoryColor.opacity(0.1))
                                                .frame(width: 28, height: 28)
                                            Text("\(idx + 1)")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(categoryColor)
                                        }
                                        Text(step)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appNestedBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // CTA
                    if isLocked {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                Text(String(localized: "paywall.unlock"))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        // Start training button
                        if dog != nil {
                            Button {
                                trainingCommand = command
                            } label: {
                                Label(String(localized: "library.detail.start"), systemImage: "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }

                        // Tip
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb")
                                .foregroundStyle(Color.appGold)
                            Text(String(localized: "library.detail.tip"))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appGold.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .fullScreenCover(item: $trainingCommand) { cmd in
            if let dog {
                TrainingSessionView(dog: dog, commands: [cmd])
                    .environment(notificationManager)
                    .environment(achievementManager)
            }
        }
    }
}

// MARK: - Locked steps placeholder

private struct LockedStepsView: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3) { i in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 28, height: 28)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 14)
                        .frame(maxWidth: i == 2 ? 120 : .infinity)
                }
                .padding(12)
                .background(Color.appNestedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(1.0 - Double(i) * 0.25)
            }
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                Text(String(localized: "library.steps.locked"))
                    .font(.system(size: 12))
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }
}

#Preview {
    LibraryCommandDetailView(
        command: Command(
            title: "Sit",
            commandDescription: "The most fundamental command for any dog.",
            difficulty: .beginner,
            category: .obedience,
            steps: [
                "Hold a treat close to your dog's nose",
                "Move your hand up — the dog's bottom will lower",
                "Once sitting, say 'Sit' clearly",
                "Give the treat and praise warmly"
            ]
        )
    )
    .environment(SubscriptionManager())
}
