import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @AppStorage("onboardingDone") private var onboardingDone = false

    @State private var currentStep = 0
    @State private var dogName = ""
    @State private var dogBreed = ""
    @State private var dogBirthDate: Date? = nil
    @State private var dogLevel: DogLevel = .puppy

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i <= currentStep ? Color.accentColor : Color.secondary.opacity(0.25))
                            .frame(width: i == currentStep ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentStep)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)

                // Step content
                TabView(selection: $currentStep) {
                    OnboardingNameView(dogName: $dogName)
                        .tag(0)
                    OnboardingBreedView(dogBreed: $dogBreed, birthDate: $dogBirthDate)
                        .tag(1)
                    OnboardingLevelView(dogLevel: $dogLevel, dogName: dogName)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                // Navigation buttons
                VStack(spacing: 12) {
                    Button(action: advance) {
                        Text(currentStep == 2
                             ? String(localized: "onboarding.start")
                             : String(localized: "onboarding.next"))
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(canAdvance ? Color.accentColor : Color.secondary.opacity(0.2))
                            .foregroundStyle(canAdvance ? .white : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canAdvance)
                    .animation(.easeInOut(duration: 0.2), value: canAdvance)

                    if currentStep > 0 {
                        Button(String(localized: "onboarding.back")) {
                            withAnimation { currentStep -= 1 }
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    } else {
                        Spacer().frame(height: 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Logic

    private var canAdvance: Bool {
        switch currentStep {
        case 0: return dogName.trimmingCharacters(in: .whitespaces).count >= 2
        case 1: return dogBreed.trimmingCharacters(in: .whitespaces).count >= 2
        case 2: return true
        default: return false
        }
    }

    private func advance() {
        if currentStep < 2 {
            withAnimation { currentStep += 1 }
        } else {
            saveDogAndFinish()
        }
    }

    private func saveDogAndFinish() {
        let dog = Dog(
            name: dogName.trimmingCharacters(in: .whitespaces),
            breed: dogBreed.trimmingCharacters(in: .whitespaces),
            birthDate: dogBirthDate,
            level: dogLevel
        )
        modelContext.insert(dog)

        // Seed базові команди при першому запуску
        for command in Command.seedCommands() {
            modelContext.insert(command)
        }

        try? modelContext.save()

        // Фіксуємо поточну версію seed-набору, щоб top-up при старті нічого не дублював
        UserDefaults.standard.set(Command.currentSeedVersion, forKey: Command.seedVersionKey)

        // Запит дозволу на сповіщення + первинне планування
        Task {
            _ = await notificationManager.requestPermission()
            await notificationManager.rescheduleAll(dog: dog)
        }

        onboardingDone = true
    }
}

#Preview {
    OnboardingView()
        .modelContainer(ModelContainer.preview)
        .environment(NotificationManager())
}
