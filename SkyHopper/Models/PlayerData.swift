import Foundation

class PlayerData {
    static let shared = PlayerData()
    
    // Player statistics
    var highScore: Int = 0
    var totalGamesPlayed: Int = 0
    var totalDistance: Int = 0
    var totalCoinsCollected: Int = 0
    var totalPowerUpsCollected: Int = 0
    var totalDeaths: Int = 0
    var longestRunTime: TimeInterval = 0
    var fastestCompletionTime: TimeInterval = 0
    
    // Map progression
    var mapHighScores: [String: Int] = [:]
    var mapBestTimes: [String: TimeInterval] = [:]
    
    // Achievement tracking
    var achievements: [String: Double] = [:] // achievement ID to progress
    
    // Daily challenges
    var currentDailyChallenges: [DailyChallenge] = []
    var lastDailyChallengeDate: Date?
    
    // Mission progress
    var missionProgress: [String: Double] = [:]
    
    // Daily login tracking
    var consecutiveDays: Int = 0
    var lastLoginDate: Date?
    
    private init() {
        loadSavedData()
    }
    
    func loadSavedData() {
        let defaults = UserDefaults.standard
        
        highScore = defaults.integer(forKey: "highScore")
        totalGamesPlayed = defaults.integer(forKey: "totalGamesPlayed")
        totalDistance = defaults.integer(forKey: "totalDistance")
        totalCoinsCollected = defaults.integer(forKey: "totalCoinsCollected")
        totalPowerUpsCollected = defaults.integer(forKey: "totalPowerUpsCollected")
        totalDeaths = defaults.integer(forKey: "totalDeaths")
        longestRunTime = defaults.double(forKey: "longestRunTime")
        fastestCompletionTime = defaults.double(forKey: "fastestCompletionTime")
        
        // Load complex data
        if let mapScoreData = defaults.dictionary(forKey: "mapHighScores") as? [String: Int] {
            mapHighScores = mapScoreData
        }
        
        if let mapTimeData = defaults.dictionary(forKey: "mapBestTimes") as? [String: Double] {
            mapBestTimes = mapTimeData.mapValues { TimeInterval($0) }
        }
        
        // Achievement progress
        if let achievementData = defaults.dictionary(forKey: "achievementProgress") as? [String: Double] {
            achievements = achievementData
        }
        
        // Mission progress
        if let missionData = defaults.dictionary(forKey: "missionProgress") as? [String: Double] {
            missionProgress = missionData
        }
        
        // Daily login data
        consecutiveDays = defaults.integer(forKey: "consecutiveDays")
        lastLoginDate = defaults.object(forKey: "lastLoginDate") as? Date
        
        // Load daily challenges if they exist and are for today
        if let challengeData = defaults.data(forKey: "dailyChallenges"),
           let challenges = try? JSONDecoder().decode([DailyChallenge].self, from: challengeData),
           let lastDate = defaults.object(forKey: "lastDailyChallengeDate") as? Date,
           Calendar.current.isDateInToday(lastDate) {
            
            currentDailyChallenges = challenges
            lastDailyChallengeDate = lastDate
        } else {
            // Generate new daily challenges
            generateDailyChallenges()
        }
        
        // Track daily login
        trackDailyLogin()
    }
    
