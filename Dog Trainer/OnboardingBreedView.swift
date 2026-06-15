import SwiftUI

struct OnboardingBreedView: View {
    @Binding var dogBreed: String
    @Binding var birthDate: Date?
    @FocusState private var isFocused: Bool

    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    // Популярні породи в Іспанії
    private let popularBreeds = [
        "Yorkshire Terrier", "Labrador Retriever", "German Shepherd",
        "Golden Retriever", "Bulldog", "Poodle", "Beagle",
        "Chihuahua", "Boxer", "Rottweiler", "Mixed / Mestizo"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Illustration
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Text("🐕")
                        .font(.system(size: 56))
                }
                .padding(.top, 24)

                // Title
                VStack(spacing: 8) {
                    Text(String(localized: "onboarding.breed.title"))
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(String(localized: "onboarding.breed.subtitle"))
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Breed input
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "onboarding.breed.label"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextField(String(localized: "onboarding.breed.placeholder"), text: $dogBreed)
                        .font(.system(size: 18, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                .padding(.horizontal, 4)

                // Popular breeds chips
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(localized: "onboarding.breed.popular"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(popularBreeds, id: \.self) { breed in
                            Button(breed) {
                                dogBreed = breed
                                isFocused = false
                            }
                            .font(.system(size: 13))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(dogBreed == breed
                                ? Color.accentColor.opacity(0.15)
                                : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(dogBreed == breed ? Color.accentColor : .primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(dogBreed == breed
                                                  ? Color.accentColor.opacity(0.5)
                                                  : Color.clear, lineWidth: 1)
                            )
                            .animation(.easeInOut(duration: 0.15), value: dogBreed)
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Optional birth date
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "onboarding.breed.birthdate"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    Button {
                        withAnimation { showDatePicker.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(birthDate.map { $0.formatted(date: .long, time: .omitted) }
                                 ?? String(localized: "onboarding.breed.birthdate.optional"))
                                .foregroundStyle(birthDate == nil ? .secondary : .primary)
                            Spacer()
                            if birthDate != nil {
                                Button {
                                    withAnimation { birthDate = nil; showDatePicker = false }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    if showDatePicker {
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDate) { _, new in
                            birthDate = new
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 4)

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Flow layout для chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OnboardingBreedView(dogBreed: .constant("Labrador"), birthDate: .constant(nil))
}
