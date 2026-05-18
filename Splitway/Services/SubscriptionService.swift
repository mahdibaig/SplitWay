import Foundation
import StoreKit

/// StoreKit 2 wrapper. Surfaces the current `tier` / `isPro`, loads the three
/// products, handles purchase + restore, and listens for transaction updates.
/// Degrades gracefully when no products are configured (dev without a
/// StoreKit config or App Store Connect): the app simply behaves as free,
/// except in DEBUG where a dev toggle can force-unlock everything so all
/// features stay testable.
@MainActor
final class SubscriptionService: ObservableObject {

    @Published private(set) var tier: SubscriptionTier = .free
    @Published private(set) var products: [Product] = []
    @Published private(set) var isWorking = false
    @Published var lastError: String?

    #if DEBUG
    /// Dev-only override so every Pro feature is reachable while testing,
    /// regardless of StoreKit state. Toggled from Settings > Developer.
    @Published var devUnlockPro: Bool = UserDefaults.standard.bool(forKey: "dev.unlockPro") {
        didSet { UserDefaults.standard.set(devUnlockPro, forKey: "dev.unlockPro") }
    }
    #endif

    private var updatesTask: Task<Void, Never>?

    var isPro: Bool {
        #if DEBUG
        if devUnlockPro { return true }
        #endif
        return tier.isPro
    }

    init() {
        // Listen for transactions that arrive outside an explicit purchase
        // (Ask to Buy approvals, renewals, restores on other devices).
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - Products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.all)
            // Stable order: individual, family, lifetime.
            products = loaded.sorted { lhs, rhs in
                order(lhs.id) < order(rhs.id)
            }
        } catch {
            AppLog.lifecycle.error("Product load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func order(_ id: String) -> Int {
        switch id {
        case ProductID.individualYearly:  return 0
        case ProductID.familyYearly:      return 1
        case ProductID.householdLifetime: return 2
        default:                          return 3
        }
    }

    // MARK: - Entitlements

    /// Recomputes `tier` from the user's current entitlements. Lifetime (a
    /// non-consumable) outranks the subscriptions if somehow both exist.
    func refreshEntitlements() async {
        var resolved: SubscriptionTier = .free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate != nil { continue }
            if let exp = transaction.expirationDate, exp < Date() { continue }
            let t = ProductID.tier(for: transaction.productID)
            if t == .lifetime { resolved = .lifetime; break }
            if t != .free { resolved = t }
        }
        tier = resolved
    }

    // MARK: - Purchase / restore

    func purchase(_ product: Product) async {
        isWorking = true
        lastError = nil
        defer { isWorking = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                } else {
                    lastError = "Couldn't verify that purchase."
                }
            case .userCancelled:
                break
            case .pending:
                lastError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            AppLog.lifecycle.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        isWorking = true
        lastError = nil
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !tier.isPro {
                lastError = "No previous purchases found for this Apple ID."
            }
        } catch {
            AppLog.lifecycle.error("Restore failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    // MARK: - Gating

    /// The single check ViewModels call. Free features should never call this;
    /// only Pro-gated capabilities pass a flag.
    func canUse(_ flag: FeatureFlag) -> Bool {
        isPro
    }
}
