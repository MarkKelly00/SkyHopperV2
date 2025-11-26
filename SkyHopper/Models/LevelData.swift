import SpriteKit

struct LevelData {
    let id: String
    let name: String
    let description: String
    let mapTheme: MapManager.MapTheme
    let difficulty: Int // 1-5
    let unlockRequirement: UnlockRequirement
    let obstaclePatterns: [ObstaclePattern]
    let powerUpFrequency: TimeInterval
    let specialMechanics: [SpecialMechanic]
    var isUnlocked: Bool
    
    // MARK: - Unlock Requirements
    
    enum UnlockRequirement {
        case none // Starter level
        case previousLevelScore(Int)
        case playerLevel(Int)
        case totalScore(Int)
        case purchasable(coins: Int, gems: Int?)
        case seasonal(month: Int)
        
        var description: String {
            switch self {
            case .none:
                return "Available from the start"
            case .previousLevelScore(let score):
                return "Score \(score) points in the previous level"
            case .playerLevel(let level):
                return "Reach player level \(level)"
            case .totalScore(let score):
                return "Reach a total score of \(score) across all levels"
            case .purchasable(let coins, let gems):
                if let gems = gems {
                    return "Purchase for \(coins) coins or \(gems) gems"
                } else {
                    return "Purchase for \(coins) coins"
                }
            case .seasonal(let month):
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM"
                let date = Calendar.current.date(from: DateComponents(year: 2020, month: month, day: 1))!
                return "Available during \(dateFormatter.string(from: date))"
            }
        }
    }
    
    // MARK: - Obstacle Patterns
    
    struct ObstaclePattern {
        let id: String
        let name: String
        let difficulty: Int // 1-5
        let spawnFunction: (SKScene) -> Void
        
        // Factory method for creating standard patterns
        static func standardPattern(id: String, name: String, difficulty: Int, gapSize: CGFloat, speed: CGFloat) -> ObstaclePattern {
            return ObstaclePattern(
                id: id,
                name: name,
                difficulty: difficulty,
                spawnFunction: { scene in
                    // Standard obstacle spawning logic would go here
                    // This would be expanded in the actual implementation
                    print("Spawning pattern: \(name) with gap: \(gapSize), speed: \(speed)")
                }
            )
        }
    }
    
    // MARK: - Special Mechanics
    
    enum SpecialMechanic {
        case movingObstacles
        case shrinkingGaps
        case windGusts
        case gravitationalFields
        case teleporters
        case timedGates
        case inverseControls
        case fogEffects
        
        var description: String {
            switch self {
            case .movingObstacles:
                return "Obstacles move up and down"
            case .shrinkingGaps:
                return "Gaps between obstacles shrink as you approach"
            case .windGusts:
                return "Random wind gusts affect your movement"
            case .gravitationalFields:
                return "Areas with altered gravity"
            case .teleporters:
                return "Teleportation portals to different parts of the level"
            case .timedGates:
                return "Gates that open and close on a timer"
            case .inverseControls:
                return "Control inputs are periodically reversed"
            case .fogEffects:
                return "Reduced visibility with fog effects"
            }
        }
    }
    
    // MARK: - Level Progression
    
