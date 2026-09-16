import AppIntents
import SwiftUI

// MARK: - App tab enum

enum AppTab: String {
    case home     = "home"
    case progress = "progress"
    case library  = "library"
}

// MARK: - DogTrainerEntity
// AppEntity дозволяє Siri/Shortcuts передавати структуровані дані в app

struct DogTrainerEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Pupcademy"

    static var defaultQuery = DogTrainerEntityQuery()

    var id: String
    var dogName: String
    var openTab: AppTab

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(dogName)")
    }

    init(dogName: String, openTab: AppTab = .home) {
        self.id = "\(dogName)-\(openTab.rawValue)"
        self.dogName = dogName
        self.openTab = openTab
    }
}

// MARK: - Entity Query (required by AppEntity)

struct DogTrainerEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [DogTrainerEntity] {
        []   // Не потрібен для наших інтентів
    }

    func suggestedEntities() async throws -> [DogTrainerEntity] {
        []
    }
}

// MARK: - OpenIntent — deep link в конкретну вкладку

struct OpenIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.open.title"
    static let openAppWhenRun: Bool = true

    @Parameter(title: "intent.param.target")
    var target: DogTrainerEntity

    init() { self.target = DogTrainerEntity(dogName: "") }
    init(target: DogTrainerEntity) { self.target = target }

    func perform() async throws -> some IntentResult {
        // Deep link надсилається через NotificationCenter
        // ContentView його ловить і перемикає таб
        await MainActor.run {
            NotificationCenter.default.post(
                name: .openAppTab,
                object: nil,
                userInfo: ["tab": target.openTab.rawValue]
            )
        }
        return .result()
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let openAppTab = Notification.Name("Pupcademy.openAppTab")
}
