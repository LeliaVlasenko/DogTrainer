import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: String = ProductID.monthly
    @State private var purchaseResult: PurchaseResult? = nil
    @State private var showSuccess = false
    @State private var isLoadingProducts = false
    // Право саме цього юзера на trial (перевіряється через StoreKit,
    // враховує чи він вже використовував introductory offer раніше).
    @State private var trialEligible: Bool = false
    @State private var presentedLegal: LegalDocument? = nil

    private var canPurchase: Bool {
        !subscriptionManager.isPurchasing && selectedProduct != nil
    }

    private var selectedProduct: Product? {
        subscriptionManager.products.first { $0.id == selectedProductID }
    }

    private var monthlyProduct: Product? {
        subscriptionManager.products.first { $0.id == ProductID.monthly }
    }

    private var yearlyProduct: Product? {
        subscriptionManager.products.first { $0.id == ProductID.yearly }
    }

    // Розраховуємо економію для yearly
    private var yearlySaving: String? {
        guard let m = monthlyProduct, let y = yearlyProduct else { return nil }
        let monthlyAnnual = m.price * 12
        let saving = monthlyAnnual - y.price
        guard saving > 0 else { return nil }
        let formatter = y.priceFormatStyle
        return saving.formatted(formatter)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero
                    PaywallHeroView()

                    // Features list
                    PaywallFeaturesView()

                    // Product picker / Loading / Empty
                    if !subscriptionManager.products.isEmpty {
                        ProductPickerView(
                            monthly: monthlyProduct,
                            yearly: yearlyProduct,
                            selectedID: $selectedProductID,
                            yearlySaving: yearlySaving
                        )
                    } else if isLoadingProducts {
                        HStack(spacing: 10) {
                            SwiftUI.ProgressView()
                            Text(String(localized: "paywall.products.loading"))
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.appFlame)
                            Text(String(localized: "paywall.products.unavailable"))
                                .font(.system(size: 14, weight: .medium))
                                .multilineTextAlignment(.center)
                            Text(String(localized: "paywall.products.retry.hint"))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await loadProducts() }
                            } label: {
                                Label(String(localized: "paywall.products.retry"),
                                      systemImage: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.top, 4)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Error
                    if let error = subscriptionManager.purchaseError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appCoral)
                            .multilineTextAlignment(.center)
                    }

                    // CTA
                    VStack(spacing: 12) {
                        Button {
                            Task { await startPurchase() }
                        } label: {
                            Group {
                                if subscriptionManager.isPurchasing {
                                    SwiftUI.ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(ctaTitle)
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canPurchase ? Color.accentColor : Color.secondary.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!canPurchase)
                        .animation(.easeInOut(duration: 0.2), value: canPurchase)

                        // Trial label — показуємо тільки якщо юзер реально має право
                        if trialEligible {
                            TrialBadgeView()
                        }

                        // Restore + legal
                        HStack(spacing: 16) {
                            Button(String(localized: "paywall.restore")) {
                                Task { await subscriptionManager.restore() }
                            }
                            Text("·")
                            Button(String(localized: "paywall.privacy")) {
                                presentedLegal = .privacy
                            }
                            Text("·")
                            Button(String(localized: "paywall.terms")) {
                                presentedLegal = .terms
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .overlay {
            if showSuccess {
                PurchaseSuccessOverlay { dismiss() }
            }
        }
        .sheet(item: $presentedLegal) { doc in
            LegalView(document: doc)
        }
        .task {
            // Прибираємо стару помилку при кожному відкритті paywall.
            subscriptionManager.purchaseError = nil
            // Завантажити продукти якщо ще не завантажені
            if subscriptionManager.products.isEmpty {
                await loadProducts()
            }
            await refreshTrialEligibility()
        }
        .onChange(of: selectedProductID) { _, _ in
            Task { await refreshTrialEligibility() }
        }
    }

    private func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        await subscriptionManager.initialize()
    }

    /// Перевіряємо чи має юзер право на free trial для обраного продукту.
    /// StoreKit сам врахує історію transactions (chi trial вже було спожито).
    private func refreshTrialEligibility() async {
        guard let sub = selectedProduct?.subscription,
              sub.introductoryOffer != nil else {
            trialEligible = false
            return
        }
        trialEligible = await sub.isEligibleForIntroOffer
    }

    // MARK: - Helpers

    private var ctaTitle: String {
        // Показуємо "Спробувати безкоштовно" тільки якщо юзер реально має право
        // на intro offer (StoreKit пам'ятає попередні trials).
        if trialEligible {
            return String(localized: "paywall.cta.trial")
        }
        return String(localized: "paywall.cta.subscribe")
    }

    private func startPurchase() async {
        guard let product = selectedProduct else { return }
        let result = await subscriptionManager.purchase(product)
        switch result {
        case .success:
            withAnimation { showSuccess = true }
        case .cancelled, .pending, .failed:
            break
        }
    }
}

// MARK: - Hero

private struct PaywallHeroView: View {
    var body: some View {
        VStack(spacing: 10) {
            BrandIcon(.paw, size: 88)
            Text(String(localized: "paywall.title"))
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            Text(String(localized: "paywall.subtitle"))
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}

// MARK: - Features

private struct PaywallFeaturesView: View {
    private let features: [(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey)] = [
        ("infinity",             "paywall.feature.commands.title",  "paywall.feature.commands.sub"),
        ("chart.line.uptrend.xyaxis", "paywall.feature.progress.title", "paywall.feature.progress.sub"),
        ("wand.and.stars",       "paywall.feature.ai.title",        "paywall.feature.ai.sub"),
        ("applewatch",           "paywall.feature.watch.title",     "paywall.feature.watch.sub")
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.icon) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 14, weight: .medium))
                        Text(feature.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.appSage)
                }
                .padding(14)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Product picker

private struct ProductPickerView: View {
    let monthly: Product?
    let yearly: Product?
    @Binding var selectedID: String
    let yearlySaving: String?

    var body: some View {
        VStack(spacing: 10) {
            if let monthly {
                ProductCard(
                    product: monthly,
                    isSelected: selectedID == monthly.id,
                    badge: nil,
                    priceDetail: String(localized: "paywall.billing.monthly")
                ) { selectedID = monthly.id }
            }
            if let yearly {
                ProductCard(
                    product: yearly,
                    isSelected: selectedID == yearly.id,
                    badge: yearlySaving.map { String(localized: "paywall.save \($0)") },
                    priceDetail: String(localized: "paywall.billing.yearly")
                ) { selectedID = yearly.id }
            }
        }
    }
}

private struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let priceDetail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Radio
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                                      lineWidth: isSelected ? 2 : 1)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.system(size: 15, weight: .medium))
                    Text(priceDetail)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 17, weight: .bold))
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appSage)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trial badge

private struct TrialBadgeView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gift")
                .font(.system(size: 13))
            Text(String(localized: "paywall.trial.badge"))
                .font(.system(size: 13))
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Success overlay

private struct PurchaseSuccessOverlay: View {
    let onDone: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                BrandIcon(.confetti, size: 80)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)
                Text(String(localized: "paywall.success.title"))
                    .font(.system(size: 22, weight: .bold))
                Text(String(localized: "paywall.success.subtitle"))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(String(localized: "paywall.success.cta"), action: onDone)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(28)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(32)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
