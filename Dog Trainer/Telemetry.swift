import Foundation
import os.log

// MARK: - Telemetry
//
// Мінімальна facade для локальних телеметрії-подій. Все пишеться через
// os_log — можна відкрити Console.app і фільтрувати за subsystem'ом.
// НЕ надсилає нічого на сервер — privacy-first (див. LegalView).
//
// Юзер може відмовитись через `Telemetry.setOptedIn(false)` — тоді
// нічого не логується.

enum TelemetryEvent {
    case onboardingStarted
    case onboardingCompleted(level: String)
    case sessionStarted(commandCount: Int)
    case sessionCompleted(duration: Int, successCount: Int, totalCount: Int)
    case paywallShown(source: String)
    case paywallPurchase(productId: String)
    case paywallDismissed
    case redeemCodeOpened
    case badgeEarned(id: String)
    case commandMastered(id: String)
}

enum Telemetry {

    private static let logger = Logger(
        subsystem: "com.lelia.Dog-Academy",
        category: "telemetry"
    )

    private static let optedInKey = "telemetry.optedIn"

    static var isOptedIn: Bool {
        // За замовч. увімкнено; юзер може вимкнути у Profile → Privacy.
        UserDefaults.standard.object(forKey: optedInKey) as? Bool ?? true
    }

    static func setOptedIn(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: optedInKey)
    }

    static func log(_ event: TelemetryEvent) {
        guard isOptedIn else { return }
        logger.info("\(String(describing: event), privacy: .public)")
    }
}
