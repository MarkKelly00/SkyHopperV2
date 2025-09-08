import Foundation
import GameKit

class AchievementManager {
    static let shared = AchievementManager()
    
    struct Achievement {
        let id: String
        let name: String
        let description: String
        let points: Int
        let isHidden: Bool
        var isUnlocked: Bool
        var progress: Double // 0.0 to 1.0
        
        // Game Center integration
        var gameKitID: String?
    }
    
    var achievements: [Achievement] = []
    
    private init() {
        setupAchievements()
        loadSavedAchievements()
    }
    
    private func setupAchievements() {
        achievements = [
            // Distance-based achievements
            Achievement(
                id: "distance_100",
                name: "First Flight",
                description: "Fly a distance of 100 meters",
                points: 10,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.distance.100"
            ),
            Achievement(
                id: "distance_500",
                name: "Sky Explorer",
                description: "Fly a distance of 500 meters",
                points: 25,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.distance.500"
            ),
            Achievement(
                id: "distance_1000",
                name: "Mile High Club",
                description: "Fly a distance of 1000 meters",
                points: 50,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.distance.1000"
            ),
            Achievement(
                id: "distance_5000",
                name: "Transcontinental Pilot",
                description: "Fly a distance of 5000 meters",
                points: 100,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.distance.5000"
            ),
            
            // Score-based achievements
            Achievement(
                id: "score_100",
                name: "Century Score",
                description: "Reach a score of 100",
                points: 10,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.score.100"
            ),
            Achievement(
                id: "score_500",
                name: "Skilled Pilot",
                description: "Reach a score of 500",
                points: 25,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.score.500"
            ),
            Achievement(
                id: "score_1000",
                name: "Master Pilot",
                description: "Reach a score of 1000",
                points: 50,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.score.1000"
            ),
            
            // Power-up achievements
            Achievement(
                id: "powerups_10",
                name: "Power Collector",
                description: "Collect 10 power-ups",
                points: 15,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.powerups.10"
            ),
            Achievement(
                id: "powerups_50",
                name: "Power Hoarder",
                description: "Collect 50 power-ups",
                points: 30,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.powerups.50"
            ),
            Achievement(
                id: "powerups_100",
                name: "Power Addict",
                description: "Collect 100 power-ups",
                points: 50,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.powerups.100"
            ),
            
            // Character-based achievements
            Achievement(
                id: "unlock_all_characters",
                name: "Fleet Commander",
                description: "Unlock all characters",
                points: 100,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.characters.all"
            ),
            
            // Map-based achievements
            Achievement(
                id: "unlock_all_maps",
                name: "World Traveler",
                description: "Unlock all standard maps",
                points: 75,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.maps.all"
            ),
            
            // Special achievements
            Achievement(
                id: "close_call_10",
                name: "Living Dangerously",
                description: "Have 10 near misses with obstacles",
                points: 25,
                isHidden: true,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.closecalls.10"
            ),
            Achievement(
                id: "play_consecutive_7",
                name: "Weekly Flyer",
                description: "Play the game for 7 consecutive days",
                points: 50,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.consecutive.7"
            ),
            Achievement(
                id: "resurrect_5",
                name: "Phoenix",
                description: "Use the extra life power-up 5 times",
                points: 30,
                isHidden: false,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.resurrect.5"
            ),
            Achievement(
                id: "ghost_through_10",
                name: "Ghostly",
                description: "Pass through 10 obstacles with ghost power-up",
                points: 25,
                isHidden: true,
                isUnlocked: false,
                progress: 0,
                gameKitID: "com.skyhopper.ghost.10"
            )
        ]
    }
    
    // MARK: - Achievement Tracking
    
    func trackDistance(_ distance: Int) {
        updateAchievementProgress("distance_100", value: Double(distance), target: 100)
        updateAchievementProgress("distance_500", value: Double(distance), target: 500)
        updateAchievementProgress("distance_1000", value: Double(distance), target: 1000)
        updateAchievementProgress("distance_5000", value: Double(distance), target: 5000)
    }
    
