import Foundation
import Observation
import WatchConnectivity

// MARK: - Message keys (shared with iPhone side)
//
// Тримаємо ключі стандартизованими — обидві сторони перевіряють ті самі.
// Якщо будеш міняти — синхронізуй з `WatchConnectivityBridge` в iPhone-app.

enum WatchMessageKey {
    static let action        = "action"
    static let dogName       = "dogName"
    static let dogBreed      = "dogBreed"
    static let streak        = "streak"
    static let trainedToday  = "trainedToday"
}

enum WatchAction: String {
    case requestSnapshot   // Watch → iPhone: give me current state
    case logTraining       // Watch → iPhone: log a quick training
    case snapshotResponse  // iPhone → Watch: here's the state
}

// MARK: - Snapshot

struct DogSnapshot: Equatable {
    let dogName: String
    let dogBreed: String
    let streak: Int
    let trainedToday: Bool

    init?(from message: [String: Any]) {
        guard
            let name  = message[WatchMessageKey.dogName]  as? String,
            let breed = message[WatchMessageKey.dogBreed] as? String,
            let strk  = message[WatchMessageKey.streak]   as? Int,
            let today = message[WatchMessageKey.trainedToday] as? Bool
        else { return nil }
        self.dogName = name
        self.dogBreed = breed
        self.streak = strk
        self.trainedToday = today
    }
}

// MARK: - Manager

@MainActor
@Observable
final class WatchConnectivityManager: NSObject {

    static let shared = WatchConnectivityManager()

    var snapshot: DogSnapshot? = nil
    var isLogging = false
    var lastError: String? = nil

    private let session: WCSession?

    override init() {
        self.session = WCSession.isSupported() ? WCSession.default : nil
        super.init()
        session?.delegate = self
        session?.activate()
    }

    // MARK: Public API

    func requestSnapshot() async {
        await send(action: .requestSnapshot)
    }

    func logTraining() async {
        isLogging = true
        defer { isLogging = false }
        await send(action: .logTraining)
    }

    // MARK: Private

    private func send(action: WatchAction) async {
        guard let session, session.isReachable else {
            lastError = "iPhone unreachable"
            return
        }
        let message: [String: Any] = [WatchMessageKey.action: action.rawValue]
        await withCheckedContinuation { continuation in
            session.sendMessage(message, replyHandler: { [weak self] reply in
                Task { @MainActor in
                    if let snap = DogSnapshot(from: reply) {
                        self?.snapshot = snap
                    }
                    continuation.resume()
                }
            }, errorHandler: { [weak self] error in
                Task { @MainActor in
                    self?.lastError = error.localizedDescription
                    continuation.resume()
                }
            })
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        // no-op — після активації UI викличе requestSnapshot()
    }

    // iPhone штовхає update без запиту (напр. після завершення сесії у phone-app)
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let raw = message[WatchMessageKey.action] as? String,
              WatchAction(rawValue: raw) == .snapshotResponse,
              let snap = DogSnapshot(from: message)
        else { return }
        Task { @MainActor in
            self.snapshot = snap
        }
    }
}
