//
//  StoreKitManager.swift
//  DevHours
//
//  Handles StoreKit 2 one-time purchase for lifetime premium access.
//

import Foundation
import StoreKit
import Observation

@Observable
final class StoreKitManager {

    // MARK: - Product ID

    static let lifetimeProductID = "com.tobiasfu.DevHours.premium.lifetime"

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading: Bool = false
    private(set) var purchaseError: String?

    // MARK: - Computed Properties

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    var hasLifetimePurchase: Bool {
        purchasedProductIDs.contains(Self.lifetimeProductID)
    }

    var priceString: String {
        lifetimeProduct?.displayPrice ?? "$9.99"
    }

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products and check entitlements on init
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        purchaseError = nil

        do {
            let storeProducts = try await Product.products(for: [Self.lifetimeProductID])
            products = storeProducts
            print("StoreKitManager: Loaded \(products.count) products")
        } catch {
            print("StoreKitManager: Failed to load products - \(error)")
            purchaseError = "Failed to load products. Please try again."
        }

        isLoading = false
    }

    /// Purchase the lifetime product
    func purchaseLifetime() async -> Bool {
        guard let product = lifetimeProduct else {
            purchaseError = "Product not available. Please try again."
            return false
        }

        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                let transaction = try checkVerified(verification)

                // Update entitlements
                purchasedProductIDs.insert(transaction.productID)

                // Finish the transaction
                await transaction.finish()

                print("StoreKitManager: Purchase successful")
                isLoading = false
                return true

            case .userCancelled:
                print("StoreKitManager: User cancelled purchase")
                isLoading = false
                return false

            case .pending:
                print("StoreKitManager: Purchase pending (e.g., parental approval)")
                purchaseError = "Purchase is pending approval."
                isLoading = false
                return false

            @unknown default:
                print("StoreKitManager: Unknown purchase result")
                isLoading = false
                return false
            }
        } catch {
            print("StoreKitManager: Purchase failed - \(error)")
            purchaseError = "Purchase failed. Please try again."
            isLoading = false
            return false
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil

        do {
            try await AppStore.sync()
            await checkEntitlements()
            print("StoreKitManager: Restore completed")
        } catch {
            print("StoreKitManager: Restore failed - \(error)")
            purchaseError = "Failed to restore purchases. Please try again."
        }

        isLoading = false
    }

    /// Check current entitlements
    func checkEntitlements() async {
        var newPurchasedIDs: Set<String> = []

        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is our lifetime product
                if transaction.productID == Self.lifetimeProductID {
                    newPurchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("StoreKitManager: Failed to verify transaction - \(error)")
            }
        }

        purchasedProductIDs = newPurchasedIDs
        print("StoreKitManager: Entitlements updated - has lifetime: \(hasLifetimePurchase)")
    }

    // MARK: - Private Methods

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)

                    // Bind self and transaction to local lets for Sendable safety
                    if let strongSelf = self,
                       let productID = transaction?.productID,
                       productID == StoreKitManager.lifetimeProductID {
                        let revoked = transaction?.revocationDate != nil
                        await MainActor.run {
                            if revoked {
                                strongSelf.purchasedProductIDs.remove(productID)
                            } else {
                                strongSelf.purchasedProductIDs.insert(productID)
                            }
                        }
                    }

                    await transaction?.finish()
                } catch {
                    print("StoreKitManager: Transaction verification failed - \(error)")
                }
            }
        }
    }

    /// Verify a transaction
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