    func trackScore(_ score: Int) {
        updateAchievementProgress("score_100", value: Double(score), target: 100)
        updateAchievementProgress("score_500", value: Double(score), target: 500)
        updateAchievementProgress("score_1000", value: Double(score), target: 1000)
    }
    
    func trackPowerUpCollected() {
        // Increment counts stored in UserDefaults
        let currentCount = UserDefaults.standard.integer(forKey: "powerUpCollectedCount") + 1
        UserDefaults.standard.set(currentCount, forKey: "powerUpCollectedCount")
        
        updateAchievementProgress("powerups_10", value: Double(currentCount), target: 10)
        updateAchievementProgress("powerups_50", value: Double(currentCount), target: 50)
        updateAchievementProgress("powerups_100", value: Double(currentCount), target: 100)
    }
    
    func trackResurrection() {
        let currentCount = UserDefaults.standard.integer(forKey: "resurrectCount") + 1
        UserDefaults.standard.set(currentCount, forKey: "resurrectCount")
        
        updateAchievementProgress("resurrect_5", value: Double(currentCount), target: 5)
    }
    
    func trackGhostObstaclePass() {
        let currentCount = UserDefaults.standard.integer(forKey: "ghostObstacleCount") + 1
        UserDefaults.standard.set(currentCount, forKey: "ghostObstacleCount")
        
        updateAchievementProgress("ghost_through_10", value: Double(currentCount), target: 10)
    }
    
    func trackCloseCall() {
        let currentCount = UserDefaults.standard.integer(forKey: "closeCallCount") + 1
        UserDefaults.standard.set(currentCount, forKey: "closeCallCount")
        
        updateAchievementProgress("close_call_10", value: Double(currentCount), target: 10)
    }
    
    func trackConsecutiveDays() {
        // Check if played today
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Load last played date
        if let lastPlayed = UserDefaults.standard.object(forKey: "lastPlayedDate") as? Date {
            let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
            
            if calendar.isDate(lastPlayedDay, inSameDayAs: today) {
                // Already tracked today, do nothing
                return
            }
            
            // Check if this is the next consecutive day
            let components = calendar.dateComponents([.day], from: lastPlayedDay, to: today)
            if let days = components.day, days == 1 {
                // Consecutive day
                let streak = UserDefaults.standard.integer(forKey: "consecutiveDaysStreak") + 1
                UserDefaults.standard.set(streak, forKey: "consecutiveDaysStreak")
                
                updateAchievementProgress("play_consecutive_7", value: Double(streak), target: 7)
            } else if let days = components.day, days > 1 {
                // Streak broken, reset
                UserDefaults.standard.set(1, forKey: "consecutiveDaysStreak")
            }
        } else {
            // First time playing
            UserDefaults.standard.set(1, forKey: "consecutiveDaysStreak")
        }
        
        // Update last played date to today
        UserDefaults.standard.set(today, forKey: "lastPlayedDate")
    }
    
    func trackCharacterUnlocks() {
        let characterManager = CharacterManager.shared
        let totalCharacters = CharacterManager.AircraftType.allCases.count
        let unlockedCount = characterManager.unlockedAircraft.count
        
        updateAchievementProgress("unlock_all_characters", value: Double(unlockedCount), target: Double(totalCharacters))
    }
    
    func trackMapUnlocks() {
        let mapManager = MapManager.shared
        // Filter out seasonal maps for this achievement
        let standardMapTypes = MapManager.MapTheme.allCases.filter { !$0.isSeasonalMap }
        let totalMaps = standardMapTypes.count
        let unlockedCount = mapManager.unlockedMaps.filter { !$0.isSeasonalMap }.count
        
        updateAchievementProgress("unlock_all_maps", value: Double(unlockedCount), target: Double(totalMaps))
    }
    
    private func updateAchievementProgress(_ id: String, value: Double, target: Double) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        
        var achievement = achievements[index]
        
        // Calculate progress (capped at 1.0)
        let newProgress = min(value / target, 1.0)
        
        // Only proceed if progress increased
        guard newProgress > achievement.progress else { return }
        
        achievement.progress = newProgress
        
