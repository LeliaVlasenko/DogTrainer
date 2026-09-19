import SwiftUI

// MARK: - Watch entry point
//
// Мінімальний watchOS-компаньйон. Показує стан обраної собаки з
// iPhone і дозволяє логувати тренування одним тапом.
//
// Дані живуть на iPhone (через SwiftData) — Watch отримує їх через
// WatchConnectivity live-request. Якщо iPhone поза досяжністю,
// показуємо fallback UI.

@main
struct DogAcademyWatchApp: App {
    @State private var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(connectivity)
                .task { await connectivity.requestSnapshot() }
        }
    }
}
