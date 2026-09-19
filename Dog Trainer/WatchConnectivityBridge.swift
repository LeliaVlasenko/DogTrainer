import Foundation
import Observation
import SwiftData
import WatchConnectivity

// MARK: - Message keys
//
// Синхронізовано з `WatchConnectivityManager` у watchOS-таргеті.
// Якщо міняєш — оновлюй обидва місця.

enum WatchMessageKey {
    static let action        = "action"
    static let dogName       = "dogName"
    static let dogBreed      = "dogBreed"
    static let streak        = "streak"
    static let trainedToday  = "trainedToday"
}

enum WatchAction: String {
    case requestSnapshot
    case logTraining
    case snapshotResponse
}

// MARK: - Bridge (iPhone side)
//
// Слухає повідомлення від Watch і відповідає snapshot'ом.
// Також може штовхати оновлення (push) коли phone-app зберігає сесію.

@MainActor
@Observable
final class WatchConnectivityBridge: NSObject {

    static let shared = WatchConnectivityBridge()

    /// Container вставляється з `Dog_TrainerApp` після ініціалізації.
    var modelContainer: ModelContainer?

    private let session: WCSession?

    override init() {
        self.session = WCSession.isSupported() ? WCSession.default : nil
        super.init()
        session?.delegate = self
        session?.activate()
    }

    /// Штовхнути свіжий snapshot на Watch (наприклад після збереження сесії).
    func pushSnapshot() {
        guard let session, session.isReachable else { return }
        Task { @MainActor in
            guard let payload = buildSnapshotPayload() else { return }
            var msg = payload
            msg[WatchMessageKey.action] = WatchAction.snapshotResponse.rawValue
            session.sendMessage(msg, replyHandler: nil)
        }
    }

    // MARK: Handling

    /// Обробити incoming message. Викликається з sessionDelegate,
    /// повертає reply-payload синхронно через continuation.
    fileprivate func handle(_ message: [String: Any]) async -> [String: Any] {
        guard let raw = message[WatchMessageKey.action] as? String,
              let action = WatchAction(rawValue: raw)
        else { return [:] }

        switch action {
        case .requestSnapshot:
            return buildSnapshotPayload() ?? [:]
        case .logTraining:
            await logQuickTraining()
            return buildSnapshotPayload() ?? [:]
        case .snapshotResponse:
            return [:]
        }
    }

    // MARK: Data access

    private func buildSnapshotPayload() -> [String: Any]? {
        guard let context = modelContainer?.mainContext else { return nil }
        let dogs = (try? context.fetch(FetchDescriptor<Dog>())) ?? []
        let selectedID = UserDefaults.standard.string(forKey: DogSelection.key) ?? ""
        guard let dog = DogSelection.resolve(from: dogs, selectedIDString: selectedID) else {
            return nil
        }
        return [
            WatchMessageKey.dogName: dog.name,
            WatchMessageKey.dogBreed: dog.breed,
            WatchMessageKey.streak: dog.currentStreak,
            WatchMessageKey.trainedToday: dog.trainedToday
        ]
    }

    /// Логіка "quick log" — таки сама, що і в `QuickLogIntent`.
    /// Створює 60-секундну сесію з найчастіше вживаною unlocked-командою.
    private func logQuickTraining() async {
        guard let context = modelContainer?.mainContext else { return }

        let dogs = (try? context.fetch(FetchDescriptor<Dog>())) ?? []
        let selectedID = UserDefaults.standard.string(forKey: DogSelection.key) ?? ""
        guard let dog = DogSelection.resolve(from: dogs, selectedIDString: selectedID) else { return }

        let allCommands = (try? context.fetch(FetchDescriptor<Command>())) ?? []
        let unlocked = allCommands.filter { $0.isUnlocked }
        let picked = unlocked.max(by: { $0.successCount < $1.successCount }) ?? unlocked.first
        guard let command = picked else { return }

        let session = TrainingSession(
            date: .now,
            durationSeconds: 60,
            mood: .good,
            dog: dog
        )
        session.commandResults = [
            CommandResult(
                commandId: command.id,
                commandTitle: command.title,
                succeeded: true,
                attempts: 1
            )
        ]
        command.successCount += 1
        context.insert(session)
        try? context.save()

        Telemetry.log(.sessionCompleted(
            duration: 60,
            successCount: 1,
            totalCount: 1
        ))
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityBridge: WCSessionDelegate {

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        // no-op
    }

    // На iPhone-стороні є ще два обов'язкових методи delegate'у.
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Реактивуємо якщо Watch знову з'явиться в парі.
        session.activate()
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            let reply = await handle(message)
            replyHandler(reply)
        }
    }
}
