import Foundation

// MARK: - DeveloperMode
//
// Інструменти для тестування. Доступні **тільки** у DEBUG-білдах
// (запуск з Xcode) АБО якщо доданий custom прапор `DEVELOPER_MODE`
// (наприклад, для TestFlight-білдів — додай у Build Settings →
// "Other Swift Flags" → -D DEVELOPER_MODE).
//
// У production App Store-білдах (без обох прапорів) `isAvailable == false` —
// UI не показується і `unlockAllCommands` ігнорується. Жоден код не виконується.

enum DeveloperMode {

    /// Чи доступний девелопер-режим у поточному build configuration.
    static var isAvailable: Bool {
        #if DEBUG || DEVELOPER_MODE
        return true
        #else
        return false
        #endif
    }

    /// Ключ для UserDefaults-стораджу
    static let unlockAllCommandsKey = "dev.unlockAllCommands"
}
