import SpriteKit
import GameKit

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
        setupGameElements()
        
        // Load level settings
        loadLevelSettings()
        
        // Apply map theme
        mapManager.applyTheme(to: self)
        
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
        ground.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0)
        ground.strokeColor = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
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
        // Get selected aircraft from CharacterManager
        player = characterManager.createAircraftSprite(for: characterManager.selectedAircraft)
        
        // Position player
        player.position = CGPoint(x: size.width * 0.3, y: size.height * 0.5)
        player.zPosition = 20
        
        // Make sure the physics body is set properly for the game
        if let physics = player.physicsBody {
            physics.affectedByGravity = false  // Start with no gravity until game begins
            physics.allowsRotation = false
            physics.categoryBitMask = playerCategory
            physics.contactTestBitMask = obstacleCategory | groundCategory | scoreCategory | powerUpCategory
            physics.collisionBitMask = obstacleCategory | groundCategory
        }
        
        addChild(player)
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
        
        // High score label
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        highScoreLabel = SKLabelNode(text: "Best: \(highScore)")
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
        // Variable removed to avoid warning
        
        // Adjust based on current level difficulty
        if let level = currentLevel {
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
        
        // Calculate gap position
        let gapPosition = CGFloat.random(in: 150...(size.height - 150))
        
        // Create top obstacle
        let topObstacleHeight = gapPosition - (gapHeight / 2)
        let topObstacle = createObstacle(size: CGSize(width: obstacleWidth, height: topObstacleHeight), position: CGPoint(x: size.width + 40, y: size.height - (topObstacleHeight / 2)))
        
        // Create bottom obstacle - always create it for proper Flappy Bird-style gaps
        let bottomObstacleY = gapPosition + (gapHeight / 2)
        let bottomObstacleHeight = size.height - bottomObstacleY
        let bottomObstacle = createObstacle(size: CGSize(width: obstacleWidth, height: bottomObstacleHeight), position: CGPoint(x: size.width + 40, y: bottomObstacleY + (bottomObstacleHeight / 2)))
        
        // Create score node in the gap
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: size.width + 40, y: gapPosition)
        
        let scorePhysics = SKPhysicsBody(rectangleOf: CGSize(width: 5, height: gapHeight))
        scorePhysics.isDynamic = false
        scorePhysics.categoryBitMask = scoreCategory
        scorePhysics.contactTestBitMask = playerCategory
        scorePhysics.collisionBitMask = 0 // Don't collide with anything
        scoreNode.physicsBody = scorePhysics
        scoreNode.name = "scoreNode"
        
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
        
        // Increment distance counter
        distance += 1
        playerData.recordDistance(1)
        
        // Update daily challenges
        playerData.updateChallengeProgress(id: "distance", value: distance)
        playerData.updateChallengeProgress(id: "obstacles", value: distance * 2) // 2 obstacles per spawn
    }
    
    private func createObstacle(size: CGSize, position: CGPoint) -> SKNode {
        // Create obstacle node
        let obstacle = SKSpriteNode(color: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0), size: size)
        obstacle.position = position
        obstacle.zPosition = 15
        obstacle.name = "obstacle"
        
        // Add some decoration to the obstacle
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
        
        // Create physics body
        let physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = playerCategory
        obstacle.physicsBody = physicsBody
        
        return obstacle
    }
    
    private func spawnPowerUp() {
        // Only spawn power-ups during gameplay
        guard isGameStarted && !isGameOver else { return }
        
        // Get a random power-up type
        let powerUpType = powerUpManager.getRandomPowerUpType()
        
        // Calculate position for power-up that doesn't collide with obstacles
        let xPos = size.width + 40
        let safeSpawnDistance: CGFloat = 200.0 // Distance from obstacles where power-ups can spawn safely
        
        // Find a safe position for the power-up
        var yPos = CGFloat.random(in: 150...(size.height - 150))
        var isSafe = false
        
        // Get all obstacles in the scene
        var obstaclePositions: [CGPoint] = []
        enumerateChildNodes(withName: "obstacle") { node, _ in
            obstaclePositions.append(node.position)
        }
        
        // Try up to 5 times to find a safe position
        for _ in 0..<5 {
            isSafe = true
            
            // Check distance from all obstacles
            for obstaclePos in obstaclePositions {
                // Only consider obstacles that are ahead of the player and in spawn area
                if obstaclePos.x > size.width * 0.4 {
                    let distance = hypot(xPos - obstaclePos.x, yPos - obstaclePos.y)
                    if distance < safeSpawnDistance {
                        isSafe = false
                        break
                    }
                }
            }
            
            if isSafe {
                break // Found a safe position
            }
            
            // Try a new random position
            yPos = CGFloat.random(in: 150...(size.height - 150))
        }
        
        // Create power-up sprite at the safe position
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
            
            // Award points for destroying the obstacle
            score += 1
            updateScore()
            
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
            
            // Show hit count
            showTemporaryMessage("Shield hit! \(invincibilityCount) left")
            
            // Check if invincibility is over
            if invincibilityCount <= 0 {
                isInvincible = false
                player.childNode(withName: "shield")?.removeFromParent()
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
    
    private func handlePlayerScoreCollision(scoreNode: SKNode?) {
        // Increment score
        score += 1 * (powerUpManager.scoreMultiplier)
        
        // Update score label
        updateScore()
        
        // Remove score node
        scoreNode?.removeFromParent()
        
        // Play score sound
        audioManager.playEffect(.collect)
        
        // Update daily challenges
        playerData.updateChallengeProgress(id: "score", value: score)
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
        // Update score label
        scoreLabel.text = "Score: \(score)"
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
        
        // Make player temporarily invincible
        isInvincible = true
        invincibilityCount = 3
        
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
        
        // Remove shield if present
        player.childNode(withName: "shield")?.removeFromParent()
        
        // Remove extra life indicator if present
        player.childNode(withName: "extraLifeIndicator")?.removeFromParent()
        
        // Reset game state
        isGameStarted = false
        isGameOver = false
        score = 0
        distance = 0
        isInvincible = false
        invincibilityCount = 0
        isSpeedBoostActive = false
        
        // Reset player position
        player.position = CGPoint(x: size.width * 0.3, y: size.height * 0.5)
        player.physicsBody?.velocity = CGVector.zero
        player.physicsBody?.affectedByGravity = false
        
        // Update score display
        updateScore()
        
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