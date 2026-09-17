import SwiftUI
import SwiftData

// MARK: - Add dog sheet
//
// Спрощений flow для додавання додаткової собаки з ProfileView.
// Використовує ті самі суб-в'юшки що й онбординг (Name / Breed / Level).

struct AddDogSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var dogName = ""
    @State private var dogBreed = ""
    @State private var dogBirthDate: Date? = nil
    @State private var dogLevel: DogLevel = .puppy

    var body: some View {
        NavigationStack {
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
                    .padding(.top, 8)
                    .padding(.bottom, 8)

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

                    VStack(spacing: 12) {
                        Button(action: advance) {
                            Text(currentStep == 2
                                 ? String(localized: "profile.dog.add.save")
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
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(String(localized: "profile.dog.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "profile.edit.cancel")) { dismiss() }
                }
            }
        }
    }

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
            save()
        }
    }

    private func save() {
        let dog = Dog(
            name: dogName.trimmingCharacters(in: .whitespaces),
            breed: dogBreed.trimmingCharacters(in: .whitespaces),
            birthDate: dogBirthDate,
            level: dogLevel
        )
        modelContext.insert(dog)
        try? modelContext.save()
        DogSelection.select(dog)
        dismiss()
    }
}
