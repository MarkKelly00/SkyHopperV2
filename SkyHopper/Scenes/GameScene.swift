import SpriteKit
import GameKit

// MARK: - Extensions

extension Bool {
    // Helper method to create a random boolean with a given percentage chance of being true
    static func random(percentage: Int) -> Bool {
        return Int.random(in: 1...100) <= percentage
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    
    // Game state
    private var isGameStarted = false
    private var isGameOver = false
    private var score = 0
    private var distance = 0
    private var gameStartTime: TimeInterval = 0
    private var gameTime: TimeInterval = 0
    
    // Level properties
    private var levelId: String?
    private var currentLevel: LevelData?
    
    // Physics categories
    private let playerCategory: UInt32 = 1
    private let obstacleCategory: UInt32 = 2
    private let groundCategory: UInt32 = 4
    private let scoreCategory: UInt32 = 8
    private let powerUpCategory: UInt32 = 16
    
    // Game elements
    private var player: SKSpriteNode!
    private var ground: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var highScoreLabel: SKLabelNode!
    private var tapToStartLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode!
    
    // Game parameters
    private var obstacleFrequency: TimeInterval = 3.0
    private var obstacleSpeed: CGFloat = 120.0
    private var powerUpFrequency: TimeInterval = 10.0
    
    // Power-up states
    private var isInvincible = false
    private var invincibilityCount = 0
    private var isSpeedBoostActive = false
    
    // Managers
    private let powerUpManager = PowerUpManager.shared
    private let characterManager = CharacterManager.shared
    private let mapManager = MapManager.shared
    private let playerData = PlayerData.shared
    private let achievementManager = AchievementManager.shared
    private let audioManager = AudioManager.shared
    private let gameCenterManager = GameCenterManager.shared
    
    // MARK: - Initialization
    
    init(size: CGSize, levelId: String? = nil) {
        self.levelId = levelId
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupPhysics()
        
        // Load level settings first so they're available when creating game elements
        loadLevelSettings()
        
        // Apply map theme
        mapManager.applyTheme(to: self)
        
        // Now create game elements with correct level settings
        setupGameElements()
        
        // Display tap to start message
        displayTapToStartMessage()
        
        // Track daily challenge progress
        playerData.trackDailyLogin()
    }
    
    private func setupScene() {
        // Physics world setup will be done in setupPhysics()
        
        // Set default background color
        backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        
        // Add clouds for background decoration
        addClouds()
    }
    
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -5.0)
        physicsWorld.contactDelegate = self
        
