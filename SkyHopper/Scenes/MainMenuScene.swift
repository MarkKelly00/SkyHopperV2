import SpriteKit
import GameKit

class MainMenuScene: SKScene {
    
    // UI elements
    private var playButton: SKShapeNode!
    private var characterButton: SKShapeNode!
    private var shopButton: SKShapeNode!
    private var settingsButton: SKShapeNode!
    private var profileButton: SKShapeNode!
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
    private var mapNameLabel: SKLabelNode!
    
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
        
        // Load player data after a small delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadPlayerData()
        }
        
        // Track daily login and check for challenges
        PlayerData.shared.trackDailyLogin()
        checkForDailyRewards()
        
        // Play menu music
        setupAudio()
    }
    
    // MARK: - Audio Setup
    
    private func setupAudio() {
        // Stop any currently playing music
        AudioManager.shared.stopBackgroundMusic()
        
        // Force menu soundtrack to play by setting the map theme to nil
        // This ensures we get the default menu music, not level-specific music
        AudioManager.shared.playMenuMusic()
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
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 148) // Lowered by 0.5rem (8 points) to prevent overlap with high score
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        // Create buttons
        createPlayButton()
        createCharacterButton()
        createShopButton()
        createSettingsButton()
        createProfileButton()
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
    
    private func createProfileButton() {
        // Place at the bottom of the screen with proper spacing
        profileButton = createSpecialButton(
            text: "PROFILE",
            position: CGPoint(x: size.width / 4, y: bottomY)
        )
        profileButton.name = "profileButton"
        addChild(profileButton)
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
        // Use safe area layout for currency display (similar to Score/Best labels)
        let safeArea = SafeAreaLayout(scene: self)
        let currencySafeTopY = safeArea.safeTopY(offset: -UIConstants.Spacing.medium) // Move up by 1rem for better fit
        
        // Coins display (left side of safe area)
        let coinsIcon = SKLabelNode(text: "🪙")
        coinsIcon.fontSize = 20
        coinsIcon.position = CGPoint(x: safeArea.safeLeftX() + 30, y: currencySafeTopY)
        addChild(coinsIcon)
        
        coinsLabel = SKLabelNode(text: "0")
        coinsLabel.fontName = "AvenirNext-Medium"
        coinsLabel.fontSize = 18
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: safeArea.safeLeftX() + 55, y: currencySafeTopY)
        addChild(coinsLabel)
        
        // Gems display (right side of safe area)
        let gemsIcon = SKLabelNode(text: "💎")
        gemsIcon.fontSize = 20
        gemsIcon.position = CGPoint(x: safeArea.safeRightX() - 55, y: currencySafeTopY)
        addChild(gemsIcon)
        
        gemsLabel = SKLabelNode(text: "0")
        gemsLabel.fontName = "AvenirNext-Medium"
        gemsLabel.fontSize = 18
        gemsLabel.horizontalAlignmentMode = .right
        gemsLabel.position = CGPoint(x: safeArea.safeRightX() - 30, y: currencySafeTopY)
        addChild(gemsLabel)
        
        // High score display - Two lines, centered
        let highScoreY = size.height - 81 // Move up by 0.25rem (4 points) for better spacing
        
        // First line: "High Score: XXX" 
        highScoreLabel = SKLabelNode(text: "High Score: 0")
        highScoreLabel.fontName = "AvenirNext-Medium"
        highScoreLabel.fontSize = 20
        highScoreLabel.horizontalAlignmentMode = .center
        highScoreLabel.position = CGPoint(x: size.width / 2, y: highScoreY)
        addChild(highScoreLabel)
        
        // Second line: "(Map Name)" - smaller font, centered below
        mapNameLabel = SKLabelNode(text: "")
        mapNameLabel.fontName = "AvenirNext-Medium"
        mapNameLabel.fontSize = 16  // Smaller than main score
        mapNameLabel.fontColor = UIColor.lightGray
        mapNameLabel.horizontalAlignmentMode = .center
        mapNameLabel.position = CGPoint(x: size.width / 2, y: highScoreY - 25) // 25 points below
        addChild(mapNameLabel)
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
        // Create animated craft for the main menu
        // If user selected Map Default, always show helicopter on main menu for clarity
        let selected = CharacterManager.shared.selectedAircraft
        let typeForMenu: CharacterManager.AircraftType = (selected == .mapDefault) ? .helicopter : selected
        helicopterNode = CharacterManager.shared.createAircraftSprite(for: typeForMenu)
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
        
        // Get highest score with map name
        let (score, mapName) = PlayerData.shared.getHighestScoreWithMapName()
        
        // Update the main score line (first line)
        if score > 0 {
            highScoreLabel.text = "High Score: \(score)"
        } else {
            highScoreLabel.text = "High Score: 0"
        }
        
        // Update the map name line (second line)
        if let mapName = mapName, score > 0 {
            mapNameLabel.text = "(\(mapName))"
            mapNameLabel.isHidden = false
        } else {
            mapNameLabel.text = ""
            mapNameLabel.isHidden = true
        }
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
                } else if node.name == "profileButton" || node.parent?.name == "profileButton" {
                    handleProfileButton()
                } else if node.name == "leaderboardButton" || node.parent?.name == "leaderboardButton" {
                    handleLeaderboardButton()
                }
            }
        }
    }
    
    private func handlePlayButton() {
        animateButtonPress(playButton) {
            // Always show level selection screen (instead of bypassing when only 1 map unlocked)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let block = SKAction.run { [weak self] in
                guard let self = self else { return }
                    self.transitionToMapSelection()
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
    
    private func handleProfileButton() {
        animateButtonPress(profileButton) {
            let transition = SKTransition.fade(withDuration: 0.5)
            let profileScene = ProfileSettingsScene(size: self.size)
            profileScene.scaleMode = .aspectFill
            self.view?.presentScene(profileScene, transition: transition)
        }
    }
    
    private func handleLeaderboardButton() {
        animateButtonPress(leaderboardButton) {
            // Use custom leaderboard scene instead of Game Center default
            let transition = SKTransition.fade(withDuration: 0.5)
            let leaderboardScene = ModernLeaderboardScene(size: self.size)
            leaderboardScene.scaleMode = .aspectFill
            self.view?.presentScene(leaderboardScene, transition: transition)
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
        // Transition to custom achievement scene
        let transition = SKTransition.fade(withDuration: 0.5)
        let achievementScene = AchievementScene(size: size)
        achievementScene.scaleMode = scaleMode
        view?.presentScene(achievementScene, transition: transition)
    }
}