    static func createLevelProgression() -> [LevelData] {
        var levels: [LevelData] = []
        
        // Level 1: City Skyline - Tutorial Level
        levels.append(LevelData(
            id: "level_1",
            name: "City Beginnings",
            description: "Navigate your aircraft through the city skyline in this introductory level.",
            mapTheme: .city,
            difficulty: 1,
            unlockRequirement: .none,
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "basic_gaps", name: "Basic Gaps", difficulty: 1, gapSize: 150, speed: 120)
            ],
            powerUpFrequency: 15.0,
            specialMechanics: [],
            isUnlocked: true
        ))
        
        // Level 2: City Advanced
        levels.append(LevelData(
            id: "level_2",
            name: "Downtown Rush",
            description: "Faster pace through the heart of the city with narrower gaps.",
            mapTheme: .city,
            difficulty: 2,
            unlockRequirement: .previousLevelScore(50),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "narrow_gaps", name: "Narrow Gaps", difficulty: 2, gapSize: 120, speed: 130)
            ],
            powerUpFrequency: 12.0,
            specialMechanics: [],
            isUnlocked: true
        ))
        
        // Level 2.5: Stargate Escape
        levels.append(LevelData(
            id: "desert_escape",
            name: "Stargate Escape",
            description: "Navigate through Egyptian desert with pyramid obstacles and mysterious portal gates.",
            mapTheme: .desert,
            difficulty: 2,
            unlockRequirement: .previousLevelScore(75),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "desert_pyramids", name: "Desert Pyramids", difficulty: 2, gapSize: 140, speed: 125)
            ],
            powerUpFrequency: 8.0,
            specialMechanics: [.teleporters], // Teleporters represent the stargates
            isUnlocked: true
        ))
        
        // Level 3: Forest Valley
        levels.append(LevelData(
            id: "level_3",
            name: "Forest Valley",
            description: "Navigate through a lush forest with moving tree obstacles.",
            mapTheme: .forest,
            difficulty: 2,
            unlockRequirement: .previousLevelScore(100),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "moving_trees", name: "Moving Trees", difficulty: 2, gapSize: 130, speed: 125)
            ],
            powerUpFrequency: 10.0,
            specialMechanics: [.movingObstacles],
            isUnlocked: true
        ))
        
        // Level 4: Forest Challenge
        levels.append(LevelData(
            id: "level_4",
            name: "Deep Woods",
            description: "Dense forest with tighter spaces and wind effects.",
            mapTheme: .forest,
            difficulty: 3,
            unlockRequirement: .previousLevelScore(150),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "forest_maze", name: "Forest Maze", difficulty: 3, gapSize: 110, speed: 130)
            ],
            powerUpFrequency: 8.0,
            specialMechanics: [.movingObstacles, .windGusts],
            isUnlocked: true
        ))
        
        // Level 5: Mountain Pass
        levels.append(LevelData(
            id: "level_5",
            name: "Mountain Pass",
            description: "Navigate through mountain peaks with fog effects.",
            mapTheme: .mountain,
            difficulty: 3,
            unlockRequirement: .previousLevelScore(200),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "mountain_peaks", name: "Mountain Peaks", difficulty: 3, gapSize: 120, speed: 135)
            ],
            powerUpFrequency: 10.0,
            specialMechanics: [.fogEffects],
            isUnlocked: true
        ))
        
        // Level 6: Mountain Summit
        levels.append(LevelData(
            id: "level_6",
            name: "Summit Challenge",
            description: "High altitude flying with strong wind gusts and tight spaces.",
            mapTheme: .mountain,
            difficulty: 4,
            unlockRequirement: .previousLevelScore(250),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "summit_challenge", name: "Summit Challenge", difficulty: 4, gapSize: 100, speed: 140)
            ],
            powerUpFrequency: 8.0,
            specialMechanics: [.windGusts, .fogEffects],
            isUnlocked: true
        ))
        
        // Level 7: Reef Void
        levels.append(LevelData(
            id: "level_7",
            name: "Reef Void",
            description: "Submerged flying with modified physics and moving seaweed obstacles.",
            mapTheme: .underwater,
            difficulty: 3,
            unlockRequirement: .previousLevelScore(300),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "seaweed_forest", name: "Seaweed Forest", difficulty: 3, gapSize: 130, speed: 110)
            ],
            powerUpFrequency: 7.0,
            specialMechanics: [.movingObstacles, .gravitationalFields],
            isUnlocked: true
        ))
        
        // Level 8: Deep Sea
        levels.append(LevelData(
            id: "level_8",
            name: "Deep Sea Trenches",
            description: "Navigate the dark depths with limited visibility and gravitational currents.",
            mapTheme: .underwater,
            difficulty: 4,
            unlockRequirement: .previousLevelScore(350),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "deep_trenches", name: "Deep Trenches", difficulty: 4, gapSize: 110, speed: 120)
            ],
            powerUpFrequency: 6.0,
            specialMechanics: [.fogEffects, .gravitationalFields],
            isUnlocked: true
        ))
        
        // Level 9: Space Frontier
        levels.append(LevelData(
            id: "level_9",
            name: "Space Frontier",
            description: "Zero-gravity flying through asteroid fields with teleportation gates.",
            mapTheme: .space,
            difficulty: 4,
            unlockRequirement: .previousLevelScore(400),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "asteroid_field", name: "Asteroid Field", difficulty: 4, gapSize: 120, speed: 150)
            ],
            powerUpFrequency: 8.0,
            specialMechanics: [.movingObstacles, .teleporters],
            isUnlocked: true
        ))
        
        // Level 10: Cosmic Challenge
        levels.append(LevelData(
            id: "level_10",
            name: "Cosmic Challenge",
            description: "The ultimate challenge with all mechanics combined in an intense space setting.",
            mapTheme: .space,
            difficulty: 5,
            unlockRequirement: .previousLevelScore(500),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "cosmic_gauntlet", name: "Cosmic Gauntlet", difficulty: 5, gapSize: 100, speed: 160)
            ],
            powerUpFrequency: 5.0,
            specialMechanics: [.movingObstacles, .shrinkingGaps, .teleporters, .inverseControls],
            isUnlocked: true
        ))
        
        // Seasonal Levels
        levels.append(LevelData(
            id: "halloween_special",
            name: "Haunted Flight",
            description: "Spooky Halloween level with ghost obstacles and fog effects.",
            mapTheme: .halloween,
            difficulty: 3,
            unlockRequirement: .seasonal(month: 10),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "ghost_obstacles", name: "Ghost Obstacles", difficulty: 3, gapSize: 120, speed: 140)
            ],
            powerUpFrequency: 7.0,
            specialMechanics: [.fogEffects, .movingObstacles],
            isUnlocked: false
        ))
        
        levels.append(LevelData(
            id: "christmas_special",
            name: "Santa's Flight",
            description: "Help Santa navigate through Christmas trees while avoiding evil elves and collecting presents for bonus points!",
            mapTheme: .christmas,
            difficulty: 3,
            unlockRequirement: .seasonal(month: 12),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "christmas_trees", name: "Christmas Trees", difficulty: 3, gapSize: 120, speed: 135)
            ],
            powerUpFrequency: 5.0,
            specialMechanics: [.movingObstacles, .fogEffects],
            isUnlocked: true
        ))
        
        levels.append(LevelData(
            id: "summer_special",
            name: "Beach Party",
            description: "Summer beach level with beach umbrella obstacles and sunny skies.",
            mapTheme: .summer,
            difficulty: 2,
            unlockRequirement: .seasonal(month: 7),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "beach_objects", name: "Beach Objects", difficulty: 2, gapSize: 140, speed: 135)
            ],
            powerUpFrequency: 8.0,
            specialMechanics: [.windGusts],
            isUnlocked: false
        ))
        
        // Premium DLC Level (Purchasable)
        levels.append(LevelData(
            id: "premium_level_1",
            name: "Lost City",
            description: "Premium level with ancient ruins and unique mechanics.",
            mapTheme: .city, // Would ideally have a special theme
            difficulty: 3,
            unlockRequirement: .purchasable(coins: 5000, gems: 25),
            obstaclePatterns: [
                ObstaclePattern.standardPattern(id: "ancient_ruins", name: "Ancient Ruins", difficulty: 3, gapSize: 120, speed: 140)
            ],
            powerUpFrequency: 5.0,
            specialMechanics: [.timedGates, .teleporters],
            isUnlocked: false
        ))
        
        return levels
    }
    
    // MARK: - Level Management
    
    static func loadUnlockedLevels() -> [LevelData] {
        var levels = createLevelProgression()
        
        // Load unlocked status from UserDefaults
        if let unlockedIDs = UserDefaults.standard.stringArray(forKey: "unlockedLevels") {
            for i in 0..<levels.count {
                if unlockedIDs.contains(levels[i].id) {
                    levels[i].isUnlocked = true
                }
            }
        }
        
        // Check for seasonal levels
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        for i in 0..<levels.count {
            if case .seasonal(let month) = levels[i].unlockRequirement, month == currentMonth {
                levels[i].isUnlocked = true
            }
        }
        
        return levels
    }
    
    static func saveUnlockedLevels(_ levels: [LevelData]) {
        let unlockedIDs = levels.filter { $0.isUnlocked }.map { $0.id }
        UserDefaults.standard.set(unlockedIDs, forKey: "unlockedLevels")
    }
    
    static func unlockNextLevel(after currentLevelID: String, withScore score: Int) -> String? {
        var levels = loadUnlockedLevels()
        
        guard let currentIndex = levels.firstIndex(where: { $0.id == currentLevelID }),
              currentIndex + 1 < levels.count else {
            return nil
        }
        
        let nextLevel = levels[currentIndex + 1]
        
        // Check unlock requirement
        if case .previousLevelScore(let requiredScore) = nextLevel.unlockRequirement, score >= requiredScore {
            levels[currentIndex + 1].isUnlocked = true
            saveUnlockedLevels(levels)
            return nextLevel.id
        }
        
        return nil
    }
}