        // Set physics speed to standard
        physicsWorld.speed = 1.0
    }
    
    private func setupGameElements() {
        // Create ground
        createGround()
        
        // Create player (helicopter, jet, etc.)
        createPlayer()
        
        // Create score display
        createScoreDisplay()
    }
    
    private func loadLevelSettings() {
        // Find level data if levelId is provided, otherwise use default
        if let levelId = self.levelId,
           let level = LevelData.loadUnlockedLevels().first(where: { $0.id == levelId }) {
            currentLevel = level
            
            // Apply level-specific settings
            obstacleFrequency = level.obstaclePatterns.first?.name == "Forest Maze" ? 2.0 : level.mapTheme.obstacleFrequency
            obstacleSpeed = level.mapTheme.obstacleSpeed
            powerUpFrequency = level.powerUpFrequency
        } else {
            // Default settings
            obstacleFrequency = 3.0
            obstacleSpeed = 120.0
            powerUpFrequency = 10.0
        }
    }
    
    // MARK: - Game Element Creation
    
    private func addClouds() {
        // Add a few clouds for decoration
        for _ in 0..<5 {
            let cloudWidth = CGFloat.random(in: 60...120)
            let cloudHeight = CGFloat.random(in: 30...50)
            
            let cloud = SKSpriteNode(color: .white, size: CGSize(width: cloudWidth, height: cloudHeight))
            cloud.alpha = 0.8
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height/2...size.height)
            )
            cloud.zPosition = -10
            
            // Animate cloud movement
            let moveLeft = SKAction.moveBy(x: -size.width - cloudWidth, y: 0, duration: Double.random(in: 20...30))
            let moveReset = SKAction.moveTo(x: size.width + cloudWidth/2, duration: 0)
            let moveSequence = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveSequence)
            
            cloud.run(moveForever)
            addChild(cloud)
        }
    }
    
    private func createGround() {
        ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: 60))
        
        // Set ground color based on level theme
        if currentLevel?.id == "desert_escape" {
            // Desert sand color for Stargate Escape level
            ground.fillColor = UIColor(red: 0.95, green: 0.85, blue: 0.6, alpha: 1.0)
            ground.strokeColor = UIColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0)
        } else if let mapTheme = currentLevel?.mapTheme {
            // Get ground color from map theme
            ground.fillColor = mapTheme.groundColor
            ground.strokeColor = mapTheme.groundColor.darker()
        } else {
            // Default ground color (green grass)
        ground.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0)
        ground.strokeColor = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
        }
        
        ground.zPosition = 10
        ground.name = "ground"
        
        // Add physics body to ground
        let groundPhysics = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 60))
        groundPhysics.isDynamic = false
        groundPhysics.categoryBitMask = groundCategory
        groundPhysics.contactTestBitMask = playerCategory
        groundPhysics.collisionBitMask = playerCategory
        ground.physicsBody = groundPhysics
        
        addChild(ground)
    }
    
    private func createPlayer() {
        // Force F22 Raptor for Desert level regardless of selected aircraft
        let isDesertLevel = currentLevel?.id == "desert_escape" || currentLevel?.mapTheme == .desert
        
        // Select appropriate aircraft based on level and user preferences
        var aircraftType: CharacterManager.AircraftType
        
        // Handle special case for desert level (Stargate Escape)
        if isDesertLevel {
            print("Desert level detected - using F22 Raptor")
            // Always use F22 Raptor for the desert level, regardless of whether it's unlocked
            aircraftType = .f22Raptor
            
            // Create the F22 directly to bypass unlock checks
            player = createF22RaptorSpriteDirectly()
            
            // Position player
            player.position = CGPoint(x: size.width * 0.3, y: size.height * 0.5)
            player.zPosition = 20
            
            // Set up physics body
            setupPlayerPhysics()
            
            addChild(player)
            return
        } 
        
        // If the player has selected the mapDefault option, choose aircraft based on level theme
        if characterManager.selectedAircraft == .mapDefault {
            // Determine appropriate aircraft for current map theme
            if let mapTheme = currentLevel?.mapTheme {
                switch mapTheme {
                case .city: aircraftType = .helicopter
                case .forest: aircraftType = .biplane
                case .mountain: aircraftType = .eagle
                case .underwater: aircraftType = .duck
                case .space: aircraftType = .rocketPack
                case .desert: aircraftType = .f22Raptor // Should never reach this due to earlier check
                case .halloween, .christmas, .summer: aircraftType = .fighterJet
                default: aircraftType = .helicopter // Fallback
                }
            } else {
                // Default if we can't determine map theme
                aircraftType = .helicopter
            }
        } else {
            // User has selected a specific aircraft
            aircraftType = characterManager.selectedAircraft
        }
        
        // Create the appropriate aircraft sprite with physics enabled for gameplay
        // If the aircraft is not unlocked and we're not in the desert level,
        // CharacterManager will fallback to the default aircraft
        player = characterManager.createAircraftSprite(for: aircraftType, enablePhysics: true)
        
        // Position player
        player.position = CGPoint(x: size.width * 0.3, y: size.height * 0.5)
        player.zPosition = 20
        
        // Make sure the physics body is set properly for the game
        setupPlayerPhysics()
        
        addChild(player)
    }
    
    private func setupPlayerPhysics() {
        if let physics = player.physicsBody {
            physics.affectedByGravity = false  // Start with no gravity until game begins
            physics.allowsRotation = false
            physics.categoryBitMask = playerCategory
            physics.contactTestBitMask = obstacleCategory | groundCategory | scoreCategory | powerUpCategory
            physics.collisionBitMask = obstacleCategory | groundCategory
        }
    }
    
    // Create F22 directly to bypass character manager unlock restrictions
    private func createF22RaptorSpriteDirectly() -> SKSpriteNode {
        let raptor = SKSpriteNode(color: .clear, size: CGSize(width: 60, height: 20))
        raptor.name = "player"

        // Main body - dark gray color
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: -28, y: -2)) // Back left
        bodyPath.addLine(to: CGPoint(x: -24, y: -4)) // Bottom curve
        bodyPath.addLine(to: CGPoint(x: -8, y: -4)) // Bottom straight
        bodyPath.addLine(to: CGPoint(x: 15, y: 0)) // Nose point
        bodyPath.addLine(to: CGPoint(x: -8, y: 4)) // Top straight
        bodyPath.addLine(to: CGPoint(x: -24, y: 4)) // Top curve
        bodyPath.close()

        let body = SKShapeNode(path: bodyPath.cgPath)
        body.fillColor = UIColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0) // Stealth dark gray
        body.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0) // Darker outline
        body.lineWidth = 1.0
        body.name = "playerBody"
        raptor.addChild(body)

        // Wings - angular, pixelated style
        let wingsPath = UIBezierPath()
        // Left wing
        wingsPath.move(to: CGPoint(x: -10, y: 0)) // Wing root
        wingsPath.addLine(to: CGPoint(x: -20, y: 8)) // Wing tip back
        wingsPath.addLine(to: CGPoint(x: -12, y: 8)) // Wing middle
        wingsPath.addLine(to: CGPoint(x: 0, y: 3)) // Wing front
        wingsPath.addLine(to: CGPoint(x: -10, y: 0)) // Back to root
        
        // Right wing - mirrored
        wingsPath.move(to: CGPoint(x: -10, y: 0)) // Wing root
        wingsPath.addLine(to: CGPoint(x: -20, y: -8)) // Wing tip back
        wingsPath.addLine(to: CGPoint(x: -12, y: -8)) // Wing middle
        wingsPath.addLine(to: CGPoint(x: 0, y: -3)) // Wing front
        wingsPath.addLine(to: CGPoint(x: -10, y: 0)) // Back to root

        let wings = SKShapeNode(path: wingsPath.cgPath)
        wings.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0) // Slightly lighter than body
        wings.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0) // Darker outline
        wings.lineWidth = 1.0
        wings.name = "playerWings"
        raptor.addChild(wings)

        // Cockpit - blue tinted canopy
        let cockpitPath = UIBezierPath()
        cockpitPath.move(to: CGPoint(x: 0, y: 0)) // Front of cockpit
        cockpitPath.addLine(to: CGPoint(x: -6, y: 2)) // Top back
        cockpitPath.addLine(to: CGPoint(x: -12, y: 2)) // Back top
        cockpitPath.addLine(to: CGPoint(x: -12, y: -2)) // Back bottom
        cockpitPath.addLine(to: CGPoint(x: -6, y: -2)) // Bottom back
        cockpitPath.addLine(to: CGPoint(x: 0, y: 0)) // Back to front
        cockpitPath.close()

        let cockpit = SKShapeNode(path: cockpitPath.cgPath)
        cockpit.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.8) // Blue tinted glass
        cockpit.strokeColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // Dark outline
        cockpit.lineWidth = 1.0
        cockpit.position = CGPoint(x: 8, y: 0) // Position near front
        cockpit.name = "playerCockpit"
        raptor.addChild(cockpit)

        // Tail fins - angular pixelated style
        let tailPath = UIBezierPath()
        // Left tail
        tailPath.move(to: CGPoint(x: -20, y: 2)) // Tail base
        tailPath.addLine(to: CGPoint(x: -25, y: 8)) // Tail top
        tailPath.addLine(to: CGPoint(x: -28, y: 8)) // Tail back
        tailPath.addLine(to: CGPoint(x: -28, y: 2)) // Back to base
        tailPath.close()
        
        // Right tail
        tailPath.move(to: CGPoint(x: -20, y: -2)) // Tail base
        tailPath.addLine(to: CGPoint(x: -25, y: -8)) // Tail top
        tailPath.addLine(to: CGPoint(x: -28, y: -8)) // Tail back
        tailPath.addLine(to: CGPoint(x: -28, y: -2)) // Back to base
        tailPath.close()

        let tails = SKShapeNode(path: tailPath.cgPath)
        tails.fillColor = UIColor(red: 0.27, green: 0.27, blue: 0.32, alpha: 1.0) // Slightly different than body
        tails.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0) // Darker outline
        tails.lineWidth = 1.0
        tails.name = "playerTails"
        raptor.addChild(tails)

        // Exhaust nozzles
        let nozzlePath = UIBezierPath()
        nozzlePath.move(to: CGPoint(x: -28, y: 2)) // Top left
        nozzlePath.addLine(to: CGPoint(x: -30, y: 2)) // Top right
        nozzlePath.addLine(to: CGPoint(x: -30, y: -2)) // Bottom right
        nozzlePath.addLine(to: CGPoint(x: -28, y: -2)) // Bottom left
        nozzlePath.close()

        let nozzles = SKShapeNode(path: nozzlePath.cgPath)
        nozzles.fillColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Dark exhaust
        nozzles.strokeColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // Almost black
        nozzles.lineWidth = 1.0
        nozzles.name = "playerNozzles"
        raptor.addChild(nozzles)

        // Afterburner effects
        let afterburnerPath = UIBezierPath()
        afterburnerPath.move(to: CGPoint(x: -30, y: 1)) // Top left
        afterburnerPath.addLine(to: CGPoint(x: -38, y: 0)) // Tip
        afterburnerPath.addLine(to: CGPoint(x: -30, y: -1)) // Bottom left
        afterburnerPath.close()

        let afterburner = SKShapeNode(path: afterburnerPath.cgPath)
        afterburner.fillColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.8) // Orange flame
        afterburner.strokeColor = UIColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.6) // Red-orange outline
        afterburner.lineWidth = 0.5
        afterburner.name = "playerAfterburner"

        // Create a shorter inner flame
        let innerFlamePath = UIBezierPath()
        innerFlamePath.move(to: CGPoint(x: -30, y: 0.6)) // Top left
        innerFlamePath.addLine(to: CGPoint(x: -35, y: 0)) // Tip
        innerFlamePath.addLine(to: CGPoint(x: -30, y: -0.6)) // Bottom left
        innerFlamePath.close()

        let innerFlame = SKShapeNode(path: innerFlamePath.cgPath)
        innerFlame.fillColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9) // Yellow core
        innerFlame.strokeColor = UIColor.clear
        innerFlame.name = "innerFlame"
        afterburner.addChild(innerFlame)

        // Animate afterburner
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.05)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.05)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        afterburner.run(repeatForever)
        
        // Slight color pulsing for inner flame
        let colorChange = SKAction.sequence([
            SKAction.colorize(with: .yellow, colorBlendFactor: 0.7, duration: 0.1),
            SKAction.colorize(with: .orange, colorBlendFactor: 0.3, duration: 0.1)
        ])
        let colorRepeat = SKAction.repeatForever(colorChange)
        innerFlame.run(colorRepeat)

        raptor.addChild(afterburner)

        // Always add physics body for the F22 Raptor in GameScene - it's needed for gameplay
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 16))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = playerCategory
        physicsBody.contactTestBitMask = obstacleCategory | groundCategory | scoreCategory | powerUpCategory
        physicsBody.collisionBitMask = obstacleCategory | groundCategory
        raptor.physicsBody = physicsBody

        return raptor
    }
    
    private func createScoreDisplay() {
        // Score label (current score)
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: size.height - 40)
        scoreLabel.zPosition = 50
        addChild(scoreLabel)
        
        // High score label (per-map)
        var bestForMap = 0
        if let levelId = self.levelId {
            bestForMap = PlayerData.shared.mapHighScores[levelId] ?? 0
        } else if let lvlId = currentLevel?.id {
            bestForMap = PlayerData.shared.mapHighScores[lvlId] ?? 0
        } else {
            bestForMap = UserDefaults.standard.integer(forKey: "highScore")
        }
        highScoreLabel = SKLabelNode(text: "Best: \(bestForMap)")
        highScoreLabel.fontName = "AvenirNext-Bold"
        highScoreLabel.fontSize = 24
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 40)
        highScoreLabel.zPosition = 50
        addChild(highScoreLabel)
    }
    
    private func displayTapToStartMessage() {
        tapToStartLabel = SKLabelNode(text: "Tap To Start!")
        tapToStartLabel.fontName = "AvenirNext-Bold"
        tapToStartLabel.fontSize = 36
        tapToStartLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        tapToStartLabel.zPosition = 50
        tapToStartLabel.name = "tapToStartLabel"
        
        // Add pulsating animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        tapToStartLabel.run(SKAction.repeatForever(pulse))
        
        addChild(tapToStartLabel)
    }
    
    // MARK: - Game Control
    
    private func startGame() {
        guard !isGameStarted else { return }
        
        isGameStarted = true
        
        // Record game start time
        gameStartTime = Date().timeIntervalSince1970
        
        // Remove "Tap To Start" label
        enumerateChildNodes(withName: "tapToStartLabel") { node, _ in
            node.removeFromParent()
        }
        
        // Enable player gravity
        player.physicsBody?.affectedByGravity = true
        
        // Start spawning obstacles
        startObstacleSpawning()
        
        // Start spawning power-ups
        startPowerUpSpawning()
        
        // Play game start sound
        audioManager.playEffect(.jump)
        
        // Record that the game was played
        playerData.recordGamePlayed()
    }
    
    private func startObstacleSpawning() {
        // Create and run the obstacle spawning action
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnObstacle()
        }
        let waitAction = SKAction.wait(forDuration: obstacleFrequency)
        let spawnSequence = SKAction.sequence([waitAction, spawnAction])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        
        run(spawnForever, withKey: "spawnObstacles")
    }
    
    private func startPowerUpSpawning() {
        // Create and run the power-up spawning action
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnPowerUp()
        }
        let waitAction = SKAction.wait(forDuration: powerUpFrequency)
        let spawnSequence = SKAction.sequence([waitAction, spawnAction])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        
        run(spawnForever, withKey: "spawnPowerUps")
    }
    
    private func spawnObstacle() {
        // Get level-specific settings for gap size and pattern difficulty
        var gapHeight: CGFloat = 170
        var obstacleWidth: CGFloat = 80
        
        // Adjust based on current level difficulty
        if let level = currentLevel {
            // Note: Desert level special features are handled in createObstacle method
            
            // Adjust gap height based on difficulty (smaller gaps for harder levels)
            switch level.difficulty {
            case 1: // Beginner - wider gaps
                gapHeight = CGFloat.random(in: 170...220)
            case 2: // Easy
                gapHeight = CGFloat.random(in: 150...200)
            case 3: // Medium
                gapHeight = CGFloat.random(in: 130...180)
            case 4: // Hard
                gapHeight = CGFloat.random(in: 120...160)
            case 5: // Expert
                gapHeight = CGFloat.random(in: 100...140)
            default:
                gapHeight = CGFloat.random(in: 150...200)
            }
            
            // Apply advanced patterns based on difficulty
            if level.difficulty > 1 {
                // Make obstacles slightly taller as difficulty increases
                obstacleWidth += CGFloat(level.difficulty - 1) * 5
            }
        }
        
        // Route to theme-specific obstacle creators
        if let theme = currentLevel?.mapTheme {
            switch theme {
            case .desert:
                createDesertObstacles(obstacleWidth: obstacleWidth, gapHeight: gapHeight)
                return
            case .mountain:
                createMountainObstacles(obstacleWidth: obstacleWidth, gapHeight: gapHeight)
                return
            case .underwater:
                createUnderwaterObstacles(obstacleWidth: obstacleWidth, gapHeight: gapHeight)
                return
            case .space:
                createSpaceObstacles(obstacleWidth: obstacleWidth, gapHeight: gapHeight)
                return
            case .forest:
                createJungleObstacles(obstacleWidth: obstacleWidth, gapHeight: gapHeight)
                return
            default:
                break
            }
        }
        
        // Standard Flappy Bird style for other levels
        // Calculate gap position
        let gapPosition = CGFloat.random(in: 150...(size.height - 150))
        
        // Create top obstacle
        let topObstacleHeight = gapPosition - (gapHeight / 2)
            let topObstacle = createObstacle(size: CGSize(width: obstacleWidth, height: topObstacleHeight), position: CGPoint(x: size.width + 40, y: size.height - (topObstacleHeight / 2)))
        
            // Create bottom obstacle - always create it for proper Flappy Bird-style gaps
        let bottomObstacleY = gapPosition + (gapHeight / 2)
        let bottomObstacleHeight = size.height - bottomObstacleY
            let bottomObstacle = createObstacle(size: CGSize(width: obstacleWidth, height: bottomObstacleHeight), position: CGPoint(x: size.width + 40, y: bottomObstacleY + (bottomObstacleHeight / 2)))
        
            // Create score node that spans the entire height of the screen
        let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: size.width + 40, y: size.height / 2) // Center vertically
        
            // Make the score detection zone cover the full height of the screen
            // This ensures the player gets points regardless of whether they go through, above or below the obstacles
            let scorePhysics = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: size.height))
        scorePhysics.isDynamic = false
        scorePhysics.categoryBitMask = scoreCategory
        scorePhysics.contactTestBitMask = playerCategory
        scorePhysics.collisionBitMask = 0 // Don't collide with anything
            
            // Set precise collision detection flag for better accuracy
            scorePhysics.usesPreciseCollisionDetection = true
            
        scoreNode.physicsBody = scorePhysics
        scoreNode.name = "scoreNode"
        
            // Optional visualization for debug - comment out in production
            // let visualizer = SKShapeNode(rectOf: CGSize(width: 15, height: gapHeight))
            // visualizer.fillColor = .green
            // visualizer.alpha = 0.3
            // scoreNode.addChild(visualizer)
        
        // Add the obstacles and score node to the scene
        addChild(topObstacle)
            addChild(bottomObstacle) // Always add bottom obstacle for Flappy Bird-style gameplay
        addChild(scoreNode)
        
        // Animate obstacle movement
        let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])
        
        topObstacle.run(sequence)
        bottomObstacle.run(sequence)
        scoreNode.run(sequence)
        
            // Note: distance is now incremented in handlePlayerScoreCollision
            // Track obstacles created
        playerData.recordDistance(1)
        
        // Update daily challenges
        playerData.updateChallengeProgress(id: "obstacles", value: distance * 2) // 2 obstacles per spawn
    }
    
    private func createObstacle(size: CGSize, position: CGPoint) -> SKNode {
        // Check if this is desert level
        let isDesertLevel = currentLevel?.id == "desert_escape"
        
        // Create obstacle node based on level theme
        let obstacle = SKSpriteNode(color: isDesertLevel ? 
                                    UIColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1.0) : // Sandy color for pyramids
                                    UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0),   // Default gray for city obstacles
                                    size: size)
        obstacle.position = position
        obstacle.zPosition = 15
        obstacle.name = "obstacle"
        
        // For desert level, create pyramid-themed obstacles
        if isDesertLevel {
            // Remove default rectangle texture and draw pyramids
            obstacle.color = .clear
            
                // Create pyramid shape for obstacles coming from the ground
                if size.height > 100 {
                    let pyramidPath = UIBezierPath()
                    pyramidPath.move(to: CGPoint(x: -size.width/2, y: -size.height/2)) // Bottom left
                    pyramidPath.addLine(to: CGPoint(x: size.width/2, y: -size.height/2)) // Bottom right
                    pyramidPath.addLine(to: CGPoint(x: 0, y: size.height/2)) // Top center
                    pyramidPath.close()

                    let pyramid = SKShapeNode(path: pyramidPath.cgPath)
                    pyramid.fillColor = UIColor(red: 0.85, green: 0.68, blue: 0.35, alpha: 1.0) // Sandy pyramid color
                    pyramid.strokeColor = UIColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 1.0) // Darker sandy border
                    pyramid.position = CGPoint.zero
                    obstacle.addChild(pyramid)

                    // Add horizontal lines as pyramid steps
                    let stepCount = min(6, Int(size.height / 35))
                    for i in 0..<stepCount {
                        let progress = CGFloat(i) / CGFloat(stepCount)
                        let stepWidth = size.width * (1.0 - progress)
                        let yPos = -size.height/2 + (progress * size.height)

                        let step = SKShapeNode(rectOf: CGSize(width: stepWidth, height: 3))
                        step.fillColor = UIColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 1.0) // Darker sandy color
                        step.strokeColor = .clear
                        step.position = CGPoint(x: 0, y: yPos)
                        pyramid.addChild(step)
                    }

                    // Add some small details to make it look more like ancient pyramid
                    let entrance = SKShapeNode(rectOf: CGSize(width: size.width * 0.15, height: size.height * 0.1))
                    entrance.fillColor = UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0) // Dark entrance
                    entrance.strokeColor = .clear
                    entrance.position = CGPoint(x: 0, y: -size.height/2 + (size.height * 0.05))
                    pyramid.addChild(entrance)
                    
                    // Randomly add a stargate portal above the pyramids (30% chance)
                    if Bool.random(percentage: 30) {
                        createStargatePortal(near: obstacle, at: position)
                    }
            } else {
                // For smaller obstacles, just make them sand dune shaped
                let duneShape = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
                duneShape.fillColor = UIColor(red: 0.9, green: 0.85, blue: 0.6, alpha: 1.0) // Light sand color
                duneShape.strokeColor = UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0) // Slightly darker border
                duneShape.position = CGPoint.zero
                obstacle.addChild(duneShape)
            }
        } else {
            // Regular obstacles for other levels (city buildings, etc.)
        if size.height > 50 {
            let stripeCount = Int(size.height / 40)
            for i in 0..<stripeCount {
                let stripe = SKShapeNode(rectOf: CGSize(width: size.width, height: 3))
                stripe.fillColor = .darkGray
                stripe.strokeColor = .clear
                stripe.position = CGPoint(x: 0, y: -size.height/2 + CGFloat(i * 40) + 20)
                obstacle.addChild(stripe)
                }
            }
        }
        
        // Create physics body
        // Use a triangular physics body for desert pyramids so collisions match visuals
        let physicsBody: SKPhysicsBody
        if isDesertLevel && size.height > 100 {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size.width / 2, y: -size.height / 2))
            path.addLine(to: CGPoint(x: size.width / 2, y: -size.height / 2))
            path.addLine(to: CGPoint(x: 0, y: size.height / 2))
            path.closeSubpath()
            physicsBody = SKPhysicsBody(polygonFrom: path)
        } else {
            physicsBody = SKPhysicsBody(rectangleOf: size)
        }
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        obstacle.physicsBody = physicsBody
        
        return obstacle
    }
    
        private func createStargatePortal(near obstacle: SKNode, at position: CGPoint) {
        // Position the stargate portal in the sky, away from the obstacle
        let xPos = position.x + CGFloat.random(in: -40...40)
        let yPos = position.y + size.height/4 + CGFloat.random(in: 0...size.height/4)
        
        // Create the portal node
        let portal = SKNode()
        portal.position = CGPoint(x: xPos, y: yPos)
        portal.zPosition = 16 // Slightly in front of obstacles
        portal.name = "stargate_portal" // Special name to identify it
        
        // Create Eye of Sauron style portal (vertical eye shape with fiery appearance)
        // Outer elliptical shape for the eye
        let eyeWidth: CGFloat = 40
        let eyeHeight: CGFloat = 60
        
        // Create fiery outer ring with vertical oval shape
        let eyePath = CGPath(ellipseIn: CGRect(x: -eyeWidth/2, y: -eyeHeight/2, width: eyeWidth, height: eyeHeight), transform: nil)
        let eyeRing = SKShapeNode(path: eyePath)
        eyeRing.fillColor = UIColor(red: 0.8, green: 0.2, blue: 0.0, alpha: 0.4) // Dark red/orange interior
        eyeRing.strokeColor = UIColor(red: 0.9, green: 0.3, blue: 0.0, alpha: 1.0) // Brighter orange ring
        eyeRing.lineWidth = 4
        eyeRing.alpha = 0.9
        eyeRing.position = CGPoint.zero
        portal.addChild(eyeRing)

        // Create inner pupil - black ellipse
        let pupilPath = CGPath(ellipseIn: CGRect(x: -eyeWidth/4, y: -eyeHeight/4, width: eyeWidth/2, height: eyeHeight/2), transform: nil)
        let pupil = SKShapeNode(path: pupilPath)
        pupil.fillColor = UIColor.black
        pupil.strokeColor = UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0) // Dark red outline
        pupil.lineWidth = 2
        pupil.position = CGPoint.zero
        eyeRing.addChild(pupil)

        // Create flame effect around the eye
        let flameCount = 8
        for i in 0..<flameCount {
            let angle = (CGFloat(i) / CGFloat(flameCount)) * CGFloat.pi * 2.0
            let flameDistance = max(eyeWidth, eyeHeight) * 0.7
            let flameX = cos(angle) * flameDistance * (eyeWidth/eyeHeight)
            let flameY = sin(angle) * flameDistance
            
            // Create flame path
            let flamePath = UIBezierPath()
            flamePath.move(to: CGPoint.zero)
            flamePath.addLine(to: CGPoint(x: flameX * 0.5, y: flameY * 0.5))
            flamePath.addLine(to: CGPoint(x: flameX * 0.7, y: flameY * 0.7))
            flamePath.addLine(to: CGPoint(x: flameX * 0.3, y: flameY * 0.9))
            flamePath.addLine(to: CGPoint(x: flameX, y: flameY))
            flamePath.addLine(to: CGPoint(x: flameX * 0.4, y: flameY * 0.8))
            flamePath.addLine(to: CGPoint(x: flameX * 0.6, y: flameY * 0.6))
            flamePath.addLine(to: CGPoint(x: flameX * 0.2, y: flameY * 0.4))
            flamePath.close()
            
            let flame = SKShapeNode(path: flamePath.cgPath)
            flame.fillColor = UIColor(red: 0.9, green: 0.4, blue: 0.0, alpha: 0.6) // Orange
            flame.strokeColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.4) // Yellow-orange
            flame.lineWidth = 1
            flame.alpha = 0.7
            flame.zPosition = -0.5
            flame.position = CGPoint.zero
            
            // Animate the flame
            let scaleAction = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.3 + Double.random(in: 0...0.2)),
                SKAction.scale(to: 0.8, duration: 0.3 + Double.random(in: 0...0.2))
            ])
            let fadeAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.9, duration: 0.2 + Double.random(in: 0...0.3)),
                SKAction.fadeAlpha(to: 0.5, duration: 0.2 + Double.random(in: 0...0.3))
            ])
            let groupAction = SKAction.group([scaleAction, fadeAction])
            let repeatAction = SKAction.repeatForever(groupAction)
            
            flame.run(repeatAction)
            eyeRing.addChild(flame)
        }

        // Create a glow effect
        let glow = SKEffectNode()
        glow.position = CGPoint.zero
        let glowFilter = CIFilter(name: "CIGaussianBlur")!
        glowFilter.setValue(5, forKey: "inputRadius")
        glow.filter = glowFilter
        glow.shouldEnableEffects = true
        glow.alpha = 0.7
        eyeRing.addChild(glow)
        
        // Animate the portal with pulsing effect
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 1.0),
            SKAction.scale(to: 0.9, duration: 1.0)
        ])
        let pulseRepeat = SKAction.repeatForever(pulseAction)
        eyeRing.run(pulseRepeat)
        
        // Add physics body for collision detection
        let portalPhysics = SKPhysicsBody(circleOfRadius: 25)
        portalPhysics.isDynamic = false
        portalPhysics.categoryBitMask = obstacleCategory // Same category as obstacles
        portalPhysics.contactTestBitMask = playerCategory
        portalPhysics.collisionBitMask = 0 // No actual collision physics, just detection
        portal.physicsBody = portalPhysics
        
        // Add portal to the scene
        addChild(portal)
        
        // Move the portal with the same speed as obstacles
        let moveAction = SKAction.moveTo(x: -100, duration: TimeInterval(size.width + 100) / obstacleSpeed)
        let removeAction = SKAction.removeFromParent()
        portal.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    private func createDesertObstacles(obstacleWidth: CGFloat, gapHeight: CGFloat) {
        // Create 1-2 pyramids from the ground with varying heights
        let pyramidCount = Int.random(in: 1...2)
        
        // Create a gap in a random horizontal position
        let gapXOffset = CGFloat.random(in: -obstacleWidth...obstacleWidth) * 0.5
        
        for i in 0..<pyramidCount {
            // Create pyramid sizes with different heights and widths
            let pyramidWidth = obstacleWidth + CGFloat.random(in: -10...20) // Vary width slightly
            let maxHeight = size.height * 0.7 // Max pyramid height - leaves room to fly over
            let minHeight = size.height * 0.3 // Min pyramid height
            
            // Calculate height - first pyramid is usually taller
            let pyramidHeight = i == 0 ? 
                CGFloat.random(in: minHeight + 50...maxHeight) : 
                CGFloat.random(in: minHeight...maxHeight - 50)
            
            // Calculate horizontal position - space them out
            var xOffset: CGFloat = 0
            if pyramidCount > 1 {
                // If we have multiple pyramids, space them out horizontally
                if i == 0 {
                    xOffset = gapXOffset - obstacleWidth * 1.0
                } else {
                    xOffset = gapXOffset + obstacleWidth * 1.0
                }
            } else {
                // For single pyramid, use the gap offset directly
                xOffset = gapXOffset
            }
            
            // Position relative to bottom of screen
            let position = CGPoint(
                x: size.width + 40 + xOffset,
                y: pyramidHeight / 2 // From bottom of screen
            )
            
            // Create obstacle
            let obstacle = createObstacle(
                size: CGSize(width: pyramidWidth, height: pyramidHeight),
                position: position
            )
            
            // Add the obstacle to the scene
            addChild(obstacle)
            
            // Animate obstacle movement
            let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
            let removeAction = SKAction.removeFromParent()
            let sequence = SKAction.sequence([moveAction, removeAction])
            obstacle.run(sequence)
            
            // Create a stargate above (30% chance, but only if this is the taller pyramid)
            if Bool.random(percentage: 30) && i == 0 {
                createStargatePortal(near: obstacle, at: CGPoint(
                    x: position.x,
                    y: position.y + pyramidHeight * 0.8 + CGFloat.random(in: 20...60)
                ))
            }
        }
        
        // Create score node that's used for all obstacles
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: size.width + 40, y: size.height / 2)
        
        // Make score detection span full height
        let scorePhysics = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: size.height))
        scorePhysics.isDynamic = false
        scorePhysics.categoryBitMask = scoreCategory
        scorePhysics.contactTestBitMask = playerCategory
        scorePhysics.collisionBitMask = 0
        scorePhysics.usesPreciseCollisionDetection = true
        
        scoreNode.physicsBody = scorePhysics
        scoreNode.name = "scoreNode"
        
        // Add score node to the scene
        addChild(scoreNode)
        
        // Animate score node
        let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
        let removeAction = SKAction.removeFromParent()
        scoreNode.run(SKAction.sequence([moveAction, removeAction]))
        
        // Track obstacles created for statistics
        playerData.recordDistance(pyramidCount)
        playerData.updateChallengeProgress(id: "obstacles", value: distance + pyramidCount)
    }
    
    // Mountain obstacles: ground-attached triangular peaks (like pyramids), with snow caps and optional icicle hazards
    private func createMountainObstacles(obstacleWidth: CGFloat, gapHeight: CGFloat) {
        // Create 1-2 mountain peaks similar to City Beginnings difficulty for 1-star maps
        let peakCount = Int.random(in: 1...2)
        let gapXOffset = CGFloat.random(in: -obstacleWidth...obstacleWidth) * 0.3
        
        for i in 0..<peakCount {
            let width = obstacleWidth + CGFloat.random(in: -5...15)
            // For Summit Surge (1-star difficulty), use similar heights to City Beginnings
            let maxHeight = size.height * 0.55 // Less tall than original
            let minHeight = size.height * 0.2
            let height = i == 0 ? 
                CGFloat.random(in: minHeight + 30...maxHeight) : 
                CGFloat.random(in: minHeight...maxHeight - 30)
            
            let xOffset: CGFloat = (peakCount > 1 ? 
                (i == 0 ? gapXOffset - obstacleWidth * 0.8 : gapXOffset + obstacleWidth * 0.8) : 
                gapXOffset)
            
            let position = CGPoint(x: size.width + 40 + xOffset, y: height / 2)
            
            // Create mountain obstacle with custom appearance
            let mountain = createMountainPeak(size: CGSize(width: width, height: height), position: position)
            addChild(mountain)
            
            // Movement animation
            let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
            let removeAction = SKAction.removeFromParent()
            mountain.run(SKAction.sequence([moveAction, removeAction]))
            
            // 20% chance to add icicle hazards for extra difficulty
            if Bool.random(percentage: 20) && height > 100 {
                createIcicleHazard(near: mountain, at: position)
            }
        }
        
        // Score node
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: size.width + 40, y: size.height / 2)
        let scorePhysics = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: size.height))
        scorePhysics.isDynamic = false
        scorePhysics.categoryBitMask = scoreCategory
        scorePhysics.contactTestBitMask = playerCategory
        scorePhysics.collisionBitMask = 0
        scorePhysics.usesPreciseCollisionDetection = true
        scoreNode.physicsBody = scorePhysics
        scoreNode.name = "scoreNode"
        addChild(scoreNode)
        let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
        scoreNode.run(SKAction.sequence([moveAction, .removeFromParent()]))
    }
    
    // Underwater obstacles: seabed rocks and coral reefs; sharks swim by like portals
    private func createUnderwaterObstacles(obstacleWidth: CGFloat, gapHeight: CGFloat) {
        // Create seabed rocks - these attach to the bottom like pyramids
        let rockHeight = CGFloat.random(in: 80...180)
        let rock = createUnderwaterRock(size: CGSize(width: obstacleWidth * 1.2, height: rockHeight), 
                                        position: CGPoint(x: size.width + 40, y: rockHeight / 2))
        addChild(rock)
        
        // Create coral reef pillars at different heights (2-star difficulty like Stargate)
        if Bool.random(percentage: 70) {
            let reefHeight = CGFloat.random(in: 100...200)
            let reefY = rockHeight + CGFloat.random(in: 60...120) + reefHeight / 2
            
            // Make sure reef doesn't go too high
            if reefY < size.height - 100 {
                let reef = createCoralReef(size: CGSize(width: obstacleWidth * 0.8, height: reefHeight), 
                                          position: CGPoint(x: size.width + 40 + CGFloat.random(in: -20...20), y: reefY))
                addChild(reef)
                let moveReef = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
                reef.run(SKAction.sequence([moveReef, .removeFromParent()]))
            }
        }
        
        let moveRock = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
        rock.run(SKAction.sequence([moveRock, .removeFromParent()]))
        
        // 35% chance to spawn shark hazard (like portals in Stargate)
        if Bool.random(percentage: 35) { 
            createSharkHazard() 
        }
        
        // Score node
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: size.width + 40, y: size.height / 2)
        let scorePhysics = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: size.height))
        scorePhysics.isDynamic = false
        scorePhysics.categoryBitMask = scoreCategory
        scorePhysics.contactTestBitMask = playerCategory
        scorePhysics.collisionBitMask = 0
        scorePhysics.usesPreciseCollisionDetection = true
        scoreNode.physicsBody = scorePhysics
        scoreNode.name = "scoreNode"
        addChild(scoreNode)
        let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
        scoreNode.run(SKAction.sequence([moveAction, .removeFromParent()]))
    }
    
    private func createSharkHazard() {
        // Create menacing shark with open mouth and teeth (like portals in Stargate)
        let shark = SKNode()
        shark.name = "shark_hazard"
        shark.zPosition = 16
        
        // Shark body - elongated oval shape
        let bodyPath = UIBezierPath(ovalIn: CGRect(x: -40, y: -12, width: 80, height: 24))
        let body = SKShapeNode(path: bodyPath.cgPath)
        body.fillColor = UIColor(red: 0.4, green: 0.45, blue: 0.5, alpha: 1.0) // Dark gray-blue
        body.strokeColor = UIColor(red: 0.25, green: 0.3, blue: 0.35, alpha: 1.0)
        body.lineWidth = 2
        shark.addChild(body)
        
        // Dorsal fin (triangular)
        let finPath = UIBezierPath()
        finPath.move(to: CGPoint(x: -8, y: 12))
        finPath.addLine(to: CGPoint(x: 8, y: 12))
        finPath.addLine(to: CGPoint(x: 0, y: 24))
        finPath.close()
        let fin = SKShapeNode(path: finPath.cgPath)
        fin.fillColor = UIColor(red: 0.35, green: 0.4, blue: 0.45, alpha: 1.0)
        fin.strokeColor = UIColor(red: 0.2, green: 0.25, blue: 0.3, alpha: 1.0)
        fin.position = CGPoint(x: -5, y: 0)
        shark.addChild(fin)
        
        // Tail fin
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -40, y: 0))
        tailPath.addLine(to: CGPoint(x: -50, y: 10))
        tailPath.addLine(to: CGPoint(x: -48, y: 0))
        tailPath.addLine(to: CGPoint(x: -50, y: -10))
        tailPath.close()
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.fillColor = body.fillColor
        tail.strokeColor = body.strokeColor
        shark.addChild(tail)
        
        // Open mouth with teeth (the danger zone)
        let mouthPath = UIBezierPath()
        mouthPath.move(to: CGPoint(x: 40, y: 0))
        mouthPath.addLine(to: CGPoint(x: 25, y: 8))
        mouthPath.addLine(to: CGPoint(x: 20, y: 0))
        mouthPath.addLine(to: CGPoint(x: 25, y: -8))
        mouthPath.close()
        let mouth = SKShapeNode(path: mouthPath.cgPath)
        mouth.fillColor = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.9) // Red mouth interior
        mouth.strokeColor = UIColor.white
        shark.addChild(mouth)
        
        // Add teeth
        for i in 0..<3 {
            let toothTop = SKShapeNode()
            let toothPath = UIBezierPath()
            toothPath.move(to: CGPoint(x: 0, y: 0))
            toothPath.addLine(to: CGPoint(x: -2, y: -4))
            toothPath.addLine(to: CGPoint(x: 2, y: -4))
            toothPath.close()
            toothTop.path = toothPath.cgPath
            toothTop.fillColor = .white
            toothTop.strokeColor = .clear
            toothTop.position = CGPoint(x: 24 + CGFloat(i * 5), y: 6)
            shark.addChild(toothTop)
            
            let toothBottom = SKShapeNode()
            let toothPathB = UIBezierPath()
            toothPathB.move(to: CGPoint(x: 0, y: 0))
            toothPathB.addLine(to: CGPoint(x: -2, y: 4))
            toothPathB.addLine(to: CGPoint(x: 2, y: 4))
            toothPathB.close()
            toothBottom.path = toothPathB.cgPath
            toothBottom.fillColor = .white
            toothBottom.strokeColor = .clear
            toothBottom.position = CGPoint(x: 24 + CGFloat(i * 5), y: -6)
            shark.addChild(toothBottom)
        }
        
        // Eye
        let eye = SKShapeNode(circleOfRadius: 3)
        eye.fillColor = .black
        eye.strokeColor = .white
        eye.lineWidth = 1
        eye.position = CGPoint(x: 15, y: 6)
        shark.addChild(eye)
        
        // Position shark in middle areas of screen
        let y = CGFloat.random(in: size.height * 0.3...size.height * 0.7)
        shark.position = CGPoint(x: size.width + 100, y: y)
        
        // Physics body for collision
        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 30))
        physics.isDynamic = false
        physics.categoryBitMask = obstacleCategory
        physics.contactTestBitMask = playerCategory
        physics.collisionBitMask = 0
        shark.physicsBody = physics
        
        // Add slight up-down swimming motion
        let swimUp = SKAction.moveBy(x: 0, y: 15, duration: 1.0)
        let swimDown = SKAction.moveBy(x: 0, y: -15, duration: 1.0)
        let swimSequence = SKAction.sequence([swimUp, swimDown])
        shark.run(SKAction.repeatForever(swimSequence))
        
        addChild(shark)
        
        // Move across screen
        let move = SKAction.moveTo(x: -150, duration: TimeInterval((size.width + 250) / obstacleSpeed))
        shark.run(SKAction.sequence([move, .removeFromParent()]))
    }
    
    // Space obstacles: realistic asteroids, space debris, and satellite wreckage (3-star difficulty)
    private func createSpaceObstacles(obstacleWidth: CGFloat, gapHeight: CGFloat) {
        // Faster movement for 3-star difficulty
        let speedMultiplier: CGFloat = 1.3
        
        // Spawn 2-3 asteroids for increased difficulty
        let asteroidCount = Int.random(in: 2...3)
        for i in 0..<asteroidCount {
            let asteroid = createAsteroid()
            
            // Position asteroids at different heights
            let yRange = size.height - 200
            let yPos = 100 + (yRange / CGFloat(asteroidCount)) * CGFloat(i) + CGFloat.random(in: -30...30)
            asteroid.position = CGPoint(x: size.width + 60 + CGFloat(i * 40), y: yPos)
            
            addChild(asteroid)
            
            // Faster movement for 3-star maps
            let moveDuration = TimeInterval(size.width / (obstacleSpeed * speedMultiplier))
            let move = SKAction.moveBy(x: -(size.width + 150), y: 0, duration: moveDuration)
            asteroid.run(SKAction.sequence([move, .removeFromParent()]))
        }
        
        // Add space debris/satellite parts
        if Bool.random(percentage: 60) {
            let debris = createSpaceDebris()
            debris.position = CGPoint(x: size.width + 100, y: CGFloat.random(in: 120...(size.height - 120)))
            addChild(debris)
            
            let moveDuration = TimeInterval(size.width / (obstacleSpeed * speedMultiplier))
            let moveDebris = SKAction.moveBy(x: -(size.width + 150), y: 0, duration: moveDuration)
            debris.run(SKAction.sequence([moveDebris, .removeFromParent()]))
        }
        
        // 30% chance for shooting star/comet hazard
        if Bool.random(percentage: 30) { 
            createShootingStarHazard() 
        }
        
        // Score node
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: size.width + 40, y: size.height / 2)
        let scorePhysics = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: size.height))
        scorePhysics.isDynamic = false
        scorePhysics.categoryBitMask = scoreCategory
        scorePhysics.contactTestBitMask = playerCategory
        scorePhysics.collisionBitMask = 0
        scorePhysics.usesPreciseCollisionDetection = true
        scoreNode.physicsBody = scorePhysics
        scoreNode.name = "scoreNode"
        addChild(scoreNode)
        
        let moveDuration = TimeInterval(size.width / (obstacleSpeed * speedMultiplier))
        let moveAction = SKAction.moveBy(x: -(size.width + 150), y: 0, duration: moveDuration)
        scoreNode.run(SKAction.sequence([moveAction, .removeFromParent()]))
    }
    
    // Create realistic asteroid obstacles
    private func createAsteroid() -> SKNode {
        let asteroid = SKNode()
        asteroid.name = "obstacle"
        asteroid.zPosition = 15
        
        // Random asteroid size
        let radius = CGFloat.random(in: 25...45)
        
        // Create irregular asteroid shape
        let path = UIBezierPath()
        let segments = 8
        for i in 0..<segments {
            let angle = (CGFloat(i) / CGFloat(segments)) * CGFloat.pi * 2.0
            let radiusVariation = radius + CGFloat.random(in: -8...8)
            let x = cos(angle) * radiusVariation
            let y = sin(angle) * radiusVariation
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()
        
        let asteroidShape = SKShapeNode(path: path.cgPath)
        asteroidShape.fillColor = UIColor(red: 0.6, green: 0.55, blue: 0.5, alpha: 1.0) // Gray-brown
        asteroidShape.strokeColor = UIColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0)
        asteroidShape.lineWidth = 2
        asteroid.addChild(asteroidShape)
        
        // Add crater details
        for _ in 0..<3 {
            let craterRadius = CGFloat.random(in: 3...7)
            let crater = SKShapeNode(circleOfRadius: craterRadius)
            crater.fillColor = UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 0.5)
            crater.strokeColor = .clear
            crater.position = CGPoint(x: CGFloat.random(in: -radius/2...radius/2),
                                     y: CGFloat.random(in: -radius/2...radius/2))
            asteroid.addChild(crater)
        }
        
        // Slow rotation
        let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 8.0)
        asteroid.run(SKAction.repeatForever(rotate))
        
        // Physics body
        let physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        asteroid.physicsBody = physicsBody
        
        return asteroid
    }
    
    // Create space debris/satellite parts
    private func createSpaceDebris() -> SKNode {
        let debris = SKNode()
        debris.name = "obstacle"
        debris.zPosition = 15
        
        // Create metallic debris piece
        let width = CGFloat.random(in: 30...50)
        let height = CGFloat.random(in: 15...25)
        
        let debrisShape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 3)
        debrisShape.fillColor = UIColor(red: 0.7, green: 0.75, blue: 0.8, alpha: 1.0) // Metallic
        debrisShape.strokeColor = UIColor(red: 0.5, green: 0.55, blue: 0.6, alpha: 1.0)
        debrisShape.lineWidth = 1
        debris.addChild(debrisShape)
        
        // Add solar panel or antenna details
        if Bool.random() {
            // Solar panel
            let panel = SKShapeNode(rectOf: CGSize(width: width * 0.8, height: 3))
            panel.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 0.9) // Dark blue panel
            panel.strokeColor = .clear
            panel.position = CGPoint(x: 0, y: 0)
            debris.addChild(panel)
        } else {
            // Antenna
            let antenna = SKShapeNode(rectOf: CGSize(width: 2, height: 15))
            antenna.fillColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
            antenna.strokeColor = .clear
            antenna.position = CGPoint(x: width/3, y: height/2 + 7)
            debris.addChild(antenna)
        }
        
        // Tumbling motion
        let tumble = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 6.0)
        debris.run(SKAction.repeatForever(tumble))
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height))
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        debris.physicsBody = physicsBody
        
        return debris
    }
    
    // Create shooting star hazard
    private func createShootingStarHazard() {
        let shootingStar = SKNode()
        shootingStar.name = "shooting_star_hazard"
        shootingStar.zPosition = 16
        
        // Star head
        let starHead = SKShapeNode(circleOfRadius: 6)
        starHead.fillColor = UIColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0) // Bright yellow-white
        starHead.strokeColor = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
        starHead.lineWidth = 2
        starHead.glowWidth = 4
        shootingStar.addChild(starHead)
        
        // Comet tail
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: 0, y: 0))
        tailPath.addLine(to: CGPoint(x: -30, y: 3))
        tailPath.addLine(to: CGPoint(x: -40, y: 0))
        tailPath.addLine(to: CGPoint(x: -30, y: -3))
        tailPath.close()
        
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.fillColor = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.7)
        tail.strokeColor = .clear
        shootingStar.addChild(tail)
        
        // Position and movement
        shootingStar.position = CGPoint(x: size.width + 60, y: CGFloat.random(in: size.height*0.6...size.height*0.9))
        
        // Physics
        let physics = SKPhysicsBody(circleOfRadius: 8)
        physics.isDynamic = false
        physics.categoryBitMask = obstacleCategory
        physics.contactTestBitMask = playerCategory
        physics.collisionBitMask = 0
        shootingStar.physicsBody = physics
        
        addChild(shootingStar)
        
        // Fast diagonal movement
        let moveX = -(size.width + 200)
        let moveY = -CGFloat.random(in: 100...200)
        let move = SKAction.moveBy(x: moveX, y: moveY, duration: TimeInterval(size.width / (obstacleSpeed * 1.5)))
        shootingStar.run(SKAction.sequence([move, .removeFromParent()]))
    }
    
    // Jungle/Forest obstacles: trees, vines, and wildlife (2-star difficulty like Stargate)
    private func createJungleObstacles(obstacleWidth: CGFloat, gapHeight: CGFloat) {
        // Create tree trunks from ground (similar pattern to pyramids)
        let treeCount = Int.random(in: 1...2)
        let gapXOffset = CGFloat.random(in: -obstacleWidth...obstacleWidth) * 0.4
        
        for i in 0..<treeCount {
            let width = obstacleWidth * 0.9 + CGFloat.random(in: -5...10)
            let maxHeight = size.height * 0.6 // Medium difficulty
            let minHeight = size.height * 0.25
            let height = i == 0 ? 
                CGFloat.random(in: minHeight + 40...maxHeight) : 
                CGFloat.random(in: minHeight...maxHeight - 40)
            
            let xOffset: CGFloat = (treeCount > 1 ? 
                (i == 0 ? gapXOffset - obstacleWidth * 0.9 : gapXOffset + obstacleWidth * 0.9) : 
                gapXOffset)
            
            let position = CGPoint(x: size.width + 40 + xOffset, y: height / 2)
            
            // Create tree obstacle
            let tree = createJungleTree(size: CGSize(width: width, height: height), position: position)
            addChild(tree)
            
            // Movement
            let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
            tree.run(SKAction.sequence([moveAction, .removeFromParent()]))
            
            // 25% chance to add swinging vine hazard
            if Bool.random(percentage: 25) && i == 0 {
                createVineHazard(near: tree, at: position)
            }
        }
        
        // 30% chance to spawn a bird/parrot hazard
        if Bool.random(percentage: 30) {
            createBirdHazard()
        }
        
        // Score node
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: size.width + 40, y: size.height / 2)
        let scorePhysics = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: size.height))
        scorePhysics.isDynamic = false
        scorePhysics.categoryBitMask = scoreCategory
        scorePhysics.contactTestBitMask = playerCategory
        scorePhysics.collisionBitMask = 0
        scorePhysics.usesPreciseCollisionDetection = true
        scoreNode.physicsBody = scorePhysics
        scoreNode.name = "scoreNode"
        addChild(scoreNode)
        let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
        scoreNode.run(SKAction.sequence([moveAction, .removeFromParent()]))
    }
    
    // Create jungle tree obstacle
    private func createJungleTree(size: CGSize, position: CGPoint) -> SKNode {
        let tree = SKSpriteNode(color: .clear, size: size)
        tree.position = position
        tree.zPosition = 15
        tree.name = "obstacle"
        
        // Tree trunk
        let trunkPath = UIBezierPath(roundedRect: CGRect(x: -size.width/2, y: -size.height/2, 
                                                         width: size.width, height: size.height), 
                                    cornerRadius: size.width * 0.1)
        
        let trunk = SKShapeNode(path: trunkPath.cgPath)
        trunk.fillColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0) // Brown trunk
        trunk.strokeColor = UIColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
        trunk.lineWidth = 2
        tree.addChild(trunk)
        
        // Add tree bark texture
        for i in 0..<5 {
            let barkLine = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: 2))
            barkLine.fillColor = UIColor(red: 0.3, green: 0.2, blue: 0.08, alpha: 0.5)
            barkLine.strokeColor = .clear
            barkLine.position = CGPoint(x: 0, y: -size.height/2 + CGFloat(i) * (size.height/5) + 10)
            tree.addChild(barkLine)
        }
        
        // Add leafy canopy on top
        if size.height > 100 {
            for _ in 0..<3 {
                let leafCluster = SKShapeNode(circleOfRadius: CGFloat.random(in: 15...25))
                leafCluster.fillColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 0.9) // Green leaves
                leafCluster.strokeColor = UIColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0)
                leafCluster.lineWidth = 1
                leafCluster.position = CGPoint(x: CGFloat.random(in: -size.width/3...size.width/3),
                                              y: size.height/2 + CGFloat.random(in: 0...20))
                tree.addChild(leafCluster)
            }
        }
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        tree.physicsBody = physicsBody
        
        return tree
    }
    
    // Create swinging vine hazard
    private func createVineHazard(near tree: SKNode, at position: CGPoint) {
        let vine = SKNode()
        vine.name = "vine_hazard"
        vine.zPosition = 16
        
        // Create vine rope
        let vineLength: CGFloat = 60
        let vineShape = SKShapeNode(rectOf: CGSize(width: 4, height: vineLength), cornerRadius: 2)
        vineShape.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.2, alpha: 1.0) // Dark green vine
        vineShape.strokeColor = UIColor(red: 0.2, green: 0.3, blue: 0.1, alpha: 1.0)
        vineShape.position = CGPoint(x: 0, y: -vineLength/2)
        vine.addChild(vineShape)
        
        // Add leaves
        for i in 0..<3 {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: 8, height: 12))
            leaf.fillColor = UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 0.9)
            leaf.strokeColor = .clear
            leaf.position = CGPoint(x: CGFloat.random(in: -3...3), 
                                   y: -CGFloat(i) * 20)
            vine.addChild(leaf)
        }
        
        // Position vine hanging from above the tree
        vine.position = CGPoint(x: position.x + CGFloat.random(in: -30...30),
                               y: position.y + size.height/2 + 100)
        
        // Swinging animation
        vine.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        let swing = SKAction.sequence([
            SKAction.rotate(byAngle: 0.3, duration: 2.0),
            SKAction.rotate(byAngle: -0.6, duration: 4.0),
            SKAction.rotate(byAngle: 0.3, duration: 2.0)
        ])
        vine.run(SKAction.repeatForever(swing))
        
        // Physics
        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: vineLength))
        physics.isDynamic = false
        physics.categoryBitMask = obstacleCategory
        physics.contactTestBitMask = playerCategory
        physics.collisionBitMask = 0
        vine.physicsBody = physics
        
        addChild(vine)
        
        // Movement
        let move = SKAction.moveTo(x: -100, duration: TimeInterval((size.width + 200) / obstacleSpeed))
        vine.run(SKAction.sequence([move, .removeFromParent()]))
    }
    
    // Create bird/parrot hazard
    private func createBirdHazard() {
        let bird = SKNode()
        bird.name = "bird_hazard"
        bird.zPosition = 16
        
        // Bird body
        let body = SKShapeNode(ellipseOf: CGSize(width: 20, height: 15))
        body.fillColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) // Red parrot
        body.strokeColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
        bird.addChild(body)
        
        // Wings
        let wingPath = UIBezierPath()
        wingPath.move(to: CGPoint(x: -10, y: 0))
        wingPath.addLine(to: CGPoint(x: -20, y: 5))
        wingPath.addLine(to: CGPoint(x: -15, y: -5))
        wingPath.close()
        
        let leftWing = SKShapeNode(path: wingPath.cgPath)
        leftWing.fillColor = body.fillColor
        leftWing.strokeColor = body.strokeColor
        bird.addChild(leftWing)
        
        let rightWing = SKShapeNode(path: wingPath.cgPath)
        rightWing.xScale = -1
        rightWing.fillColor = body.fillColor
        rightWing.strokeColor = body.strokeColor
        bird.addChild(rightWing)
        
        // Beak
        let beak = SKShapeNode()
        let beakPath = UIBezierPath()
        beakPath.move(to: CGPoint(x: 10, y: 0))
        beakPath.addLine(to: CGPoint(x: 15, y: 2))
        beakPath.addLine(to: CGPoint(x: 15, y: -2))
        beakPath.close()
        beak.path = beakPath.cgPath
        beak.fillColor = UIColor.orange
        beak.strokeColor = .clear
        bird.addChild(beak)
        
        // Wing flapping animation
        let flapUp = SKAction.rotate(byAngle: 0.2, duration: 0.2)
        let flapDown = SKAction.rotate(byAngle: -0.4, duration: 0.2)
        let flapReset = SKAction.rotate(byAngle: 0.2, duration: 0.2)
        let flap = SKAction.sequence([flapUp, flapDown, flapReset])
        leftWing.run(SKAction.repeatForever(flap))
        rightWing.run(SKAction.repeatForever(flap))
        
        // Position
        bird.position = CGPoint(x: size.width + 80, y: CGFloat.random(in: size.height*0.4...size.height*0.8))
        
        // Physics
        let physics = SKPhysicsBody(circleOfRadius: 12)
        physics.isDynamic = false
        physics.categoryBitMask = obstacleCategory
        physics.contactTestBitMask = playerCategory
        physics.collisionBitMask = 0
        bird.physicsBody = physics
        
        addChild(bird)
        
        // Swooping movement
        let moveX = -(size.width + 200)
        let swoopY = sin(CGFloat.random(in: 0...CGFloat.pi)) * 30
        let move = SKAction.moveBy(x: moveX, y: swoopY, duration: TimeInterval((size.width + 200) / obstacleSpeed))
        bird.run(SKAction.sequence([move, .removeFromParent()]))
    }
    
    // Helper function to create mountain peak obstacles with snow caps
    private func createMountainPeak(size: CGSize, position: CGPoint) -> SKNode {
        let mountain = SKSpriteNode(color: .clear, size: size)
        mountain.position = position
        mountain.zPosition = 15
        mountain.name = "obstacle"
        
        // Create triangular mountain shape
        let mountainPath = UIBezierPath()
        mountainPath.move(to: CGPoint(x: -size.width/2, y: -size.height/2))
        mountainPath.addLine(to: CGPoint(x: size.width/2, y: -size.height/2))
        mountainPath.addLine(to: CGPoint(x: 0, y: size.height/2))
        mountainPath.close()
        
        let mountainShape = SKShapeNode(path: mountainPath.cgPath)
        mountainShape.fillColor = UIColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0) // Gray mountain
        mountainShape.strokeColor = UIColor(red: 0.35, green: 0.35, blue: 0.4, alpha: 1.0)
        mountainShape.lineWidth = 2
        mountain.addChild(mountainShape)
        
        // Add snow cap on top (white triangle at peak)
        let snowCapHeight = size.height * 0.3
        let snowPath = UIBezierPath()
        snowPath.move(to: CGPoint(x: -size.width/4, y: size.height/2 - snowCapHeight))
        snowPath.addLine(to: CGPoint(x: size.width/4, y: size.height/2 - snowCapHeight))
        snowPath.addLine(to: CGPoint(x: 0, y: size.height/2))
        snowPath.close()
        
        let snowCap = SKShapeNode(path: snowPath.cgPath)
        snowCap.fillColor = UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0) // Snow white
        snowCap.strokeColor = UIColor(red: 0.85, green: 0.85, blue: 0.9, alpha: 1.0)
        snowCap.lineWidth = 1
        mountain.addChild(snowCap)
        
        // Add some rock texture lines
        for i in 0..<4 {
            let progress = CGFloat(i) / 4.0
            let lineY = -size.height/2 + (size.height * 0.7 * progress)
            let lineWidth = size.width * (1.0 - progress * 0.5)
            
            let rockLine = SKShapeNode(rectOf: CGSize(width: lineWidth, height: 2))
            rockLine.fillColor = UIColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 0.5)
            rockLine.strokeColor = .clear
            rockLine.position = CGPoint(x: 0, y: lineY)
            mountain.addChild(rockLine)
        }
        
        // Physics body - triangular
        let physicsPath = CGMutablePath()
        physicsPath.move(to: CGPoint(x: -size.width/2, y: -size.height/2))
        physicsPath.addLine(to: CGPoint(x: size.width/2, y: -size.height/2))
        physicsPath.addLine(to: CGPoint(x: 0, y: size.height/2))
        physicsPath.closeSubpath()
        
        let physicsBody = SKPhysicsBody(polygonFrom: physicsPath)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        mountain.physicsBody = physicsBody
        
        return mountain
    }
    
    // Create icicle hazards that hang from mountain peaks
    private func createIcicleHazard(near mountain: SKNode, at position: CGPoint) {
        let icicle = SKNode()
        icicle.name = "icicle_hazard"
        icicle.zPosition = 16
        
        // Create icicle shape (inverted triangle)
        let iciclePath = UIBezierPath()
        iciclePath.move(to: CGPoint(x: -8, y: 0))
        iciclePath.addLine(to: CGPoint(x: 8, y: 0))
        iciclePath.addLine(to: CGPoint(x: 0, y: -25))
        iciclePath.close()
        
        let icicleShape = SKShapeNode(path: iciclePath.cgPath)
        icicleShape.fillColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.9) // Ice blue
        icicleShape.strokeColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        icicleShape.lineWidth = 1
        icicle.addChild(icicleShape)
        
        // Position icicle hanging from near the peak
        icicle.position = CGPoint(x: position.x + CGFloat.random(in: -20...20), 
                                 y: position.y + CGFloat.random(in: 40...80))
        
        // Physics body
        let physics = SKPhysicsBody(polygonFrom: iciclePath.cgPath)
        physics.isDynamic = false
        physics.categoryBitMask = obstacleCategory
        physics.contactTestBitMask = playerCategory
        physics.collisionBitMask = 0
        icicle.physicsBody = physics
        
        // Add slight swaying motion
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.05, duration: 1.5),
            SKAction.rotate(byAngle: -0.1, duration: 3.0),
            SKAction.rotate(byAngle: 0.05, duration: 1.5)
        ])
        icicle.run(SKAction.repeatForever(sway))
        
        addChild(icicle)
        
        // Move with same speed as obstacles
        let move = SKAction.moveTo(x: -100, duration: TimeInterval((size.width + 200) / obstacleSpeed))
        icicle.run(SKAction.sequence([move, .removeFromParent()]))
    }
    
    // Create underwater rock obstacles (rounded, seaweed-covered)
    private func createUnderwaterRock(size: CGSize, position: CGPoint) -> SKNode {
        let rock = SKSpriteNode(color: .clear, size: size)
        rock.position = position
        rock.zPosition = 15
        rock.name = "obstacle"
        
        // Create rounded rock shape
        let rockPath = UIBezierPath(roundedRect: CGRect(x: -size.width/2, y: -size.height/2, 
                                                        width: size.width, height: size.height), 
                                    cornerRadius: size.width * 0.3)
        
        let rockShape = SKShapeNode(path: rockPath.cgPath)
        rockShape.fillColor = UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0) // Dark brown rock
        rockShape.strokeColor = UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0)
        rockShape.lineWidth = 2
        rock.addChild(rockShape)
        
        // Add seaweed on top
        for _ in 0..<3 {
            let seaweedX = CGFloat.random(in: -size.width/3...size.width/3)
            let seaweed = SKShapeNode(rectOf: CGSize(width: 4, height: 20), cornerRadius: 2)
            seaweed.fillColor = UIColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 0.8) // Green seaweed
            seaweed.strokeColor = .clear
            seaweed.position = CGPoint(x: seaweedX, y: size.height/2 + 10)
            
            // Animate seaweed swaying
            let sway = SKAction.sequence([
                SKAction.rotate(byAngle: 0.1, duration: 2.0),
                SKAction.rotate(byAngle: -0.2, duration: 4.0),
                SKAction.rotate(byAngle: 0.1, duration: 2.0)
            ])
            seaweed.run(SKAction.repeatForever(sway))
            rock.addChild(seaweed)
        }
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        rock.physicsBody = physicsBody
        
        return rock
    }
    
    // Create coral reef obstacles (colorful, branching)
    private func createCoralReef(size: CGSize, position: CGPoint) -> SKNode {
        let reef = SKSpriteNode(color: .clear, size: size)
        reef.position = position
        reef.zPosition = 15
        reef.name = "obstacle"
        
        // Main coral body
        let coralPath = UIBezierPath(roundedRect: CGRect(x: -size.width/2, y: -size.height/2, 
                                                         width: size.width, height: size.height), 
                                     cornerRadius: size.width * 0.2)
        
        let coralShape = SKShapeNode(path: coralPath.cgPath)
        // Random coral colors
        let colors = [
            UIColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 0.9), // Coral red
            UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.9), // Orange
            UIColor(red: 0.9, green: 0.3, blue: 0.6, alpha: 0.9), // Pink
            UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 0.9)  // Purple
        ]
        coralShape.fillColor = colors.randomElement()!
        coralShape.strokeColor = coralShape.fillColor.darker(by: 0.2)
        coralShape.lineWidth = 2
        reef.addChild(coralShape)
        
        // Add coral branches
        for i in 0..<4 {
            let branchHeight = CGFloat.random(in: 15...25)
            let branchX = CGFloat(i - 2) * (size.width / 5)
            
            let branch = SKShapeNode(ellipseOf: CGSize(width: 8, height: branchHeight))
            branch.fillColor = coralShape.fillColor
            branch.strokeColor = .clear
            branch.position = CGPoint(x: branchX, y: size.height/2 + branchHeight/2 - 5)
            reef.addChild(branch)
        }
        
        // Add some small fish swimming around
        if Bool.random() {
            let fish = SKShapeNode(ellipseOf: CGSize(width: 12, height: 6))
            fish.fillColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9) // Yellow fish
            fish.strokeColor = .clear
            fish.position = CGPoint(x: CGFloat.random(in: -20...20), 
                                   y: CGFloat.random(in: -10...10))
            
            // Simple swimming animation
            let swim = SKAction.sequence([
                SKAction.moveBy(x: 15, y: 5, duration: 2.0),
                SKAction.moveBy(x: -15, y: -5, duration: 2.0)
            ])
            fish.run(SKAction.repeatForever(swim))
            reef.addChild(fish)
        }
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        reef.physicsBody = physicsBody
        
        return reef
    }
    
    private func spawnPowerUp() {
        // Only spawn power-ups during gameplay
        guard isGameStarted && !isGameOver else { return }
        
        // Get a random power-up type
        let powerUpType = powerUpManager.getRandomPowerUpType()
        
        // Calculate position for power-up that doesn't collide with obstacles
        let xPos = size.width + 40
        let safeSpawnDistance: CGFloat = 100.0 // Distance from obstacles where power-ups can spawn safely (reduced to be more strict)
        
        // Find a safe position for the power-up
        var yPos = CGFloat.random(in: 150...(size.height - 150))
        var isSafe = false
        var attempts = 0
        let maxAttempts = 10 // More attempts to find safe position
        
        // Get all obstacles in the scene and their bounding boxes
        var obstacles: [(node: SKNode, frame: CGRect)] = []
        enumerateChildNodes(withName: "obstacle") { node, _ in
            // Convert node frame to scene coordinates
            let frame = node.calculateAccumulatedFrame()
            obstacles.append((node: node, frame: frame))
        }
        
        // Try multiple times to find a safe position
        while !isSafe && attempts < maxAttempts {
            isSafe = true
            attempts += 1
            
            // Create a test frame for the power-up (30x30 is typical size)
            let testFrame = CGRect(x: xPos - 15, y: yPos - 15, width: 30, height: 30)
            
            // Check collision with all obstacles
            for obstacle in obstacles {
                // Only consider obstacles ahead of the player (right side of screen)
                if obstacle.node.position.x > size.width * 0.4 {
                    // Check if frames intersect or are too close
                    let obstacleFrame = obstacle.frame.insetBy(dx: -safeSpawnDistance, dy: -safeSpawnDistance)
                    if testFrame.intersects(obstacleFrame) {
                        isSafe = false
                        break
                    }
                }
            }
            
            if isSafe {
                // Found safe position - Debug info
                print("Safe position found at y: \(yPos) after \(attempts) attempts")
                break
            }
            
            // Try a new random position with better distribution
            yPos = CGFloat.random(in: 100...(size.height - 100))
        }
        
        // If no safe position found after all attempts, try middle of screen
        if !isSafe {
            print("No safe position found, using center area")
            yPos = size.height / 2 + CGFloat.random(in: -50...50)
        }
        
        // Create power-up sprite at the position
        let position = CGPoint(x: xPos, y: yPos)
        let powerUpNode = powerUpManager.createPowerUpSprite(ofType: powerUpType, at: position)
        powerUpNode.zPosition = 25
        addChild(powerUpNode)
        
        // Animate power-up movement
        let moveAction = SKAction.moveBy(x: -(size.width + 120), y: 0, duration: TimeInterval(size.width / obstacleSpeed))
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])
        
        powerUpNode.run(sequence)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if !isGameStarted {
            // Start the game on first touch
            startGame()
        } else if isGameOver {
            // Check for main menu button touch
            if let mainMenuButton = childNode(withName: "mainMenuButton"),
               mainMenuButton.contains(location) {
                // Go back to main menu
                returnToMainMenu()
                return
            }
            
            // Restart the game if it's over
            restartGame()
        } else {
            // Apply impulse for jump if game is running
            jump()
        }
    }
    
    private func returnToMainMenu() {
        // Clean up current scene
        powerUpManager.resetAllPowerUps(in: self)
        
        // Create transition
        let transition = SKTransition.fade(withDuration: 0.5)
        
        // Create the main menu scene with the same size as current scene
        let mainMenuScene = MainMenuScene(size: size)
        
        // Present the main menu scene
        view?.presentScene(mainMenuScene, transition: transition)
    }
    
    private func jump() {
        // Reset any existing velocity
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        // Apply impulse for jump - reduced from 20 to 12 for better control
        let jumpImpulse = CGVector(dx: 0, dy: 12)
        player.physicsBody?.applyImpulse(jumpImpulse)
        
        // Play jump sound
        audioManager.playEffect(.jump)
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameStarted && !isGameOver else { return }
        
        // Calculate elapsed time
        _ = currentTime - gameStartTime
        
        // Check player bounds
        let playerY = player.position.y
        if playerY > size.height || playerY < 0 {
            gameOver()
        }
        
        // Update game time
        gameTime = Date().timeIntervalSince1970 - gameStartTime
    }
    
    // MARK: - Physics Contact
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Determine which bodies collided
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Handle collisions based on category
        if firstBody.categoryBitMask == playerCategory && secondBody.categoryBitMask == obstacleCategory {
            // Player hit obstacle
            handlePlayerObstacleCollision(obstacle: secondBody.node)
        } else if firstBody.categoryBitMask == playerCategory && secondBody.categoryBitMask == scoreCategory {
            // Player passed through score node
            handlePlayerScoreCollision(scoreNode: secondBody.node)
        } else if firstBody.categoryBitMask == playerCategory && secondBody.categoryBitMask == groundCategory {
            // Player hit ground
            gameOver()
        } else if firstBody.categoryBitMask == playerCategory && secondBody.categoryBitMask == powerUpCategory {
            // Player collected power-up
            handlePlayerPowerUpCollision(powerUpNode: secondBody.node)
        }
    }
    
    private func handlePlayerObstacleCollision(obstacle: SKNode?) {
        // Check if player hit a stargate portal (special desert level obstacle)
        if let portalNode = obstacle, portalNode.name == "stargate_portal" {
            // Player is sucked into the portal - custom game over
            gameOverWithStargate(portal: portalNode)
            return
        }
        
        // Check for speed boost (which makes the player invincible)
        if powerUpManager.isSpeedBoostActive {
            // Obstacle is destroyed by speed boost
            let flash = SKAction.sequence([
                SKAction.colorize(with: .yellow, colorBlendFactor: 0.9, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.2)
            ])
            let explosion = SKAction.run {
                // Create explosion effect
                let explosion = SKEmitterNode()
                explosion.position = obstacle?.position ?? .zero
                explosion.zPosition = 30
                explosion.particleBirthRate = 100
                explosion.numParticlesToEmit = 20
                explosion.particleLifetime = 0.5
                explosion.particleSpeed = 50
                explosion.particleSpeedRange = 30
                explosion.particleColor = .yellow
                explosion.particleAlpha = 0.8
                explosion.particleAlphaSpeed = -1.0
                explosion.particleScale = 0.5
                explosion.particleScaleRange = 0.3
                explosion.emissionAngle = 0
                explosion.emissionAngleRange = CGFloat.pi * 2
                self.addChild(explosion)
                
                // Remove explosion after animation
                let waitAction = SKAction.wait(forDuration: 0.5)
                explosion.run(SKAction.sequence([waitAction, SKAction.removeFromParent()]))
            }
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([flash, explosion, remove])
            obstacle?.run(sequence)
            
            // Award points for destroying the obstacle (only if it hasn't been scored yet)
            if let obstacle = obstacle, obstacle.name == "obstacle" {
                // Award points - obstacles should only be counted once
                obstacle.name = "scoredObstacle" // Mark as scored
                score += 1
                updateScore()
                
                // Add visual feedback
                addScoreFeedback(at: obstacle.position)
            }
            
            return
        }
        
        // Check for ghost mode
        if powerUpManager.isGhostActive {
            // For ghost mode, do nothing - we pass through obstacles
            // Add ghostly shimmer effect when passing through
            let ghostShimmer = SKEmitterNode()
            ghostShimmer.position = obstacle?.position ?? .zero
            ghostShimmer.zPosition = 30
            ghostShimmer.particleBirthRate = 50
            ghostShimmer.numParticlesToEmit = 10
            ghostShimmer.particleLifetime = 0.3
            ghostShimmer.particleSpeed = 20
            ghostShimmer.particleSpeedRange = 10
            ghostShimmer.particleColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.3)
            ghostShimmer.particleAlpha = 0.3
            ghostShimmer.particleAlphaSpeed = -1.0
            ghostShimmer.particleScale = 0.3
            addChild(ghostShimmer)
            
            // Remove shimmer after animation
            let waitAction = SKAction.wait(forDuration: 0.5)
            ghostShimmer.run(SKAction.sequence([waitAction, SKAction.removeFromParent()]))
            return
        }
        
        // Check for regular invincibility from shield (extra life)
        if isInvincible {
            // If player is invincible, reduce the counter and flash the obstacle
            invincibilityCount -= 1
            
            // Flash the obstacle
            let flash = SKAction.sequence([
                SKAction.colorize(with: .cyan, colorBlendFactor: 0.8, duration: 0.1),
                SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
            ])
            obstacle?.run(flash)
            
            // Show hit count (extra life protection)
            showTemporaryMessage("Extra life active: \(invincibilityCount) left")
            
            // Check if invincibility is over
            if invincibilityCount <= 0 {
                isInvincible = false
                // Remove the revival shield indicator created during extra life usage
                player.childNode(withName: "revivalShield")?.removeFromParent()
            }
            
            return
        }
        
        // Check if the player has an active shield from PowerUpManager
        if powerUpManager.isShieldActive {
            // Try to absorb hit with shield
            if powerUpManager.shieldHit() {
                // Shield hit success
                
                // Flash the obstacle
                let flash = SKAction.sequence([
                    SKAction.colorize(with: .blue, colorBlendFactor: 0.8, duration: 0.1),
                    SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
                ])
                obstacle?.run(flash)
                
                // Show shield hit message with remaining hits
                let hitCount = powerUpManager.shopShieldHitCount > 0 ? powerUpManager.shopShieldHitCount : 0
                if hitCount > 0 {
                    showTemporaryMessage("Shield hit! \(hitCount) left")
                } else {
                    showTemporaryMessage("Shield broken!")
                }
                
                return
            }
            // If shieldHit returned false, continue to next check
        }
        
        // If player has an extra life, use it
        if powerUpManager.hasExtraLife {
            useExtraLife()
            return
        }
        
        // If not protected by any power-up, game over
        gameOver()
    }
    
    private func gameOverWithStargate(portal: SKNode) {
        guard isGameStarted && !isGameOver else { return }
        
        isGameOver = true
        isGameStarted = false
        
        // Stop obstacle and power-up spawning
        removeAction(forKey: "spawnObstacles")
        removeAction(forKey: "spawnPowerUps")
        
        // Animate player being sucked into the stargate
        if let player = childNode(withName: "player") {
            // Create path from player to portal
            let playerPosition = player.position
            let portalPosition = portal.convert(CGPoint.zero, to: self)
            
            // Create a slight curve in the path for more natural movement
            let controlPoint = CGPoint(
                x: playerPosition.x + (portalPosition.x - playerPosition.x) / 2,
                y: playerPosition.y + (portalPosition.y - playerPosition.y) / 2 + 30
            )
            
            let path = UIBezierPath()
            path.move(to: playerPosition)
            path.addQuadCurve(to: portalPosition, controlPoint: controlPoint)
            
            // Move player along path
            let followPath = SKAction.follow(path.cgPath, asOffset: false, orientToPath: true, duration: 0.7)
            
            // Scale player down as it approaches portal
            let scaleDown = SKAction.scale(to: 0.1, duration: 0.7)
            
            // Group these actions
            let moveToPortal = SKAction.group([followPath, scaleDown])
            
            // After reaching portal, remove player
            let removePlayer = SKAction.removeFromParent()
            
            // Run sequence
            player.run(SKAction.sequence([moveToPortal, removePlayer])) {
                // After player is removed, show special game over message
                self.showStargateGameOver()
            }
            
            // Play portal sound effect - use collect sound for now
            audioManager.playEffect(.collect)
            
            // Add particles around player while being sucked in
            let suckEffect = SKEmitterNode()
            suckEffect.position = player.position
            suckEffect.particleBirthRate = 60
            suckEffect.particleLifetime = 0.7
            suckEffect.particleSpeed = 30
            suckEffect.particleSpeedRange = 20
            suckEffect.particleColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.7)
            // Create a temporary target node instead of using the portal directly
            let targetNode = SKNode()
            targetNode.position = portal.convert(CGPoint.zero, to: self)
            targetNode.name = "tempTargetNode"
            addChild(targetNode)
            suckEffect.targetNode = targetNode
            suckEffect.particleAction = SKAction.move(to: CGPoint.zero, duration: 0.7)
            addChild(suckEffect)
            
            // Remove the effect and temporary target after a delay
            let waitAction = SKAction.wait(forDuration: 1.0)
            suckEffect.run(SKAction.sequence([waitAction, SKAction.removeFromParent()]))
            targetNode.run(SKAction.sequence([SKAction.wait(forDuration: 1.5), SKAction.removeFromParent()]))
            
            // Enhance portal visuals
            portal.run(SKAction.scale(by: 1.5, duration: 0.5))
            portal.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.7),
                SKAction.group([
                    SKAction.scale(to: 2.0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        } else {
            // If player node not found, show game over immediately
            showStargateGameOver()
        }
    }
    
    private func showStargateGameOver() {
        // Show custom game over message
        let gameOverLabel = SKLabelNode(text: "Lost in The Abyss!")
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = UIColor(red: 0.0, green: 0.5, blue: 0.9, alpha: 1.0) // Blue color
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 60)
        gameOverLabel.zPosition = 100
        gameOverLabel.alpha = 0
        addChild(gameOverLabel)
        
        // Show final score
        let finalScoreLabel = SKLabelNode(text: "Final Score: \(score)")
        finalScoreLabel.fontName = "AvenirNext-Bold"
        finalScoreLabel.fontSize = 30
        finalScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        finalScoreLabel.zPosition = 100
        finalScoreLabel.alpha = 0
        addChild(finalScoreLabel)
        
        // Create Restart button (similar to Main Menu button but green)
        let restartButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 10)
        restartButton.fillColor = UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 0.8) // Green color
        restartButton.strokeColor = UIColor.white
        restartButton.lineWidth = 2
        restartButton.position = CGPoint(x: size.width/2, y: size.height/2 - 40)
        restartButton.zPosition = 100
        restartButton.alpha = 0
        restartButton.name = "restartButton"
        
        let restartLabel = SKLabelNode(text: "Restart")
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontSize = 22
        restartLabel.fontColor = UIColor.white
        restartLabel.verticalAlignmentMode = .center
        restartLabel.horizontalAlignmentMode = .center
        restartLabel.position = CGPoint(x: 0, y: 0)
        restartButton.addChild(restartLabel)
        
        addChild(restartButton)
        
        // Add Main Menu button
        let mainMenuButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 10)
        mainMenuButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 0.8)
        mainMenuButton.strokeColor = UIColor.white
        mainMenuButton.lineWidth = 2
        mainMenuButton.position = CGPoint(x: size.width/2, y: size.height/2 - 100)
        mainMenuButton.zPosition = 100
        mainMenuButton.alpha = 0
        mainMenuButton.name = "mainMenuButton"
        
        let mainMenuLabel = SKLabelNode(text: "Main Menu")
        mainMenuLabel.fontName = "AvenirNext-Bold"
        mainMenuLabel.fontSize = 22
        mainMenuLabel.fontColor = UIColor.white
        mainMenuLabel.verticalAlignmentMode = .center
        mainMenuLabel.horizontalAlignmentMode = .center
        mainMenuLabel.position = CGPoint(x: 0, y: 0)
        mainMenuButton.addChild(mainMenuLabel)
        
        addChild(mainMenuButton)
        
        // Fade in all elements with a slight delay between them
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        
        gameOverLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), fadeIn]))
        finalScoreLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.8), fadeIn]))
        restartButton.run(SKAction.sequence([SKAction.wait(forDuration: 1.1), fadeIn]))
        mainMenuButton.run(SKAction.sequence([SKAction.wait(forDuration: 1.4), fadeIn]))
        
        // Update per-map high score if needed
        if let levelId = self.levelId ?? currentLevel?.id {
            let currentBest = PlayerData.shared.mapHighScores[levelId] ?? 0
            if score > currentBest {
                _ = PlayerData.shared.updateMapHighScore(score, for: levelId)
                highScoreLabel.text = "Best: \(score)"
            }
        } else {
            // Fallback to global if no level context
            let currentHighScore = UserDefaults.standard.integer(forKey: "highScore")
            if score > currentHighScore {
                UserDefaults.standard.set(score, forKey: "highScore")
                highScoreLabel.text = "Best: \(score)"
            }
        }
        
        // Add subtle stargate background effect
        let stargateBackground = SKNode()
        stargateBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        stargateBackground.zPosition = 90
        
        // Add starfield particles
        let starfield = SKEmitterNode()
        starfield.particleBirthRate = 5
        starfield.particleLifetime = 5.0
        starfield.particleSpeed = 20
        starfield.particleSpeedRange = 10
        starfield.particleAlpha = 0.3
        starfield.particleAlphaSpeed = -0.1
        starfield.particleScale = 0.1
        starfield.particleScaleRange = 0.05
        starfield.particleColor = .cyan
        starfield.emissionAngle = 0
        starfield.emissionAngleRange = CGFloat.pi * 2
        stargateBackground.addChild(starfield)
        
        addChild(stargateBackground)
    }
    
    private func handlePlayerScoreCollision(scoreNode: SKNode?) {
        // Ensure scoreNode is valid, still in the scene, and not already processed
        guard let validNode = scoreNode, 
              validNode.parent != nil,
              validNode.name != "processedScoreNode" else { return }
        
        // Track distance for challenges
        distance += 1
        playerData.updateChallengeProgress(id: "distance", value: distance)
        
        // Immediately mark this score node as processed to prevent double counting
        // This is critical to do before any other processing
        validNode.name = "processedScoreNode"
        
        // Always increment score by 1 (or multiplier if active)
        score += 1 * (powerUpManager.scoreMultiplier)
        
        // Update score label
        updateScore()
        
        // Add visual feedback for score
        addScoreFeedback(at: validNode.position)
        
        // Remove score node to prevent further collisions
        validNode.removeFromParent()
        
        // Play score sound
        audioManager.playEffect(.collect)
        
        // Update daily challenges
        playerData.updateChallengeProgress(id: "score", value: score)
        
        // Debug output
        print("Score increased to: \(score) at distance: \(distance)")
    }
    
    // Add visual feedback when scoring
    private func addScoreFeedback(at position: CGPoint) {
        // Create "+1" text that floats up and fades out
        // Always show next to the player for better visibility
        let scoreText = SKLabelNode(text: "+\(powerUpManager.scoreMultiplier)")
        scoreText.fontName = "AvenirNext-Bold"
        scoreText.fontSize = 20
        scoreText.fontColor = .yellow
        
        // Position near the player for better visibility
        if let player = childNode(withName: "player") {
            scoreText.position = CGPoint(x: player.position.x + 40, y: player.position.y)
        } else {
            scoreText.position = position
        }
        
        scoreText.zPosition = 100 // Above most game elements
        addChild(scoreText)
        
        // Animate the score text
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.6)
        let fade = SKAction.fadeOut(withDuration: 0.6)
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])
        let group = SKAction.group([moveUp, fade, scale])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])
        scoreText.run(sequence)
    }
    
    private func handlePlayerPowerUpCollision(powerUpNode: SKNode?) {
        guard let powerUpNode = powerUpNode,
              let powerUpTypeString = powerUpNode.userData?.value(forKey: "type") as? String,
              let powerUpType = PowerUpManager.PowerUpType(rawValue: powerUpTypeString) else {
            return
        }
        
        // Debug output - helpful for troubleshooting
        print("Collected power-up: \(powerUpType.rawValue)")
        
        // Apply power-up effect - make sure to pass the player node and scene
        if powerUpManager.applyPowerUp(type: powerUpType, to: player, in: self) {
            // Show power-up message
            showPowerUpMessage(for: powerUpType)
            
            // Play power-up sound
            audioManager.playEffect(.collect)
            
            // Track power-up collection
            playerData.recordPowerUpCollected()
            playerData.updateChallengeProgress(id: "powerups", value: playerData.totalPowerUpsCollected)
            
            // Animate power-up collection
            let scaleAction = SKAction.scale(to: 1.5, duration: 0.2)
            let fadeAction = SKAction.fadeOut(withDuration: 0.2)
            let removeAction = SKAction.removeFromParent()
            let sequence = SKAction.sequence([scaleAction, fadeAction, removeAction])
            powerUpNode.run(sequence)
            
            // Additional visual feedback
            let explosion = SKEmitterNode()
            explosion.position = powerUpNode.position
            explosion.zPosition = 30
            explosion.particleBirthRate = 100
            explosion.numParticlesToEmit = 20
            explosion.particleLifetime = 0.5
            explosion.particleSpeed = 50
            explosion.particleSpeedRange = 30
            explosion.particleColor = powerUpType.color
            explosion.particleAlpha = 0.8
            explosion.particleAlphaSpeed = -1.0
            explosion.particleScale = 0.5
            explosion.particleScaleRange = 0.3
            explosion.emissionAngle = 0
            explosion.emissionAngleRange = CGFloat.pi * 2
            addChild(explosion)
            
            // Remove explosion after animation
            let waitAction = SKAction.wait(forDuration: 0.5)
            explosion.run(SKAction.sequence([waitAction, SKAction.removeFromParent()]))
        }
    }
    
    private func showPowerUpMessage(for powerUpType: PowerUpManager.PowerUpType) {
        // Show the power-up message
        showTemporaryMessage(powerUpType.message)
        
        // Add countdown timer for timed power-ups if they have a positive duration
        if powerUpType.duration > 0 {
            // Get the actual duration (considering double time)
            let actualDuration = powerUpManager.isDoubleTimeActive ? 
                                 powerUpType.duration * 2 : 
                                 powerUpType.duration
                                 
            // Add a countdown timer
            startCountdownTimer(for: powerUpType, duration: actualDuration)
        }
    }
    
    private func showTemporaryMessage(_ message: String) {
        let messageLabel = SKLabelNode(text: message)
        messageLabel.fontName = "AvenirNext-Bold"
        messageLabel.fontSize = 24
        messageLabel.position = CGPoint(x: size.width/2, y: size.height - 100)
        messageLabel.zPosition = 100
        messageLabel.name = "temporaryMessage"
        addChild(messageLabel)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        
        messageLabel.alpha = 0
        messageLabel.run(sequence)
    }
    
    private func startCountdownTimer(for powerUpType: PowerUpManager.PowerUpType, duration: TimeInterval) {
        // Only add countdown for timed power-ups with reasonable durations
        guard duration >= 1 && duration <= 10 else { return }
        
        // Create countdown container
        let countdownNode = SKNode()
        countdownNode.name = "countdown_\(powerUpType.rawValue)"
        countdownNode.position = CGPoint(x: size.width/2, y: size.height - 130)
        countdownNode.zPosition = 100
        addChild(countdownNode)
        
        // Create countdown label
        let countdownLabel = SKLabelNode(text: "\(Int(duration))")
        countdownLabel.fontName = "AvenirNext-Bold"
        countdownLabel.fontSize = 20
        countdownLabel.fontColor = powerUpType.color
        countdownLabel.verticalAlignmentMode = .center
        countdownLabel.horizontalAlignmentMode = .center
        countdownLabel.position = CGPoint(x: -1, y: 0) // Slight adjustment for visual centering
        countdownLabel.name = "countValue"
        countdownNode.addChild(countdownLabel)
        
        // Add background circle
        let circle = SKShapeNode(circleOfRadius: 15)
        circle.fillColor = UIColor(white: 0.0, alpha: 0.5)
        circle.strokeColor = powerUpType.color
        circle.lineWidth = 2
        circle.zPosition = -1
        countdownNode.addChild(circle)
        
        // Create countdown sequence
        for i in 0..<Int(duration) {
            let number = Int(duration) - i
            let wait = SKAction.wait(forDuration: TimeInterval(i))
            let update = SKAction.run {
                countdownLabel.text = "\(number)"
                
                // Pulse animation
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ])
                countdownLabel.run(pulse)
            }
            
            countdownNode.run(SKAction.sequence([wait, update]))
        }
        
        // Fade in animation
        countdownNode.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        countdownNode.run(fadeIn)
        
        // Remove when done
        let waitForEnd = SKAction.wait(forDuration: duration)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        let endSequence = SKAction.sequence([waitForEnd, fadeOut, remove])
        countdownNode.run(endSequence)
    }
    
    // MARK: - Game State
    
    private func updateScore() {
        // Update score label with current score
        scoreLabel.text = "Score: \(score)"
        
        // Check for high score updates
        let currentHighScore = UserDefaults.standard.integer(forKey: "highScore")
        if score > currentHighScore {
            UserDefaults.standard.set(score, forKey: "highScore")
            highScoreLabel.text = "Best: \(score)"
        }
    }
    
    private func gameOver() {
        guard isGameStarted && !isGameOver else { return }
        
        isGameOver = true
        isGameStarted = false
        
        // Check if player has an extra life
        if powerUpManager.hasExtraLife {
            useExtraLife()
            return
        }
        
        // Stop speed boost if active
        if isSpeedBoostActive {
            isSpeedBoostActive = false
            audioManager.deactivateSpeedBoostMusic()
            
            // Remove rainbow effect
            if let player = childNode(withName: "player") {
                player.childNode(withName: "speedTrail")?.removeFromParent()
                
                player.enumerateChildNodes(withName: "*") { node, _ in
                    if let shape = node as? SKShapeNode {
                        shape.removeAction(forKey: "rainbowEffect")
                        // Remove any color tint effect
                    }
                }
            }
        }
        
        // Play crash sound
        audioManager.playEffect(.crash)
        
        // Stop obstacle and power-up spawning
        removeAction(forKey: "spawnObstacles")
        removeAction(forKey: "spawnPowerUps")
        
        // Show game over message
        let gameOverLabel = SKLabelNode(text: "Game Over!")
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 60)
        gameOverLabel.zPosition = 100
        gameOverLabel.alpha = 0
        addChild(gameOverLabel)
        
        // Show final score
        let finalScoreLabel = SKLabelNode(text: "Final Score: \(score)")
        finalScoreLabel.fontName = "AvenirNext-Bold"
        finalScoreLabel.fontSize = 30
        finalScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        finalScoreLabel.zPosition = 100
        finalScoreLabel.alpha = 0
        addChild(finalScoreLabel)
        
        // Create Restart button (similar to Main Menu button but green)
        let restartButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 10)
        restartButton.fillColor = UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 0.8) // Green color
        restartButton.strokeColor = UIColor.white
        restartButton.lineWidth = 2
        restartButton.position = CGPoint(x: size.width/2, y: size.height/2 - 40)
        restartButton.zPosition = 100
        restartButton.alpha = 0
        restartButton.name = "restartButton"
        
        let restartLabel = SKLabelNode(text: "Restart")
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontSize = 22
        restartLabel.fontColor = UIColor.white
        restartLabel.verticalAlignmentMode = .center
        restartLabel.horizontalAlignmentMode = .center
        restartLabel.position = CGPoint(x: 0, y: 0)
        restartButton.addChild(restartLabel)
        
        addChild(restartButton)
        
        // Add Main Menu button
        let mainMenuButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 10)
        mainMenuButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 0.8)
        mainMenuButton.strokeColor = UIColor.white
        mainMenuButton.lineWidth = 2
        mainMenuButton.position = CGPoint(x: size.width/2, y: size.height/2 - 100)
        mainMenuButton.zPosition = 100
        mainMenuButton.alpha = 0
        mainMenuButton.name = "mainMenuButton"
        
        let mainMenuLabel = SKLabelNode(text: "Main Menu")
        mainMenuLabel.fontName = "AvenirNext-Bold"
        mainMenuLabel.fontSize = 22
        mainMenuLabel.fontColor = UIColor.white
        mainMenuLabel.verticalAlignmentMode = .center
        mainMenuLabel.horizontalAlignmentMode = .center
        mainMenuLabel.position = CGPoint(x: 0, y: 0)
        mainMenuButton.addChild(mainMenuLabel)
        
        addChild(mainMenuButton)
        
        // Fade in game over UI
        let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
        gameOverLabel.run(fadeInAction)
        finalScoreLabel.run(fadeInAction)
        restartButton.run(fadeInAction)
        mainMenuButton.run(fadeInAction)
        
        // Update high score if needed
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        if score > highScore {
            UserDefaults.standard.set(score, forKey: "highScore")
            
            // Submit score to Game Center
            gameCenterManager.submitScore(score)
            
            // Also submit to map-specific leaderboard
            if let mapId = levelId ?? currentLevel?.id {
                gameCenterManager.submitMapScore(score, for: mapId)
            }
            
            // Show new high score message
            let newHighScoreLabel = SKLabelNode(text: "New High Score!")
            newHighScoreLabel.fontName = "AvenirNext-Bold"
            newHighScoreLabel.fontSize = 28
            newHighScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 100)
            newHighScoreLabel.zPosition = 100
            newHighScoreLabel.alpha = 0
            addChild(newHighScoreLabel)
            
            // Add glow effect to high score message
            let glowAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.5),
                SKAction.fadeAlpha(to: 0.5, duration: 0.5)
            ])
            newHighScoreLabel.run(SKAction.repeatForever(glowAction))
        }
        
        // Record game statistics
        _ = playerData.updateHighScore(score)
        playerData.recordRunTime(gameTime)
        playerData.recordDeath()
        
        // Update level-specific high score if playing a level
        if let levelId = self.levelId {
            _ = playerData.updateMapHighScore(score, for: levelId)
            
            // Check for level unlocking
            _ = LevelData.unlockNextLevel(after: levelId, withScore: score)
        }
        
        // Award coins based on score
        let coinsEarned = CurrencyManager.shared.awardCoinsForScore(score)
        showTemporaryMessage("+ \(coinsEarned) Coins")
    }
    
    private func useExtraLife() {
        // Use the extra life
        _ = powerUpManager.useExtraLife()
        
        // Remove the heart indicator
        player.enumerateChildNodes(withName: "extraLifeIndicator") { node, _ in
            node.removeFromParent()
        }
        
        // Respawn the player at the same position but with a brief invincibility period
        player.physicsBody?.velocity = CGVector.zero
        
        // Make player temporarily invincible for ONE hit only (extra life semantics)
        isInvincible = true
        invincibilityCount = 1
        
        // Add temporary invincibility visual (different from shield)
        let revival = SKShapeNode(circleOfRadius: 30)
        revival.strokeColor = UIColor.red
        revival.lineWidth = 2
        revival.fillColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.15)
        revival.alpha = 0.7
        revival.name = "revivalShield" // Different name from regular shield
        
        // Animate revival shield
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 0.7, duration: 0.5)
        ])
        revival.run(SKAction.repeatForever(pulse))
        
        player.addChild(revival)
        
        // Show respawn message
        showTemporaryMessage("Extra Life Used!")
        
        // Continue game
        isGameStarted = true
        isGameOver = false
        
        // Track resurrection for achievements
        // Track player respawn with extra life
        playerData.recordResurrection()
    }
    
    private func restartGame() {
        // Remove all game over UI
        enumerateChildNodes(withName: "*") { node, _ in
            if node.zPosition == 100 {
                node.removeFromParent()
            }
        }
        
        // Remove all obstacles and power-ups
        enumerateChildNodes(withName: "obstacle") { node, _ in
            node.removeFromParent()
        }
        
        enumerateChildNodes(withName: "scoreNode") { node, _ in
            node.removeFromParent()
        }
        
        enumerateChildNodes(withName: "powerup") { node, _ in
            node.removeFromParent()
        }
        
        // Remove all player sprites to avoid duplicates
        enumerateChildNodes(withName: "player") { node, _ in
            node.removeFromParent()
        }
        
        // Clean up any stargate portal related nodes
        enumerateChildNodes(withName: "stargate_portal") { node, _ in
            node.removeFromParent()
        }
        
        enumerateChildNodes(withName: "tempTargetNode") { node, _ in
            node.removeFromParent()
        }
        
        // Remove any lingering hazards
        enumerateChildNodes(withName: "*_hazard") { node, _ in
            node.removeFromParent()
        }
        
        // Remove any emitter nodes (particle effects)
        enumerateChildNodes(withName: "//SKEmitterNode") { node, _ in
            node.removeFromParent()
        }
        
        // Clean up any nodes that might be in the middle of animations
        self.removeAllActions()
        self.removeAllChildren()
        
        // Reset game state
        isGameStarted = false
        isGameOver = false
        score = 0
        distance = 0
        isInvincible = false
        invincibilityCount = 0
        isSpeedBoostActive = false
        
        // Recreate the game scene elements
        setupGame()
        
        // Reset power-up states
        powerUpManager.resetAllPowerUps(in: self)
        
        // Reset extra life in UserDefaults
        UserDefaults.standard.set(false, forKey: "hasExtraLife")
        
        // Display tap to start message
        displayTapToStartMessage()
        
        // Reset physics world speed
        physicsWorld.speed = 1.0
    }
}