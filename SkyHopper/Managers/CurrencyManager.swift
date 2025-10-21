import Foundation
import SpriteKit

class CurrencyManager {
    static let shared = CurrencyManager()
    
    // Currency types
    private var coins: Int = 0
    private var gems: Int = 0
    
    // Keys for UserDefaults
    private let coinsKey = "playerCoins"
    private let gemsKey = "playerGems"
    
    // Delegate to notify changes
    weak var delegate: CurrencyManagerDelegate?
    
    private init() {
        loadSavedData()
    }
    
    // MARK: - Currency Management
    
    func getCoins() -> Int {
        return coins
    }
    
    func getGems() -> Int {
        return gems
    }
    
    func addCoins(_ amount: Int) -> Int {
        coins += amount
        saveData()
        delegate?.currencyDidChange()
        
        // Track coins earned for achievements
        AchievementManager.shared.trackCoinsEarned(amount)
        
        return coins
    }
    
    func addGems(_ amount: Int) -> Int {
        gems += amount
        saveData()
        delegate?.currencyDidChange()
        return gems
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        
        coins -= amount
        saveData()
        delegate?.currencyDidChange()
        return true
    }
    
    func spendGems(_ amount: Int) -> Bool {
        guard gems >= amount else { return false }
        
        gems -= amount
        saveData()
        delegate?.currencyDidChange()
        return true
    }
    
    // For development/testing purposes
    func resetCurrency() {
        coins = 0
        gems = 0
        saveData()
        delegate?.currencyDidChange()
    }
    
    // MARK: - Persistence
    
    private func loadSavedData() {
        let defaults = UserDefaults.standard
        coins = defaults.integer(forKey: coinsKey)
        gems = defaults.integer(forKey: gemsKey)
    }
    
    private func saveData() {
        // Ensure thread-safe access to UserDefaults
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let defaults = UserDefaults.standard
            defaults.set(self.coins, forKey: self.coinsKey)
            defaults.set(self.gems, forKey: self.gemsKey)
            print("DEBUG: CurrencyManager saved - Coins: \(self.coins), Gems: \(self.gems)")
        }
    }
    
    // MARK: - Game Integration
    
    func awardCoinsForScore(_ score: Int) -> Int {
        // More challenging formula: 1 coin for every 25 points
        // This creates a slower progression that encourages IAP
        let earnedCoins = score / 25
        
        // Ensure minimum reward of 1 coin for completing a level
        let finalCoins = max(earnedCoins, 1)
        return addCoins(finalCoins)
    }
    
    func getCoinMultiplier(for mapTheme: MapManager.MapTheme) -> Double {
        // More conservative multipliers to slow progression
        // Higher difficulty maps give slightly better rewards to encourage progression
        switch mapTheme {
        case .city:
            return 0.8  // Reduced from 1.0
        case .desert:
            return 1.0  // Reduced from 1.3
        case .forest:
            return 0.9  // Reduced from 1.2
        case .mountain:
            return 1.2  // Reduced from 1.5
        case .space:
            return 1.5  // Reduced from 2.0
        case .underwater:
            return 1.3  // Reduced from 1.8
        // Seasonal maps still have bonus multipliers but reduced
        // These create time-limited opportunities for players to earn more
        case .halloween, .christmas:
            return 2.0  // Reduced from 2.5
        case .summer:
            return 1.7  // Reduced from 2.0
        }
    }
    
    // MARK: - Store Functions
    
    enum StoreItemType {
        case character
        case consumable
        case removal
    }
    
    struct StoreItem {
        let id: String
        let name: String
        let description: String
        let type: StoreItemType
        let coinPrice: Int?
        let gemPrice: Int?
        let isPurchased: Bool
    }
    
    func getStoreItems() -> [StoreItem] {
        let characterManager = CharacterManager.shared
        var items: [StoreItem] = []
        
        // Convert aircraft to store items
        for aircraft in characterManager.allAircraft.filter({ !$0.isUnlocked }) {
            items.append(StoreItem(
                id: "character_\(aircraft.type.rawValue)",
                name: aircraft.name,
                description: aircraft.description,
                type: .character,
                coinPrice: aircraft.unlockCost,
                gemPrice: aircraft.unlockCost / 150, // 150 coins = 1 gem (more favorable gem value)
                isPurchased: aircraft.isUnlocked
            ))
        }
        
        // Add consumable items
        items.append(contentsOf: [
            StoreItem(
                id: "consumable_coins_small",
                name: "Coin Pack",
                description: "750 coins to spend in the store", // Increased from 500
                type: .consumable,
                coinPrice: nil,
                gemPrice: 10, // Same price, better value proposition
                isPurchased: false
            ),
            StoreItem(
                id: "consumable_coins_medium",
                name: "Coin Chest",
                description: "2500 coins to spend in the store", // Increased from 1500
                type: .consumable,
                coinPrice: nil,
                gemPrice: 25, // Same price, better value proposition
                isPurchased: false
            ),
            StoreItem(
                id: "consumable_coins_large",
                name: "Coin Vault",
                description: "6000 coins to spend in the store", // New premium option
                type: .consumable,
                coinPrice: nil,
                gemPrice: 50, // Best value proposition
                isPurchased: false
            ),
            StoreItem(
                id: "consumable_extraLife",
                name: "Extra Life",
                description: "One-time use extra life for your next run",
                type: .consumable,
                coinPrice: 1500, // Increased from 1000
                gemPrice: 8, // Increased from 5
                isPurchased: PowerUpManager.shared.hasExtraLife
            ),
            StoreItem(
                id: "removal_ads",
                name: "Remove Ads",
                description: "Remove all advertisements from the game",
                type: .removal,
                coinPrice: nil,
                gemPrice: 50,
                isPurchased: UserDefaults.standard.bool(forKey: "adsRemoved")
            )
        ])
        
        return items
    }
    
    func purchaseItem(withID id: String, usingGems: Bool) -> Bool {
        let storeItems = getStoreItems()
        
        guard let item = storeItems.first(where: { $0.id == id }) else {
            return false
        }
        
        if usingGems {
            guard let gemPrice = item.gemPrice, gemPrice > 0 else {
                return false
            }
            
            if !spendGems(gemPrice) {
                return false
            }
        } else {
            guard let coinPrice = item.coinPrice, coinPrice > 0 else {
                return false
            }
            
            if !spendCoins(coinPrice) {
                return false
            }
        }
        
        // Process the purchase
        if item.id.starts(with: "character_") {
            let typeName = String(item.id.dropFirst("character_".count))
            if let type = CharacterManager.AircraftType(rawValue: typeName) {
                _ = CharacterManager.shared.unlockAircraft(type: type)
            }
        } else if item.id == "consumable_extraLife" {
            UserDefaults.standard.set(true, forKey: "hasExtraLife")
        } else if item.id == "consumable_coins_small" {
            _ = addCoins(750) // Increased from 500
        } else if item.id == "consumable_coins_medium" {
            _ = addCoins(2500) // Increased from 1500
        } else if item.id == "consumable_coins_large" {
            _ = addCoins(6000) // New premium option
        } else if item.id == "removal_ads" {
            UserDefaults.standard.set(true, forKey: "adsRemoved")
        }
        
        // Track shop purchase for achievements
        AchievementManager.shared.trackShopPurchase()
        
        return true
    }
}

// MARK: - Delegate Protocol
protocol CurrencyManagerDelegate: AnyObject {
    func currencyDidChange()
}