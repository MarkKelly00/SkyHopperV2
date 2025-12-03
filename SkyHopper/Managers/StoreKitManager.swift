import Foundation
import StoreKit

/// StoreKitManager handles all In-App Purchase operations using StoreKit 2
/// This manager supports consumable products (coin packs) for the SkyHopper game
@MainActor
class StoreKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StoreKitManager()
    
    // MARK: - Product Identifiers
    /// These IDs must match exactly what you configure in App Store Connect
    /// Format: com.yourcompany.skyhopper.{product_name}
    enum ProductID: String, CaseIterable {
        case coinsSmall = "com.skyhopper.coins.small"      // 500 coins - $0.99
        case coinsMedium = "com.skyhopper.coins.medium"    // 1500 coins - $2.99
        case coinsLarge = "com.skyhopper.coins.large"      // 5000 coins - $9.99
        case coinsMega = "com.skyhopper.coins.mega"        // 12000 coins - $19.99
        case removeAds = "com.skyhopper.removeads"         // Non-consumable
        
        /// Amount of coins awarded for each package
        var coinAmount: Int {
            switch self {
            case .coinsSmall: return 500
            case .coinsMedium: return 1500
            case .coinsLarge: return 5000
            case .coinsMega: return 12000
            case .removeAds: return 0
            }
        }
        
        /// Display name for UI
        var displayName: String {
            switch self {
            case .coinsSmall: return "Small Pack"
            case .coinsMedium: return "Medium Pack"
            case .coinsLarge: return "Large Pack"
            case .coinsMega: return "Mega Pack"
            case .removeAds: return "Remove Ads"
            }
        }
    }
    
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private let currencyManager = CurrencyManager.shared
    
    // MARK: - Delegate
    weak var delegate: StoreKitManagerDelegate?
    
    // MARK: - Initialization
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products on init
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Loads all available products from the App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: Set(productIDs))
            
            // Sort products by price for consistent display
            products = storeProducts.sorted { $0.price < $1.price }
            
            print("✅ StoreKit: Loaded \(products.count) products")
            for product in products {
                print("  - \(product.id): \(product.displayName) - \(product.displayPrice)")
            }
            
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ StoreKit Error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Handling
    
    /// Initiates a purchase for the given product
    /// - Parameter product: The StoreKit Product to purchase
    /// - Returns: True if purchase was successful
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                let transaction = try checkVerified(verification)
                
                // Deliver the product content
                await deliverProduct(for: transaction)
                
                // Finish the transaction
                await transaction.finish()
                
                print("✅ Purchase successful: \(product.id)")
                isLoading = false
                delegate?.purchaseDidComplete(productID: product.id, success: true)
                return true
                
            case .userCancelled:
                print("⚠️ User cancelled purchase")
                isLoading = false
                return false
                
            case .pending:
                print("⏳ Purchase pending (Ask to Buy)")
                errorMessage = "Purchase is pending approval"
                isLoading = false
                return false
                
            @unknown default:
                print("❓ Unknown purchase result")
                isLoading = false
                return false
            }
            
        } catch StoreKitError.userCancelled {
            print("⚠️ User cancelled purchase")
            isLoading = false
            return false
            
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("❌ Purchase error: \(error)")
            isLoading = false
            delegate?.purchaseDidComplete(productID: product.id, success: false)
            return false
        }
    }
    
    /// Convenience method to purchase by product ID
    func purchase(productID: ProductID) async -> Bool {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            errorMessage = "Product not found"
            return false
        }
        return await purchase(product)
    }
    
    // MARK: - Restore Purchases
    
    /// Restores previously purchased non-consumable products
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ Purchases restored successfully")
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("❌ Restore error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Transaction Verification
    
    /// Verifies that a transaction is authentic
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Product Delivery
    
    /// Delivers the purchased content to the user
    private func deliverProduct(for transaction: Transaction) async {
        guard let productID = ProductID(rawValue: transaction.productID) else {
            print("⚠️ Unknown product ID: \(transaction.productID)")
            return
        }
        
        switch productID {
        case .coinsSmall, .coinsMedium, .coinsLarge, .coinsMega:
            // Add coins to the user's balance
            let coinsToAdd = productID.coinAmount
            _ = currencyManager.addCoins(coinsToAdd)
            print("💰 Added \(coinsToAdd) coins to user balance")
            
        case .removeAds:
            // Mark ads as removed (non-consumable)
            UserDefaults.standard.set(true, forKey: "adsRemoved")
            purchasedProductIDs.insert(transaction.productID)
            print("🚫 Ads removed")
        }
        
        // Notify delegate of successful delivery
        delegate?.purchaseDidDeliver(productID: transaction.productID, coins: productID.coinAmount)
    }
    
    // MARK: - Transaction Listener
    
    /// Listens for transaction updates (handles pending transactions, renewals, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    if let transaction = transaction {
                        await self?.deliverProduct(for: transaction)
                        await transaction.finish()
                    }
                } catch {
                    print("❌ Transaction listener error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Purchase Status
    
    /// Updates the set of purchased non-consumable products
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                // Only track non-consumable purchases
                if transaction.productType == .nonConsumable {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("❌ Failed to verify entitlement: \(error)")
            }
        }
        
        purchasedProductIDs = purchased
        
        // Update UserDefaults for Remove Ads
        if purchased.contains(ProductID.removeAds.rawValue) {
            UserDefaults.standard.set(true, forKey: "adsRemoved")
        }
    }
    
    /// Checks if a specific product has been purchased (for non-consumables)
    func isPurchased(_ productID: ProductID) -> Bool {
        return purchasedProductIDs.contains(productID.rawValue)
    }
    
    /// Checks if ads have been removed
    var hasRemovedAds: Bool {
        return isPurchased(.removeAds) || UserDefaults.standard.bool(forKey: "adsRemoved")
    }
    
    // MARK: - Helper Methods
    
    /// Gets the Product object for a given ProductID
    func getProduct(for productID: ProductID) -> Product? {
        return products.first { $0.id == productID.rawValue }
    }
    
    /// Gets the formatted price string for a product
    func priceString(for productID: ProductID) -> String {
        guard let product = getProduct(for: productID) else {
            return "N/A"
        }
        return product.displayPrice
    }
    
    /// Returns all coin pack products sorted by price
    var coinPackProducts: [Product] {
        let coinPackIDs = [
            ProductID.coinsSmall.rawValue,
            ProductID.coinsMedium.rawValue,
            ProductID.coinsLarge.rawValue,
            ProductID.coinsMega.rawValue
        ]
        return products
            .filter { coinPackIDs.contains($0.id) }
            .sorted { $0.price < $1.price }
    }
}

// MARK: - Delegate Protocol

protocol StoreKitManagerDelegate: AnyObject {
    /// Called when a purchase completes (success or failure)
    func purchaseDidComplete(productID: String, success: Bool)
    
    /// Called when product content has been delivered
    func purchaseDidDeliver(productID: String, coins: Int)
}

// MARK: - Convenience Accessors

extension StoreKitManager {
    /// Check if products are loaded (must be called from MainActor context)
    var hasProducts: Bool {
        return !products.isEmpty
    }
    
    /// Check if store is ready for purchases
    var isStoreReady: Bool {
        return !products.isEmpty && !isLoading
    }
}

