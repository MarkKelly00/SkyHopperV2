import SpriteKit
import GameKit

class MainMenuScene: SKScene {
    
    // UI elements
    private var playButton: SKShapeNode!
    private var characterButton: SKShapeNode!
    private var shopButton: SKShapeNode!
    private var settingsButton: SKShapeNode!
    private var achievementsButton: SKShapeNode!
    private var leaderboardButton: SKShapeNode!
    
    // Layout constants
    private let bottomY: CGFloat = 80.0 // Y position for bottom row buttons
    
    // Special button design for bottom row buttons
    private func createSpecialButton(text: String, position: CGPoint) -> SKShapeNode {
        let buttonWidth = 170.0 // Smaller width for achievements/leaderboard buttons
        let buttonHeight = 50.0 // Smaller height too
        
        // Create button with light gray background
        let buttonNode = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        buttonNode.fillColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0) // #f0f0f0
        buttonNode.strokeColor = UIColor.lightGray
        buttonNode.lineWidth = 1.5
        buttonNode.position = position
        buttonNode.zPosition = 10
        
        // Add text with darker gray color
        let buttonLabel = SKLabelNode(text: text)
        buttonLabel.fontName = "AvenirNext-Medium" // Slightly thinner font
        buttonLabel.fontSize = 18 // Smaller font size
        buttonLabel.fontColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1.0) // #555555
        buttonLabel.position = CGPoint(x: 0, y: -6) // Vertically center
        buttonLabel.zPosition = 1
        buttonNode.addChild(buttonLabel)
        
        return buttonNode
    }
    
    // Player data
    private var coinsLabel: SKLabelNode!
    private var gemsLabel: SKLabelNode!
    private var highScoreLabel: SKLabelNode!
    
    // Animated elements
    private var helicopterNode: SKNode!
    private var cloudsNode: SKNode!
    
    // Game Center manager
    private var gameCenterManager: GameCenterManager!
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
        setupAnimations()
        loadPlayerData()
        
        // Initialize Game Center
        gameCenterManager = GameCenterManager()
        gameCenterManager.authenticatePlayer()
        
        // Register for currency updates
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(updateCurrencyDisplay),
            name: NSNotification.Name("CurrencyChanged"),
            object: nil
        )
        
        // Track daily login and check for challenges
        PlayerData.shared.trackDailyLogin()
        checkForDailyRewards()
    }
    
    // MARK: - Setup Methods
    
    private func setupScene() {
        // Set background color based on current map theme
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Add background elements
        addBackgroundElements()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(text: "Sky Hopper")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 50
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 140) // Moved down further to account for notch
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        // Create buttons
        createPlayButton()
        createCharacterButton()
        createShopButton()
        createSettingsButton()
        createAchievementsButton()
        createLeaderboardButton()
        
        // Create player data displays
        createPlayerDataDisplays()
    }
    
    private func createPlayButton() {
        playButton = createButton(text: "PLAY", color: .green, position: CGPoint(x: size.width / 2, y: size.height / 2))
        playButton.name = "playButton"
        addChild(playButton)
    }
    
    private func createCharacterButton() {
        characterButton = createButton(text: "CHARACTERS", color: .blue, position: CGPoint(x: size.width / 2, y: size.height / 2 - 80))
        characterButton.name = "characterButton"
        addChild(characterButton)
    }
    
    private func createShopButton() {
        shopButton = createButton(text: "SHOP", color: .orange, position: CGPoint(x: size.width / 2, y: size.height / 2 - 160))
        shopButton.name = "shopButton"
        addChild(shopButton)
    }
    
    private func createSettingsButton() {
        settingsButton = createButton(text: "SETTINGS", color: .gray, position: CGPoint(x: size.width / 2, y: size.height / 2 - 240))
        settingsButton.name = "settingsButton"
        addChild(settingsButton)
    }
    
    private func createAchievementsButton() {
        // Place at the bottom of the screen with proper spacing
        achievementsButton = createSpecialButton(
            text: "ACHIEVEMENTS",
            position: CGPoint(x: size.width / 4, y: bottomY)
        )
        achievementsButton.name = "achievementsButton"
        addChild(achievementsButton)
    }
    
    private func createLeaderboardButton() {
        // Place below the settings button with proper spacing
        leaderboardButton = createSpecialButton(
            text: "LEADERBOARD",
            position: CGPoint(x: size.width * 3 / 4, y: bottomY)
        )
        leaderboardButton.name = "leaderboardButton"
        addChild(leaderboardButton)
    }
    
    private func createPlayerDataDisplays() {
        // Coins display - moved down to account for notch
        let coinsIcon = SKLabelNode(text: "🪙")
        coinsIcon.fontSize = 24
        coinsIcon.position = CGPoint(x: 30, y: size.height - 80) // Moved further down
        addChild(coinsIcon)
        
        coinsLabel = SKLabelNode(text: "0")
        coinsLabel.fontName = "AvenirNext-Medium"
        coinsLabel.fontSize = 20
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: 50, y: size.height - 80) // Moved further down
        addChild(coinsLabel)
        
        // Gems display
        let gemsIcon = SKLabelNode(text: "💎")
        gemsIcon.fontSize = 24
        gemsIcon.position = CGPoint(x: 130, y: size.height - 80) // Moved further down
        addChild(gemsIcon)
        
        gemsLabel = SKLabelNode(text: "0")
        gemsLabel.fontName = "AvenirNext-Medium"
        gemsLabel.fontSize = 20
        gemsLabel.horizontalAlignmentMode = .left
        gemsLabel.position = CGPoint(x: 150, y: size.height - 80) // Moved further down
        addChild(gemsLabel)
        
        // High score display
        highScoreLabel = SKLabelNode(text: "HIGH SCORE: 0")
        highScoreLabel.fontName = "AvenirNext-Medium"
        highScoreLabel.fontSize = 20
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.position = CGPoint(x: size.width - 30, y: size.height - 80) // Moved further down
        addChild(highScoreLabel)
    }
    
    private func createButton(text: String, color: UIColor, position: CGPoint) -> SKShapeNode {
        let buttonWidth = 210.0 // Slightly smaller for better fit
        let buttonHeight = 60.0
        
        // Create button shape
        let buttonNode = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 15)
        buttonNode.fillColor = color
        buttonNode.strokeColor = UIColor.white
        buttonNode.lineWidth = 2
        buttonNode.position = position
        buttonNode.zPosition = 10
        
        // Add text to button
        let buttonLabel = SKLabelNode(text: text)
        buttonLabel.fontName = "AvenirNext-Bold"
        buttonLabel.fontSize = 24
        buttonLabel.fontColor = UIColor.white
        buttonLabel.position = CGPoint(x: 0, y: -8) // Vertically center
        buttonLabel.zPosition = 1
        buttonNode.addChild(buttonLabel)
        
        return buttonNode
    }
    
    private func addBackgroundElements() {
        // Add clouds
        cloudsNode = SKNode()
        cloudsNode.zPosition = -5
        addChild(cloudsNode)
        
        for _ in 0..<10 {
            let cloud = createCloud()
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            cloudsNode.addChild(cloud)
        }
        
        // Add ground
        let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: 60))
        ground.fillColor = MapManager.shared.currentMap.groundColor
        ground.strokeColor = .clear
        ground.zPosition = 5
        addChild(ground)
    }
    
    private func createCloud() -> SKShapeNode {
        let cloudWidth = CGFloat.random(in: 60...120)
        let cloudHeight = cloudWidth * 0.6
        
        let cloud = SKShapeNode(ellipseOf: CGSize(width: cloudWidth, height: cloudHeight))
        cloud.fillColor = UIColor.white.withAlphaComponent(0.8)
        cloud.strokeColor = .clear
        
        // Add some randomness to cloud shape
        for _ in 0..<3 {
            let bubbleSize = cloudWidth * CGFloat.random(in: 0.4...0.7)
            let bubble = SKShapeNode(circleOfRadius: bubbleSize / 2)
            bubble.fillColor = UIColor.white.withAlphaComponent(0.8)
            bubble.strokeColor = .clear
            
            let xPos = CGFloat.random(in: -cloudWidth/3...cloudWidth/3)
            let yPos = CGFloat.random(in: -cloudHeight/3...cloudHeight/3)
            bubble.position = CGPoint(x: xPos, y: yPos)
            
            cloud.addChild(bubble)
        }
        
        // Add cloud movement
        let speed = CGFloat.random(in: 10...30)
        let moveLeft = SKAction.moveBy(x: -size.width - cloudWidth, y: 0, duration: TimeInterval(size.width / speed))
        let resetPosition = SKAction.moveTo(x: size.width + cloudWidth / 2, duration: 0)
        let sequence = SKAction.sequence([moveLeft, resetPosition])
        let forever = SKAction.repeatForever(sequence)
        
        cloud.run(forever)
        
        return cloud
    }
    
    private func setupAnimations() {
        // Create animated helicopter
        helicopterNode = CharacterManager.shared.createAircraftSprite(for: CharacterManager.shared.selectedAircraft)
        helicopterNode.position = CGPoint(x: size.width / 5, y: size.height * 2 / 3)
        helicopterNode.zPosition = 5
        helicopterNode.xScale = 1.5
        helicopterNode.yScale = 1.5
        addChild(helicopterNode)
        
        // Make helicopter float up and down
        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 1.0)
        let moveDown = SKAction.moveBy(x: 0, y: -20, duration: 1.0)
        let sequence = SKAction.sequence([moveUp, moveDown])
        let floating = SKAction.repeatForever(sequence)
        helicopterNode.run(floating)
    }
    
    private func loadPlayerData() {
        updateCurrencyDisplay()
        highScoreLabel.text = "HIGH SCORE: \(PlayerData.shared.highScore)"
    }
    
    @objc private func updateCurrencyDisplay() {
        coinsLabel.text = "\(CurrencyManager.shared.getCoins())"
        gemsLabel.text = "\(CurrencyManager.shared.getGems())"
    }
    
    private func checkForDailyRewards() {
        // Check for new daily challenges
        if let lastDate = PlayerData.shared.lastDailyChallengeDate, !Calendar.current.isDateInToday(lastDate) {
            PlayerData.shared.generateDailyChallenges()
            showDailyChallengeNotification()
        }
        
        // Check for consecutive day login rewards
        if UserDefaults.standard.bool(forKey: "showDailyLoginReward") {
            UserDefaults.standard.set(false, forKey: "showDailyLoginReward")
            showDailyLoginRewardNotification()
        }
    }
    
    private func showDailyChallengeNotification() {
        let notification = SKLabelNode(text: "New Daily Challenges Available!")
        notification.fontName = "AvenirNext-Bold"
        notification.fontSize = 24
        notification.fontColor = .white
        notification.position = CGPoint(x: size.width / 2, y: size.height - 160)
        notification.zPosition = 100
        
        let background = SKShapeNode(rect: CGRect(x: -200, y: -15, width: 400, height: 35), cornerRadius: 10)
        background.fillColor = UIColor(red: 0, green: 0.5, blue: 0.8, alpha: 0.8)
        background.strokeColor = .white
        background.lineWidth = 2
        background.zPosition = -1
        notification.addChild(background)
        
        addChild(notification)
        
        // Animate
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        notification.run(sequence)
    }
    
    private func showDailyLoginRewardNotification() {
        let day = UserDefaults.standard.integer(forKey: "consecutiveDaysStreak")
        let reward = UserDefaults.standard.integer(forKey: "lastLoginReward")
        
        let notification = SKLabelNode(text: "Day \(day) Login: +\(reward) Coins!")
        notification.fontName = "AvenirNext-Bold"
        notification.fontSize = 24
        notification.fontColor = .white
        notification.position = CGPoint(x: size.width / 2, y: size.height - 160)
        notification.zPosition = 100
        
        let background = SKShapeNode(rect: CGRect(x: -150, y: -15, width: 300, height: 35), cornerRadius: 10)
        background.fillColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 0.8)
        background.strokeColor = .white
        background.lineWidth = 2
        background.zPosition = -1
        notification.addChild(background)
        
        addChild(notification)
        
        // Animate
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        notification.run(sequence)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            for node in touchedNodes {
                if node.name == "playButton" || node.parent?.name == "playButton" {
                    handlePlayButton()
                } else if node.name == "characterButton" || node.parent?.name == "characterButton" {
                    handleCharacterButton()
                } else if node.name == "shopButton" || node.parent?.name == "shopButton" {
                    handleShopButton()
                } else if node.name == "settingsButton" || node.parent?.name == "settingsButton" {
                    handleSettingsButton()
                } else if node.name == "achievementsButton" || node.parent?.name == "achievementsButton" {
                    handleAchievementsButton()
                } else if node.name == "leaderboardButton" || node.parent?.name == "leaderboardButton" {
                    handleLeaderboardButton()
                }
            }
        }
    }
    
    private func handlePlayButton() {
        animateButtonPress(playButton) {
            // Show map selection or go directly to game
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let block = SKAction.run { [weak self] in
                guard let self = self else { return }
                if MapManager.shared.unlockedMaps.count > 1 {
                    self.transitionToMapSelection()
                } else {
                    self.startGame()
                }
            }
            let sequence = SKAction.sequence([fadeOut, block])
            self.run(sequence)
        }
    }
    
    private func handleCharacterButton() {
        animateButtonPress(characterButton) {
            self.transitionToCharacterSelection()
        }
    }
    
    private func handleShopButton() {
        animateButtonPress(shopButton) {
            self.transitionToShop()
        }
    }
    
    private func handleSettingsButton() {
        animateButtonPress(settingsButton) {
            self.transitionToSettings()
        }
    }
    
    private func handleAchievementsButton() {
        animateButtonPress(achievementsButton) {
            self.showAchievements()
        }
    }
    
    private func handleLeaderboardButton() {
        animateButtonPress(leaderboardButton) {
            self.gameCenterManager.showLeaderboard()
        }
    }
    
    private func animateButtonPress(_ button: SKShapeNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        
        button.run(sequence) {
            completion()
        }
    }
    
    // MARK: - Scene Transitions
    
    private func startGame() {
        // Direct transition to game scene
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        
        view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func transitionToMapSelection() {
        // Transition to level selection scene
        let levelScene = LevelSelectionScene(size: size)
        levelScene.scaleMode = scaleMode
        
        view?.presentScene(levelScene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func transitionToCharacterSelection() {
        // Transition to character selection scene
        let scene = CharacterSelectionScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func transitionToShop() {
        // Transition to shop scene
        let scene = ShopScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func transitionToSettings() {
        // Transition to settings scene
        let scene = SettingsScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func showAchievements() {
        // Show Game Center achievements
        gameCenterManager.showAchievements()
    }
}