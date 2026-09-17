import SwiftUI
import SwiftData

// MARK: - Dog picker menu
//
// Компактний dropdown у HomeView-хедері для перемикання між собаками.
// Не показується коли у юзера лише одна собака (мінімалістично).

struct DogPicker: View {
    let dogs: [Dog]
    let selected: Dog?
    let onAdd: () -> Void

    var body: some View {
        Menu {
            Section {
                ForEach(dogs) { dog in
                    Button {
                        DogSelection.select(dog)
                    } label: {
                        HStack {
                            Text(dog.name)
                            if dog.id == selected?.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Button(action: onAdd) {
                Label(String(localized: "profile.dog.add.title"), systemImage: "plus")
            }
        } label: {
            HStack(spacing: 6) {
                Text(selected?.name ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.appCardBackground)
            .clipShape(Capsule())
        }
    }
}
