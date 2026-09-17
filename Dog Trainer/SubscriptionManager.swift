import StoreKit
import SwiftUI

// MARK: - Product IDs (мають збігатись з App Store Connect)

enum ProductID {
    static let monthly  = "com.lelia.Dog_Academy.monthly"
    static let yearly   = "com.lelia.Dog_Academy.yearly"

    static var all: [String] { [monthly, yearly] }
}

// MARK: - Subscription status

enum SubscriptionStatus: Equatable {
    case loading
    case notSubscribed         // немає підписки, trial не використаний
    case trial(daysLeft: Int)  // активний trial
    case active                // платна підписка
    case expired               // підписка закінчилась
    case unknown

    var isPremium: Bool {
        switch self {
        case .trial, .active: return true
        default:              return false
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

// MARK: - Purchase result

enum PurchaseResult {
    case success
    case cancelled
    case pending
    case failed(Error)
}

// MARK: - SubscriptionManager

@MainActor
@Observable
final class SubscriptionManager {

    // MARK: Public state

    var status: SubscriptionStatus = .loading
    var products: [Product] = []
    var purchaseError: String? = nil
    var isPurchasing = false
    /// Остання помилка при завантаженні продуктів з App Store.
    /// Показується у debug-панелі коли продукти не приходять у TestFlight.
    var productsFetchError: String? = nil

    /// Developer-bypass: розблоковує всі premium-фічі. Доступно тільки
    /// у DEBUG/DEVELOPER_MODE-білдах (див. DeveloperMode.isAvailable).
    var devUnlockAll: Bool = UserDefaults.standard.bool(forKey: DeveloperMode.unlockAllCommandsKey) {
        didSet {
            UserDefaults.standard.set(devUnlockAll, forKey: DeveloperMode.unlockAllCommandsKey)
        }
    }

    /// Premium-доступ у поточний момент (з урахуванням dev-bypass).
    /// Використовуй цю властивість замість `status.isPremium` у views.
    var isPremium: Bool {
        if DeveloperMode.isAvailable && devUnlockAll { return true }
        return status.isPremium
    }

    // MARK: Private

    private var updateListenerTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    init() {
        // Слухаємо транзакції (renewals, revocations) у фоні
        updateListenerTask = listenForTransactionUpdates()
    }

    // MARK: - Public API

    /// Завантажити продукти і перевірити статус. Викликати при старті app.
    func initialize() async {
        await fetchProducts()
        await refreshStatus()
    }

    /// Купити підписку
    func purchase(_ product: Product) async -> PurchaseResult {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshStatus()
                return .success

            case .userCancelled:
                return .cancelled

            case .pending:
                return .pending

            @unknown default:
                return .cancelled
            }
        } catch {
            purchaseError = error.localizedDescription
            return .failed(error)
        }
    }

    /// Відновити покупки
    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            await refreshStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// Перевірити статус підписки (можна викликати з foreground)
    func refreshStatus() async {
        var foundActive = false
        var trialDaysLeft: Int? = nil

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard transaction.revocationDate == nil else { continue }

            // Перевірити чи не закінчилась
            if let expiry = transaction.expirationDate, expiry < .now {
                continue
            }

            // Introductory offer = trial
            if let offerType = transaction.offerType,
               offerType == .introductory,
               let expiry = transaction.expirationDate {
                // Округлюємо вгору: якщо залишилось 12 годин — показуємо "1 день",
                // а не "0", інакше юзер бачить "trial ends today" передчасно.
                let seconds = expiry.timeIntervalSince(.now)
                let days = Int(ceil(seconds / 86_400))
                trialDaysLeft = max(0, days)
            }

            foundActive = true
        }

        if foundActive {
            if let days = trialDaysLeft {
                status = .trial(daysLeft: days)
            } else {
                status = .active
            }
        } else {
            // Перевірити чи була підписка раніше (expired)
            let hasHistory = await hasSubscriptionHistory()
            status = hasHistory ? .expired : .notSubscribed
        }
    }

    // MARK: - Private helpers

    private func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: ProductID.all)
            // Явний порядок — старий sort() по boolean давав нестабільний
            // результат якщо App Store повертає продукти в будь-якому порядку.
            products = ProductID.all.compactMap { id in
                fetched.first { $0.id == id }
            }
            productsFetchError = nil
        } catch {
            print("⚠️ StoreKit: failed to fetch products: \(error)")
            productsFetchError = String(describing: error)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func hasSubscriptionHistory() async -> Bool {
        for await result in Transaction.all {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard ProductID.all.contains(transaction.productID) else { continue }
            return true
        }
        return false
    }

    /// Слухаємо оновлення транзакцій (renewals, refunds)
    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await transaction.finish()
                    await self?.refreshStatus()
                }
            }
        }
    }
}
