//
//  Dog_TrainerApp.swift
//  Dog Trainer
//
//  Created by Lelia Vlasenko on 15/06/2026.
//

import SwiftData
import SwiftUI

// MARK: - App entry point

@main
struct Dog_TrainerApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Dog.self, Command.self, TrainingSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

// MARK: - Preview helper

extension ModelContainer {
    static var preview: ModelContainer {
        let schema = Schema([Dog.self, Command.self, TrainingSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)

        // Seed preview data
        let dog = Dog(name: "Рекс", breed: "Лабрадор", level: .adult)
        container.mainContext.insert(dog)

        for command in Command.seedCommands() {
            container.mainContext.insert(command)
        }

        let session = TrainingSession(durationSeconds: 310, mood: .great, dog: dog)
        session.commandResults = [
            CommandResult(commandId: UUID(), commandTitle: "Sit", succeeded: true),
            CommandResult(commandId: UUID(), commandTitle: "Stay", succeeded: false, attempts: 3)
        ]
        container.mainContext.insert(session)

        return container
    }
}
