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
        let defaults = UserDefaults.standard
        defaults.set(coins, forKey: coinsKey)
        defaults.set(gems, forKey: gemsKey)
    }
    
    // MARK: - Game Integration
    
    func awardCoinsForScore(_ score: Int) -> Int {
        // Basic formula: 1 coin for every 10 points
        let earnedCoins = score / 10
        return addCoins(earnedCoins)
    }
    
    func getCoinMultiplier(for mapTheme: MapManager.MapTheme) -> Double {
        // Different maps can have different coin rewards
        switch mapTheme {
        case .city:
            return 1.0
        case .forest:
            return 1.2
        case .mountain:
            return 1.5
        case .space:
            return 2.0
        case .underwater:
            return 1.8
        // Seasonal maps have bonus multipliers
        case .halloween, .christmas:
            return 2.5
        case .summer:
            return 2.0
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
                gemPrice: aircraft.unlockCost / 100, // 100 coins = 1 gem
                isPurchased: aircraft.isUnlocked
            ))
        }
        
        // Add consumable items
        items.append(contentsOf: [
            StoreItem(
                id: "consumable_coins_small",
                name: "Coin Pack",
                description: "500 coins to spend in the store",
                type: .consumable,
                coinPrice: nil,
                gemPrice: 10,
                isPurchased: false
            ),
            StoreItem(
                id: "consumable_coins_medium",
                name: "Coin Chest",
                description: "1500 coins to spend in the store",
                type: .consumable,
                coinPrice: nil,
                gemPrice: 25,
                isPurchased: false
            ),
            StoreItem(
                id: "consumable_extraLife",
                name: "Extra Life",
                description: "One-time use extra life for your next run",
                type: .consumable,
                coinPrice: 1000,
                gemPrice: 5,
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
            _ = addCoins(500)
        } else if item.id == "consumable_coins_medium" {
            _ = addCoins(1500)
        } else if item.id == "removal_ads" {
            UserDefaults.standard.set(true, forKey: "adsRemoved")
        }
        
        return true
    }
}

// MARK: - Delegate Protocol
protocol CurrencyManagerDelegate: AnyObject {
    func currencyDidChange()
}