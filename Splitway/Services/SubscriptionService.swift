import Foundation
import StoreKit

/// StoreKit 2 wrapper. Surfaces the current `tier` / `isPro`, loads the
/// subscription products, handles purchase + restore, and listens for
/// transaction updates.
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

    // Shared household entitlement: a plan one member bought, stamped on the
    // shared household record, plus the household's participant count. These let
    // a member inherit Pro from a housemate's plan while the household is within
    // that plan's seat cap. Pushed in by the composition root via
    // `updateHouseholdEntitlement`.
    @Published private(set) var householdPlanTier: SubscriptionTier = .free
    @Published private(set) var householdPlanExpiresAt: Date?
    @Published private(set) var householdParticipantCount: Int = 1

    /// Set by the composition root. Stamps this device's active plan onto the
    /// shared household record so housemates within the seat cap inherit Pro.
    var stampHouseholdEntitlement: ((SubscriptionTier, Date?) async -> Void)?

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
        if tier.isPro { return true }   // bought it on this device
        return householdSharedPro       // covered by a housemate's plan
    }

    /// The household's active shared plan as seen by this device (`.free` if
    /// none is stamped or it has lapsed).
    private var householdActivePlanTier: SubscriptionTier {
        guard householdPlanTier.isPro else { return .free }
        if let expiresAt = householdPlanExpiresAt, expiresAt < Date() { return .free }
        return householdPlanTier
    }

    /// True when an active household plan covers the current participant count.
    private var householdSharedPro: Bool {
        householdActivePlanTier.isPro
            && householdActivePlanTier.proSeatCap >= householdParticipantCount
    }

    /// The tier that governs household size, taking the better of this device's
    /// own plan and any plan a housemate has published.
    var effectivePlanTier: SubscriptionTier {
        tier.rank >= householdActivePlanTier.rank ? tier : householdActivePlanTier
    }

    /// Max people allowed in the household for the current plan. Free,
    /// Individual, and Duo top out at 2; Household allows 6.
    var participationCap: Int {
        effectivePlanTier == .household ? 6 : 2
    }

    /// Pushed in by the composition root whenever the household or its synced
    /// plan / participant count changes, so `isPro` reflects shared plans.
    func updateHouseholdEntitlement(tier: SubscriptionTier, expiresAt: Date?, participantCount: Int) {
        householdPlanTier = tier
        householdPlanExpiresAt = expiresAt
        householdParticipantCount = max(1, participantCount)
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
            // Stable display order (see order(_:)): Individual, Duo, Household,
            // monthly before yearly.
            products = loaded.sorted { lhs, rhs in
                order(lhs.id) < order(rhs.id)
            }
        } catch {
            AppLog.lifecycle.error("Product load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func order(_ id: String) -> Int {
        switch id {
        case ProductID.individualMonthly: return 0
        case ProductID.individualYearly:  return 1
        case ProductID.duoMonthly:        return 2
        case ProductID.duoYearly:         return 3
        case ProductID.householdMonthly:  return 4
        case ProductID.householdYearly:   return 5
        default:                          return 6
        }
    }

    /// The Individual monthly product, used by the onboarding trial page.
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.individualMonthly }
    }

    // MARK: - Entitlements

    /// Recomputes `tier` from the user's current entitlements, keeping the
    /// highest-ranked one if more than one is somehow active.
    func refreshEntitlements() async {
        var resolved: SubscriptionTier = .free
        var resolvedExpiry: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate != nil { continue }
            if let exp = transaction.expirationDate, exp < Date() { continue }
            let t = ProductID.tier(for: transaction.productID)
            if t.rank > resolved.rank {
                resolved = t
                resolvedExpiry = transaction.expirationDate
            }
        }
        tier = resolved
        // Publish this device's own plan onto the shared household record so
        // housemates within the seat cap inherit Pro.
        if resolved.isPro {
            await stampHouseholdEntitlement?(resolved, resolvedExpiry)
        }
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
