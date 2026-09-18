import SwiftUI
import SwiftData

struct EditDogView: View {
    @Bindable var dog: Dog

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var hasBirthDate: Bool
    @State private var birthDate: Date
    @State private var showSavedToast = false
    @FocusState private var breedFieldFocused: Bool

    private let popularBreeds = [
        "Yorkshire Terrier", "Labrador Retriever", "German Shepherd",
        "Golden Retriever", "Bulldog", "Poodle", "Beagle",
        "Chihuahua", "Boxer", "Rottweiler", "Mixed / Mestizo"
    ]

    init(dog: Dog) {
        self.dog = dog
        self._hasBirthDate = State(initialValue: dog.birthDate != nil)
        self._birthDate = State(initialValue: dog.birthDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Name
                Section(String(localized: "profile.edit.section.basics")) {
                    LabeledRow(label: String(localized: "profile.edit.name")) {
                        TextField(String(localized: "onboarding.name.placeholder"), text: $dog.name)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    }
                }

                // MARK: Breed (text field + popular chips)
                Section(String(localized: "profile.edit.breed")) {
                    TextField(String(localized: "onboarding.breed.placeholder"), text: $dog.breed)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .focused($breedFieldFocused)

                    // Popular breeds chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "onboarding.breed.popular"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(popularBreeds, id: \.self) { breed in
                                Button {
                                    dog.breed = breed
                                    breedFieldFocused = false
                                } label: {
                                    Text(breed)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(dog.breed == breed
                                            ? Color.accentColor.opacity(0.15)
                                            : Color.appNestedBackground)
                                        .foregroundStyle(dog.breed == breed ? Color.accentColor : .primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(dog.breed == breed
                                                              ? Color.accentColor.opacity(0.5)
                                                              : Color.clear, lineWidth: 1)
                                        )
                                        .animation(.easeInOut(duration: 0.15), value: dog.breed)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Birth date
                Section(String(localized: "profile.edit.section.birthdate")) {
                    Toggle(String(localized: "profile.edit.birthdate.set"), isOn: $hasBirthDate.animation())
                    if hasBirthDate {
                        DatePicker(
                            String(localized: "onboarding.breed.birthdate"),
                            selection: $birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                }

                // MARK: Level
                Section(String(localized: "profile.edit.section.level")) {
                    Picker(String(localized: "profile.edit.level"), selection: $dog.level) {
                        ForEach(DogLevel.allCases, id: \.rawValue) { level in
                            HStack(spacing: 6) {
                                BrandIcon(level.iconName, size: 18)
                                Text(level.localizedTitle)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(String(localized: "profile.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "profile.edit.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "profile.edit.done")) {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .overlay(alignment: .top) {
                if showSavedToast {
                    SavedToast()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Logic

    private var canSave: Bool {
        !dog.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dog.breed.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        dog.name  = dog.name.trimmingCharacters(in: .whitespaces)
        dog.breed = dog.breed.trimmingCharacters(in: .whitespaces)
        dog.birthDate = hasBirthDate ? birthDate : nil
        try? modelContext.save()

        // Показуємо toast → чекаємо 0.8с → закриваємо аркуш.
        withAnimation(.spring(response: 0.4)) { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

// MARK: - Saved toast

private struct SavedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appSage)
            Text(String(localized: "profile.edit.saved"))
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.appSage.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}

// MARK: - Labeled row helper

private struct LabeledRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            content()
        }
    }
}

#Preview {
    EditDogView(dog: Dog(name: "Рекс", breed: "Лабрадор", level: .adult))
        .modelContainer(ModelContainer.preview)
}
