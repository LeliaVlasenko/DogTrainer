import AppIntents
import SwiftData
import SwiftUI

// MARK: - Start Training Intent

struct StartTrainingIntent: AppIntent {

    static let title: LocalizedStringResource = "intent.start.title"
    static let description = IntentDescription("intent.start.description")

    // Siri говорить це якщо відкриває app
    static let openAppWhenRun: Bool = true

    // Підтримка Siri і Spotlight
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    // Параметр: ім'я собаки (опціональний — якщо є кілька собак у майбутньому)
    @Parameter(title: "intent.param.dog")
    var dogName: String?

    // Shortcut suggestions для Siri
    static var parameterSummary: some ParameterSummary {
        Summary("intent.start.summary \(\.$dogName)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & OpensIntent {
        let container = try await resolveContainer()
        let context = container.mainContext

        let dogs = try context.fetch(FetchDescriptor<Dog>())
        guard let dog = dogs.first else {
            throw IntentError.noDogProfile
        }

        return .result(
            opensIntent: OpenIntent(target: DogTrainerEntity(dogName: dog.name)),
            dialog: IntentDialog(
                full: "intent.start.dialog \(dog.name)",
                supporting: "intent.start.dialog.sub"
            )
        )
    }

    // MARK: - Private

    private func resolveContainer() async throws -> ModelContainer {
        let schema = Schema([Dog.self, Command.self, TrainingSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: config)
    }
}

// MARK: - Show Progress Intent

struct ShowProgressIntent: AppIntent {

    static let title: LocalizedStringResource = "intent.progress.title"
    static let description = IntentDescription("intent.progress.description")

    static let openAppWhenRun: Bool = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    static var parameterSummary: some ParameterSummary {
        Summary("intent.progress.summary")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & OpensIntent {
        let container = try await resolveContainer()
        let context = container.mainContext

        let dogs   = try context.fetch(FetchDescriptor<Dog>())
        let sessions = try context.fetch(
            FetchDescriptor<TrainingSession>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )

        guard let dog = dogs.first else {
            throw IntentError.noDogProfile
        }

        let streak   = dog.currentStreak
        let total    = sessions.count
        let mastered = try context.fetch(FetchDescriptor<Command>())
                            .filter { $0.isMastered }.count

        let dialogText: LocalizedStringResource = streak > 0
            ? "intent.progress.dialog.streak \(dog.name) \(streak) \(total) \(mastered)"
            : "intent.progress.dialog.nostreak \(dog.name) \(total) \(mastered)"

        return .result(
            opensIntent: OpenIntent(target: DogTrainerEntity(dogName: dog.name, openTab: .progress)),
            dialog: IntentDialog(
                full: dialogText,
                supporting: "intent.progress.dialog.sub"
            )
        )
    }

    private func resolveContainer() async throws -> ModelContainer {
        let schema = Schema([Dog.self, Command.self, TrainingSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: config)
    }
}

// MARK: - Intent errors

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case noDogProfile

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noDogProfile:
            return "intent.error.no_dog"
        }
    }
}