        // Check if achievement is now complete
        if achievement.progress >= 1.0 && !achievement.isUnlocked {
            achievement.isUnlocked = true
            
            // Award points/currency for unlocking
            let earnedCoins = achievement.points * 10
            _ = CurrencyManager.shared.addCoins(earnedCoins)
            
            // Show notification to the player
            NotificationCenter.default.post(
                name: NSNotification.Name("AchievementUnlocked"),
                object: nil,
                userInfo: ["achievement": achievement]
            )
        }
        
        // Update Game Center if available and player is authenticated
        if let gameKitID = achievement.gameKitID, GKLocalPlayer.local.isAuthenticated {
            let gameKitAchievement = GKAchievement(identifier: gameKitID, player: GKLocalPlayer.local)
            gameKitAchievement.percentComplete = achievement.progress * 100.0
            gameKitAchievement.showsCompletionBanner = true
            
            GKAchievement.report([gameKitAchievement]) { error in
                if let error = error {
                    print("Error reporting achievement: \(error.localizedDescription)")
                }
            }
        }
        
        // Save the updated achievement
        achievements[index] = achievement
        saveAchievements()
    }
    
    // MARK: - Persistence
    
    private func loadSavedAchievements() {
        if let savedData = UserDefaults.standard.data(forKey: "savedAchievements"),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: savedData) {
            
            // Merge saved achievement progress with definitions
            for (index, achievement) in achievements.enumerated() {
                if let savedAchievement = savedAchievements.first(where: { $0.id == achievement.id }) {
                    achievements[index].progress = savedAchievement.progress
                    achievements[index].isUnlocked = savedAchievement.isUnlocked
                }
            }
        }
    }
    
    private func saveAchievements() {
        if let encodedData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encodedData, forKey: "savedAchievements")
        }
    }
    
    // MARK: - Game Center Integration
    
    func syncWithGameCenter() {
        // Only attempt to sync if player is authenticated
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Cannot sync achievements - player not authenticated")
            return
        }
        
        GKAchievement.loadAchievements { [weak self] (gkAchievements, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading achievements from Game Center: \(error.localizedDescription)")
                return
            }
            
            guard let gkAchievements = gkAchievements else { 
                print("No achievements returned from Game Center")
                return 
            }
            
            for gkAchievement in gkAchievements {
                if let index = self.achievements.firstIndex(where: { $0.gameKitID == gkAchievement.identifier }) {
                    // Update local achievement progress if Game Center has higher progress
                    let gameKitProgress = gkAchievement.percentComplete / 100.0
                    if gameKitProgress > self.achievements[index].progress {
                        self.achievements[index].progress = gameKitProgress
                        self.achievements[index].isUnlocked = gkAchievement.percentComplete >= 100.0
                    }
                }
            }
            
            self.saveAchievements()
        }
    }
    
    // MARK: - API Methods
    
    func getCompletedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    func getInProgressAchievements() -> [Achievement] {
        return achievements.filter { !$0.isUnlocked && $0.progress > 0 }
    }
    
    func getLockedAchievements() -> [Achievement] {
        return achievements.filter { !$0.isUnlocked && $0.progress == 0 && !$0.isHidden }
    }
    
    func getHiddenAchievements() -> [Achievement] {
        return achievements.filter { !$0.isUnlocked && $0.isHidden }
    }
    
    func resetAllAchievements() {
        // Reset all achievement progress
        for i in 0..<achievements.count {
            achievements[i].progress = 0
            achievements[i].isUnlocked = false
        }
        
        // Reset counters in UserDefaults
        UserDefaults.standard.removeObject(forKey: "powerUpCollectedCount")
        UserDefaults.standard.removeObject(forKey: "resurrectCount")
        UserDefaults.standard.removeObject(forKey: "ghostObstacleCount")
        UserDefaults.standard.removeObject(forKey: "closeCallCount")
        UserDefaults.standard.removeObject(forKey: "consecutiveDaysStreak")
        
        saveAchievements()
        
        // Reset Game Center achievements
        GKAchievement.resetAchievements { (error) in
            if let error = error {
                print("Error resetting Game Center achievements: \(error.localizedDescription)")
            }
        }
    }
}

// Make Achievement Codable for persistence
extension AchievementManager.Achievement: Codable {}