    func saveData() {
        // Ensure thread-safe access to UserDefaults
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
        let defaults = UserDefaults.standard
        
            defaults.set(self.highScore, forKey: "highScore")
            defaults.set(self.totalGamesPlayed, forKey: "totalGamesPlayed")
            defaults.set(self.totalDistance, forKey: "totalDistance")
            defaults.set(self.totalCoinsCollected, forKey: "totalCoinsCollected")
            defaults.set(self.totalPowerUpsCollected, forKey: "totalPowerUpsCollected")
            defaults.set(self.totalDeaths, forKey: "totalDeaths")
            defaults.set(self.longestRunTime, forKey: "longestRunTime")
            defaults.set(self.fastestCompletionTime, forKey: "fastestCompletionTime")
        
        // Save complex data
            defaults.set(self.mapHighScores, forKey: "mapHighScores")
            defaults.set(self.mapBestTimes.mapValues { $0 }, forKey: "mapBestTimes")
            defaults.set(self.achievements, forKey: "achievementProgress")
            defaults.set(self.missionProgress, forKey: "missionProgress")
        
        // Daily login data
            defaults.set(self.consecutiveDays, forKey: "consecutiveDays")
            defaults.set(self.lastLoginDate, forKey: "lastLoginDate")
        
        // Save daily challenges
            if let challengeData = try? JSONEncoder().encode(self.currentDailyChallenges) {
            defaults.set(challengeData, forKey: "dailyChallenges")
                defaults.set(self.lastDailyChallengeDate, forKey: "lastDailyChallengeDate")
            }
            
            print("DEBUG: PlayerData saved successfully")
        }
    }
    
    // MARK: - Game Stats Tracking
    
    func recordGamePlayed() {
        totalGamesPlayed += 1
        saveData()
    }
    
    func recordDeath() {
        totalDeaths += 1
        saveData()
    }
    
    func updateHighScore(_ score: Int) -> Bool {
        guard score > highScore else { return false }
        
        highScore = score
        saveData()
        
        // Check if this new high score unlocks any new maps
        MapManager.shared.checkMapUnlocksBasedOnScore()
        
        return true
    }
    
    func updateMapHighScore(_ score: Int, for mapID: String) -> Bool {
        let currentBest = mapHighScores[mapID] ?? 0
        
        guard score >= currentBest else { return false }  // FIXED: Changed > to >= to handle equal scores
        
        mapHighScores[mapID] = score
        saveData()
        return true
    }
    
    func recordDistance(_ distance: Int) {
        totalDistance += distance
        saveData()
        
        // Update achievements
        AchievementManager.shared.trackDistance(totalDistance)
    }
    
    func recordRunTime(_ time: TimeInterval) {
        if time > longestRunTime {
            longestRunTime = time
            saveData()
        }
    }
    
    func recordCompletionTime(_ time: TimeInterval, for mapID: String) {
        let currentBest = mapBestTimes[mapID] ?? Double.infinity
        
        if time < currentBest || currentBest == Double.infinity {
            mapBestTimes[mapID] = time
            
            if time < fastestCompletionTime || fastestCompletionTime == 0 {
                fastestCompletionTime = time
            }
            
            saveData()
        }
    }
    
    func recordCoinsCollected(_ amount: Int) {
        totalCoinsCollected += amount
        saveData()
    }
    
    func recordPowerUpCollected() {
        totalPowerUpsCollected += 1
        saveData()
        
        // Update achievements
        AchievementManager.shared.trackPowerUpCollected()
    }
    
    // MARK: - Daily Challenges
    
    struct DailyChallenge: Codable {
        let id: String
        let description: String
        let targetValue: Int
        var currentValue: Int
        var isCompleted: Bool
        let rewardCoins: Int
        
        mutating func updateProgress(_ value: Int) -> Bool {
            guard !isCompleted else { return false }
            
            currentValue = min(value, targetValue)
            
            if currentValue >= targetValue {
                isCompleted = true
                return true
            }
            
            return false
        }
    }
    
    func generateDailyChallenges() {
        // Define challenge types
        let challengeTypes: [(id: String, description: String, minTarget: Int, maxTarget: Int, reward: Int)] = [
            ("score", "Score %d points in a single run", 100, 1000, 100),
            ("distance", "Travel a total distance of %d meters", 500, 5000, 150),
            ("powerups", "Collect %d power-ups", 3, 15, 100),
            ("games", "Play %d games", 3, 10, 50),
            ("coins", "Collect %d coins", 50, 300, 50),
            ("obstacles", "Avoid %d obstacles", 20, 100, 75)
        ]
        
        // Select 3 random challenges
        currentDailyChallenges = []
        var usedIndices = Set<Int>()
        
        for _ in 0..<3 {
            var index: Int
            repeat {
                index = Int.random(in: 0..<challengeTypes.count)
            } while usedIndices.contains(index)
            
            usedIndices.insert(index)
            let challenge = challengeTypes[index]
            
            // Generate random target within range
            let target = Int.random(in: challenge.minTarget...challenge.maxTarget)
            
            // Create challenge
            currentDailyChallenges.append(DailyChallenge(
                id: challenge.id,
                description: String(format: challenge.description, target),
                targetValue: target,
                currentValue: 0,
                isCompleted: false,
                rewardCoins: challenge.reward
            ))
        }
        
        lastDailyChallengeDate = Date()
        saveData()
    }
    
    func updateChallengeProgress(id: String, value: Int) {
        guard let index = currentDailyChallenges.firstIndex(where: { $0.id == id }) else { return }
        
        let wasCompleted = currentDailyChallenges[index].isCompleted
        let isNowCompleted = currentDailyChallenges[index].updateProgress(value)
        
        if !wasCompleted && isNowCompleted {
            // Challenge completed, award coins
            let reward = currentDailyChallenges[index].rewardCoins
            _ = CurrencyManager.shared.addCoins(reward)
            
            // Notify about completion
            NotificationCenter.default.post(
                name: NSNotification.Name("DailyChallengeCompleted"),
                object: nil,
                userInfo: ["challenge": currentDailyChallenges[index]]
            )
        }
        
        saveData()
    }
    
    // MARK: - Daily Login
    
    func trackDailyLogin() {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if we've already logged in today
        if let lastDate = lastLoginDate, calendar.isDateInToday(lastDate) {
            return // Already logged in today
        }
        
        // Check if this is the next consecutive day
        if let lastDate = lastLoginDate, 
           calendar.isDate(calendar.startOfDay(for: lastDate), inSameDayAs: calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!) {
            // Consecutive day
            consecutiveDays += 1
            
            // Reward based on streak
            let reward: Int
            switch consecutiveDays {
            case 2: reward = 10
            case 3: reward = 15
            case 4: reward = 20
            case 5: reward = 30
            case 6: reward = 40
            case 7...Int.max: reward = 50 + (consecutiveDays - 7) * 5 // 50, 55, 60, etc.
            default: reward = 5
            }
            
            _ = CurrencyManager.shared.addCoins(reward)
            
            // Notify about login reward
            NotificationCenter.default.post(
                name: NSNotification.Name("DailyLoginReward"),
                object: nil,
                userInfo: ["day": consecutiveDays, "reward": reward]
            )
        } else {
            // Not consecutive, reset streak
            consecutiveDays = 1
        }
        
        lastLoginDate = now
        saveData()
        
        // Track for achievements
        AchievementManager.shared.trackConsecutiveDays()
    }
    
    // MARK: - Resurrection Tracking
    
    // Added method to track player resurrection (extra life usage)
    var totalResurrections: Int = 0
    
    func recordResurrection() {
        totalResurrections += 1
        saveData()
        
        // Track for achievements
        AchievementManager.shared.trackResurrection()
    }
    
    // MARK: - Missions
    
    func updateMissionProgress(id: String, progress: Double) {
        let currentProgress = missionProgress[id] ?? 0
        missionProgress[id] = max(currentProgress, progress)
        saveData()
    }
    
    func getMissionProgress(id: String) -> Double {
        return missionProgress[id] ?? 0
    }
    
    // MARK: - Helper Methods
    
    /// Gets the highest score across all maps and the map name where it was achieved
    func getHighestScoreWithMapName() -> (score: Int, mapName: String?) {
        guard !mapHighScores.isEmpty else {
            return (score: 0, mapName: nil)
        }
        
        // Find the highest score
        let highestEntry = mapHighScores.max { $0.value < $1.value }
        guard let entry = highestEntry else {
            return (score: 0, mapName: nil)
        }
        
        // Get the map name from level data
        let levels = LevelData.loadUnlockedLevels()
        let mapName = levels.first { $0.id == entry.key }?.name
        
        return (score: entry.value, mapName: mapName)
    }
    
    func resetAllData() {
        // Reset all player data (for development/testing)
        highScore = 0
        totalGamesPlayed = 0
        totalDistance = 0
        totalCoinsCollected = 0
        totalPowerUpsCollected = 0
        totalDeaths = 0
        longestRunTime = 0
        fastestCompletionTime = 0
        
        mapHighScores = [:]
        mapBestTimes = [:]
        achievements = [:]
        missionProgress = [:]
        
        consecutiveDays = 0
        lastLoginDate = nil
        
        generateDailyChallenges()
        
        saveData()
    }
}