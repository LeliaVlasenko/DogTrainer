import Foundation
import SwiftUI

// MARK: - Dog selection
//
// Юзер може мати кілька собак — ми зберігаємо ID обраної через UserDefaults
// і резолвимо її з @Query-списку. Якщо selectedID nil або собака видалена —
// falling back до першої з масиву.
//
// Views які використовують "поточну" собаку мають:
//   @AppStorage("selectedDogID") private var selectedID: String = ""
//   private var dog: Dog? { DogSelection.resolve(from: dogs, selectedIDString: selectedID) }
//
// Змінюємо обрану через:
//   DogSelection.select(newDog) — @AppStorage автоматично реагує.

enum DogSelection {

    static let key = "selectedDogID"

    static func select(_ dog: Dog) {
        UserDefaults.standard.set(dog.id.uuidString, forKey: key)
    }

    /// Резолвить обрану собаку зі списку `dogs`.
    /// - Parameter selectedIDString: значення `@AppStorage("selectedDogID")`.
    static func resolve(from dogs: [Dog], selectedIDString: String) -> Dog? {
        if let uuid = UUID(uuidString: selectedIDString),
           let match = dogs.first(where: { $0.id == uuid }) {
            return match
        }
        return dogs.first
    }
}
