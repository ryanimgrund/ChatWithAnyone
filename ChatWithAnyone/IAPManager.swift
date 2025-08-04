import Foundation
import StoreKit

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    // Your product ID from App Store Connect
    private let productID = "0003"

    @Published var isUnlocked: Bool = false
    @Published var purchaseInProgress: Bool = false
    @Published var errorMessage: String?
    @Published var product: Product?

    private var updateListenerTask: Task<Void, Never>? = nil

    private init() {
        // Automatically check unlock status and load product on init
        Task {
            await fetch()
            await checkIfUnlocked()
        }
        // Listen for transaction updates (restores, purchases, etc.)
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Fetch product info

    func fetch() async {
        do {
            let storeProducts = try await Product.products(for: [productID])
            self.product = storeProducts.first
        } catch {
            self.errorMessage = "Unable to fetch products: \(error.localizedDescription)"
        }
    }

    // MARK: - Buy

    func buy() async {
        guard let product = product else {
            errorMessage = "Product not available yet. Please try again later."
            return
        }
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    isUnlocked = true
                case .unverified:
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                // User cancelled purchase, no error
                break
            case .pending:
                errorMessage = "Purchase is pending. Please check again later."
            @unknown default:
                errorMessage = "Unknown error occurred."
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    func restore() async {
        do {
            // Triggers StoreKit to restore purchases
            try await AppStore.sync()
            // Always check if unlocked after restore
            await checkIfUnlocked()
            // No error if nothing restored (StoreKit 2 is silent on "nothing to restore")
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Check unlock

    func checkIfUnlocked() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == productID && transaction.revocationDate == nil {
                    isUnlocked = true
                    return
                }
            default:
                continue
            }
        }
        isUnlocked = false
    }


    // MARK: - Listen for updates

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await _ in Transaction.updates {
                await self.checkIfUnlocked()
            }
        }
    }
}

