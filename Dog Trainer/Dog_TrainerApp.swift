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
    @State private var subscriptionManager = SubscriptionManager()
    @State private var notificationManager = NotificationManager()
    @State private var achievementManager = AchievementManager()

    init() {
        let schema = Schema([Dog.self, Command.self, TrainingSession.self, EarnedBadge.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Не вдалося відкрити існуючий store зі старою схемою (без EarnedBadge).
            // Видаляємо старі файли і пробуємо ще раз — користувач втратить локальні
            // дані одноразово, зате застосунок запуститься.
            print("⚠️ ModelContainer init failed: \(error). Resetting store…")
            Self.deleteSwiftDataStore()
            do {
                container = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("ModelContainer failed after reset: \(error)")
            }
        }
    }

    /// Видаляє SwiftData store з Application Support (для self-healing міграції).
    private static func deleteSwiftDataStore() {
        let fm = FileManager.default
        guard let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }

        // SwiftData створює default.store + WAL/SHM-файли
        let names = ["default.store", "default.store-wal", "default.store-shm"]
        for name in names {
            try? fm.removeItem(at: appSupport.appendingPathComponent(name))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptionManager)
                .environment(notificationManager)
                .environment(achievementManager)
                .badgeToastOverlay(achievementManager)
                .task {
                    await subscriptionManager.initialize()
                    await notificationManager.refreshPermission()
                    // Міграція команд: додаємо нові з v2+ для існуючих юзерів
                    Command.topUpSeedIfNeeded(in: container.mainContext)
                    let dogs = (try? container.mainContext.fetch(FetchDescriptor<Dog>())) ?? []
                    await notificationManager.rescheduleAll(dog: dogs.first)
                }
        }
        .modelContainer(container)
    }
}

// MARK: - Preview helper

extension ModelContainer {
    static var preview: ModelContainer {
        let schema = Schema([Dog.self, Command.self, TrainingSession.self, EarnedBadge.self])
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

        // Preview earned badges
        container.mainContext.insert(EarnedBadge(badgeId: "sessions_1"))
        container.mainContext.insert(EarnedBadge(badgeId: "perfect_session"))

        return container
    }
}
