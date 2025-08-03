import SpriteKit
import GameKit

class LevelSelectionScene: SKScene {
    
    // Level data
    private var levels: [LevelData] = []
    private var currentPage = 0
    private let levelsPerPage = 4
    
    // UI elements
    private var levelNodes: [SKNode] = []
    private var pageIndicator: SKLabelNode!
    private var prevButton: SKShapeNode!
    private var nextButton: SKShapeNode!
    private var backButton: SKShapeNode!
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        loadLevels()
        setupUI()
        setupLevelDisplay()
    }
    
    private func setupScene() {
        // Set background color based on current map theme
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Add background elements
        addCloudsBackground()
    }
    
    private func loadLevels() {
        // Load level data
        levels = LevelData.loadUnlockedLevels()
    }
    
    private func setupUI() {
        // Title - moved down to account for notch
        let titleLabel = SKLabelNode(text: "Select Level")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 40
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 140) // Moved even further down for notch
        addChild(titleLabel)
        
        // Page indicator
        pageIndicator = SKLabelNode(text: "Page 1/\(ceil(Double(levels.count) / Double(levelsPerPage)))")
        pageIndicator.fontName = "AvenirNext-Medium"
        pageIndicator.fontSize = 18
        pageIndicator.position = CGPoint(x: size.width / 2, y: 60)
        addChild(pageIndicator)
        
        // Navigation buttons
        createNavigationButtons()
        
        // Back button
        createBackButton()
    }
    
    private func createNavigationButtons() {
        // Previous page button
        prevButton = SKShapeNode(circleOfRadius: 30)
        prevButton.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.8)
        prevButton.strokeColor = .white
        prevButton.lineWidth = 2
        prevButton.position = CGPoint(x: 50, y: 60)
        prevButton.name = "prevButton"
        
        let prevLabel = SKLabelNode(text: "←")
        prevLabel.fontName = "AvenirNext-Bold"
        prevLabel.fontSize = 30
        prevLabel.verticalAlignmentMode = .center
        prevLabel.position = CGPoint(x: 0, y: 0)
        prevButton.addChild(prevLabel)
        addChild(prevButton)
        
        // Next page button
        nextButton = SKShapeNode(circleOfRadius: 30)
        nextButton.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.8)
        nextButton.strokeColor = .white
        nextButton.lineWidth = 2
        nextButton.position = CGPoint(x: size.width - 50, y: 60)
        nextButton.name = "nextButton"
        
        let nextLabel = SKLabelNode(text: "→")
        nextLabel.fontName = "AvenirNext-Bold"
        nextLabel.fontSize = 30
        nextLabel.verticalAlignmentMode = .center
        nextLabel.position = CGPoint(x: 0, y: 0)
        nextButton.addChild(nextLabel)
        addChild(nextButton)
        
        // Update button state
        updateNavigationButtons()
    }
    
    private func createBackButton() {
        backButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        backButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 0.8)
        backButton.strokeColor = .white
        backButton.lineWidth = 2
        backButton.position = CGPoint(x: 70, y: size.height - 80) // Moved down further for notch
        backButton.zPosition = 20 // Ensure it's above other elements
        backButton.name = "backButton"
        
        let backLabel = SKLabelNode(text: "Back")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 18
        backLabel.verticalAlignmentMode = .center
        backLabel.horizontalAlignmentMode = .center
        backLabel.position = CGPoint(x: 0, y: 0)
        backButton.addChild(backLabel)
        addChild(backButton)
    }
    
    private func setupLevelDisplay() {
        // Remove existing level nodes
        levelNodes.forEach { $0.removeFromParent() }
        levelNodes.removeAll()
        
        // Calculate start index and number of levels to display
        let startIndex = currentPage * levelsPerPage
        let endIndex = min(startIndex + levelsPerPage, levels.count)
        
        // Position variables with improved spacing
        let padding: CGFloat = 25 // More padding between cards
        let levelWidth: CGFloat = (size.width - (padding * 3)) / 2 
        let levelHeight: CGFloat = 210 // Increased height for better content fit
        
        // Create level cards
        for i in startIndex..<endIndex {
            let level = levels[i]
            let levelNode = createLevelNode(for: level, width: levelWidth, height: levelHeight)
            
            // Position in grid (2x2)
            let column = (i - startIndex) % 2
            let row = (i - startIndex) / 2
            
            let xPosition = padding + (CGFloat(column) * (levelWidth + padding)) + (levelWidth / 2)
            let yPosition = size.height - 160 - (CGFloat(row) * (levelHeight + padding)) - (levelHeight / 2)
            
            levelNode.position = CGPoint(x: xPosition, y: yPosition)
            addChild(levelNode)
            levelNodes.append(levelNode)
        }
        
        // Update page indicator
        let totalPages = max(1, Int(ceil(Double(levels.count) / Double(levelsPerPage))))
        pageIndicator.text = "Page \(currentPage + 1)/\(totalPages)"
    }
    
    private func createLevelNode(for level: LevelData, width: CGFloat, height: CGFloat) -> SKNode {
        let containerNode = SKNode()
        containerNode.name = "level_\(level.id)"
        
        // Background card
        let background = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 15)
        background.fillColor = level.mapTheme.backgroundColor
        background.strokeColor = .white
        background.lineWidth = 2
        background.name = "levelBackground"
        containerNode.addChild(background)
        
        // Add a semi-transparent panel behind text for better readability
        let textPanel = SKShapeNode(rectOf: CGSize(width: width - 10, height: height - 60), cornerRadius: 10)
        textPanel.fillColor = UIColor.black.withAlphaComponent(0.2)
        textPanel.strokeColor = UIColor.clear
        textPanel.position = CGPoint(x: 0, y: 10) // Slightly above center
        textPanel.zPosition = 1
        containerNode.addChild(textPanel)
        
        // Level title with improved contrast
        let titleLabel = SKLabelNode(text: level.name)
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 20
        titleLabel.fontColor = UIColor.white
        titleLabel.position = CGPoint(x: 0, y: height/2 - 30) // Moved up for more margin below
        titleLabel.preferredMaxLayoutWidth = width - 30 // Prevent text overflow
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 2
        titleLabel.numberOfLines = 2 // Allow title to wrap if needed
        containerNode.addChild(titleLabel)
        
        // Difficulty stars with improved spacing from title
        let starSpacing: CGFloat = 18 // Increased spacing
        let totalStarWidth = (starSpacing * CGFloat(level.difficulty - 1)) + (CGFloat(level.difficulty) * 18)
        var starX = -totalStarWidth / 2
        
        for _ in 0..<level.difficulty {
            let star = SKLabelNode(text: "⭐️")
            star.fontSize = 16 // Slightly larger
            star.verticalAlignmentMode = .center // Better vertical alignment
            star.position = CGPoint(x: starX + 9, y: height/2 - 75) // Moved down for more spacing from title
            star.zPosition = 2
            containerNode.addChild(star)
            starX += 18 + starSpacing
        }
        
        // Description with better positioning and readability
        let descLabel = SKLabelNode(text: level.description)
        descLabel.fontName = "AvenirNext-Medium"
        descLabel.fontSize = 14
        descLabel.fontColor = UIColor.white
        descLabel.preferredMaxLayoutWidth = width - 30
        descLabel.numberOfLines = 3 // Increase to 3 lines for longer descriptions
        descLabel.verticalAlignmentMode = .center
        descLabel.horizontalAlignmentMode = .center
        descLabel.position = CGPoint(x: 0, y: -10) // Moved down slightly
        descLabel.zPosition = 2
        containerNode.addChild(descLabel)
        
                // Removed colored map icon box as requested
        
        // High score with improved readability
        let highScore = PlayerData.shared.mapHighScores[level.id] ?? 0
        let scoreLabel = SKLabelNode(text: "Best: \(highScore)")
        scoreLabel.fontName = "AvenirNext-Medium"
        scoreLabel.fontSize = 14
        scoreLabel.fontColor = UIColor.white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: width/2 - 15, y: -height/2 + 35)
        scoreLabel.zPosition = 2
        containerNode.addChild(scoreLabel)
        
        // Handle locked/unlocked level styling
        if !level.isUnlocked {
            // Create a semi-transparent overlay for locked levels
            let lockOverlay = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 15)
            lockOverlay.fillColor = UIColor.black.withAlphaComponent(0.5)
            lockOverlay.strokeColor = UIColor.clear
            lockOverlay.zPosition = 5 // Above other elements
            lockOverlay.name = "lockOverlay"
            containerNode.addChild(lockOverlay)
            
            // Centered lock icon
            let lockIconBackground = SKShapeNode(circleOfRadius: 30)
            lockIconBackground.fillColor = UIColor.black.withAlphaComponent(0.7)
            lockIconBackground.strokeColor = UIColor.white
            lockIconBackground.lineWidth = 2
            lockIconBackground.position = CGPoint(x: 0, y: 0) // Center of card
            lockIconBackground.zPosition = 6
            containerNode.addChild(lockIconBackground)
            
            let lockIcon = SKLabelNode(text: "🔒")
            lockIcon.fontSize = 35
            lockIcon.verticalAlignmentMode = .center
            lockIcon.horizontalAlignmentMode = .center
            lockIcon.position = CGPoint(x: 0, y: 0)
            lockIcon.zPosition = 7
            lockIconBackground.addChild(lockIcon)
            
            // Show tap instruction for lock
            let tapForInfoLabel = SKLabelNode(text: "Tap for info")
            tapForInfoLabel.fontName = "AvenirNext-Medium"
            tapForInfoLabel.fontSize = 13
            tapForInfoLabel.fontColor = UIColor.white
            tapForInfoLabel.position = CGPoint(x: 0, y: -48) // Moved down for more space from lock
            tapForInfoLabel.zPosition = 8 // Increased z-index to be above everything
            tapForInfoLabel.name = "infoText" // Named for better hit detection
            containerNode.addChild(tapForInfoLabel)
            
            // Preserve the level info visibility
            titleLabel.alpha = 0.8
            descLabel.alpha = 0.5
            
            // Store the unlock requirement in userData but don't display it directly
            containerNode.userData = NSMutableDictionary()
            containerNode.userData?.setValue(level.unlockRequirement.description, forKey: "unlockRequirement")
            
        } else {
            // Unlocked level styling - make it pop more
            background.fillColor = background.fillColor.withAlphaComponent(1.0)
            background.strokeColor = UIColor.white
            
            // Add glow effect to unlocked levels
            let glow = SKEffectNode()
            let filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 4.0])
            glow.filter = filter
            glow.position = CGPoint(x: 0, y: 0)
            glow.zPosition = -1
            containerNode.addChild(glow)
            
            // Background shape for glow
            let glowShape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 15)
            glowShape.fillColor = UIColor.clear
            glowShape.strokeColor = UIColor.white.withAlphaComponent(0.7)
            glowShape.lineWidth = 4
            glow.addChild(glowShape)
            
            // Round play button icon at bottom of card
            let playButtonCircle = SKShapeNode(circleOfRadius: 30)
            playButtonCircle.fillColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 0.8) // Green play button
            playButtonCircle.strokeColor = UIColor.white
            playButtonCircle.lineWidth = 2
            playButtonCircle.position = CGPoint(x: 0, y: -height/2 + 50) // Position at bottom center
            playButtonCircle.zPosition = 4
            playButtonCircle.name = "playButton_\(level.id)" // Add ID to the button name
            containerNode.addChild(playButtonCircle)
            
            // Play icon (triangle)
            let playTriangle = SKShapeNode()
            let trianglePath = UIBezierPath()
            trianglePath.move(to: CGPoint(x: -8, y: -10))
            trianglePath.addLine(to: CGPoint(x: -8, y: 10))
            trianglePath.addLine(to: CGPoint(x: 12, y: 0))
            trianglePath.close()
            playTriangle.path = trianglePath.cgPath
            playTriangle.fillColor = UIColor.white
            playTriangle.strokeColor = UIColor.clear
            playTriangle.position = CGPoint(x: 2, y: 0) // Slight offset for visual centering
            playTriangle.name = "playIcon"
            playButtonCircle.addChild(playTriangle)
        }
        
        return containerNode
    }
    
    private func updateNavigationButtons() {
        let totalPages = max(1, Int(ceil(Double(levels.count) / Double(levelsPerPage))))
        
        // Enable/disable previous button
        prevButton.alpha = (currentPage > 0) ? 1.0 : 0.5
        
        // Enable/disable next button
        nextButton.alpha = (currentPage < totalPages - 1) ? 1.0 : 0.5
    }
    
    private func addCloudsBackground() {
        // Create several clouds
        for _ in 0..<8 {
            let cloudWidth = CGFloat.random(in: 80...180)
            let cloudHeight = cloudWidth * 0.6
            
            let cloud = SKShapeNode(ellipseOf: CGSize(width: cloudWidth, height: cloudHeight))
            cloud.fillColor = UIColor.white.withAlphaComponent(0.7)
            cloud.strokeColor = .clear
            
            // Random position
            let x = CGFloat.random(in: -20...(size.width + 20))
            let y = CGFloat.random(in: 100...(size.height - 100))
            cloud.position = CGPoint(x: x, y: y)
            cloud.zPosition = -10
            
            // Add some variation to the cloud
            for _ in 0..<3 {
                let bubbleSize = CGFloat.random(in: 20...60)
                let bubbleNode = SKShapeNode(circleOfRadius: bubbleSize)
                bubbleNode.fillColor = UIColor.white.withAlphaComponent(0.7)
                bubbleNode.strokeColor = .clear
                
                let offsetX = CGFloat.random(in: -cloudWidth/3...cloudWidth/3)
                let offsetY = CGFloat.random(in: -cloudHeight/3...cloudHeight/3)
                bubbleNode.position = CGPoint(x: offsetX, y: offsetY)
                
                cloud.addChild(bubbleNode)
            }
            
            // Slow animation
            let moveLeft = SKAction.moveBy(x: -cloudWidth, y: 0, duration: TimeInterval(20 + Double.random(in: 0...10)))
            let moveReset = SKAction.moveBy(x: size.width + 2 * cloudWidth, y: 0, duration: 0)
            let moveSequence = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveSequence)
            
            cloud.run(moveForever)
            addChild(cloud)
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            for node in touchedNodes {
                // Check for popup buttons first (highest priority)
                if node.name == "closePopup" || node.parent?.name == "closePopup" {
                    AudioManager.shared.playEffect(.menuTap)
                    removePopup()
                    return
                }
                
                if node.name == "shopButton" || node.parent?.name == "shopButton" {
                    AudioManager.shared.playEffect(.menuTap)
                    removePopup()
                    
                    // Navigate to shop scene
                    let shopScene = ShopScene(size: size)
                    shopScene.scaleMode = scaleMode
                    view?.presentScene(shopScene, transition: SKTransition.fade(withDuration: 0.5))
                    return
                }
                
                // Check for back button
                if node.name == "backButton" || node.parent?.name == "backButton" {
                    handleBackButton()
                    return
                }
                
                // Check for navigation buttons
                if node.name == "prevButton" || node.parent?.name == "prevButton" {
                    if currentPage > 0 {
                        currentPage -= 1
                        setupLevelDisplay()
                        updateNavigationButtons()
                        AudioManager.shared.playEffect(.menuTap)
                    }
                    return
                }
                
                if node.name == "nextButton" || node.parent?.name == "nextButton" {
                    let totalPages = Int(ceil(Double(levels.count) / Double(levelsPerPage)))
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                        setupLevelDisplay()
                        updateNavigationButtons()
                        AudioManager.shared.playEffect(.menuTap)
                    }
                    return
                }
                
                // Get node names for easier checks
                let nodeName = node.name ?? ""
                let parentName = node.parent?.name ?? ""
                
                // Check for play button first (higher priority)
                if nodeName.starts(with: "playButton_") || parentName.starts(with: "playButton_") {
                    let idPart = nodeName.starts(with: "playButton_") ? 
                                  nodeName.components(separatedBy: "playButton_").last :
                                  parentName.components(separatedBy: "playButton_").last
                    
                    if let levelId = idPart {
                        AudioManager.shared.playEffect(.menuTap)
                        startLevel(withId: levelId)
                        return
                    }
                }
                
                // Check if clicked directly on the "infoText" label
                if nodeName == "infoText" || parentName == "infoText" {
                    // Find the level ID from the parent chain
                    var currentNode: SKNode? = node
                    while currentNode != nil {
                        if let parentNodeName = currentNode?.parent?.name, parentNodeName.starts(with: "level_") {
                            let levelId = parentNodeName.components(separatedBy: "level_").last
                            if let id = levelId {
                                showUnlockRequirement(forLevelId: id)
                                return
                            }
                            break
                        }
                        currentNode = currentNode?.parent
                    }
                }
                
                // Check for level node selection (background, lock, etc.)
                var levelId: String? = nil
                
                if nodeName.starts(with: "level_") {
                    levelId = nodeName.components(separatedBy: "level_").last
                } else if parentName.starts(with: "level_") {
                    levelId = parentName.components(separatedBy: "level_").last
                } else if node.name == "lockOverlay" || node.name == "infoText" || 
                          node.parent?.name == "lockOverlay" || node.parent?.name == "infoText" {
                    // If clicking on lock overlay, find the level ID from the parent
                    var currentNode: SKNode? = node
                    var foundId: String? = nil
                    while currentNode != nil && foundId == nil {
                        if let parentNodeName = currentNode?.parent?.name, parentNodeName.starts(with: "level_") {
                            foundId = parentNodeName.components(separatedBy: "level_").last
                            break
                        }
                        currentNode = currentNode?.parent
                    }
                    levelId = foundId
                }
                
                if let levelId = levelId {
                    if let level = levels.first(where: { $0.id == levelId }), level.isUnlocked {
                        startLevel(withId: levelId)
                        return
                    } else {
                        // Show unlock requirement
                        showUnlockRequirement(forLevelId: levelId)
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - Level Actions
    
    private func handleBackButton() {
        AudioManager.shared.playEffect(.menuTap)
        
        let mainMenu = MainMenuScene(size: size)
        mainMenu.scaleMode = scaleMode
        view?.presentScene(mainMenu, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func startLevel(withId levelId: String) {
        AudioManager.shared.playEffect(.menuTap)
        
        if let level = levels.first(where: { $0.id == levelId }) {
            // Set the current map theme
            _ = MapManager.shared.selectMap(theme: level.mapTheme) // Ignore return value
            
            // Start game with the selected level
            let gameScene = GameScene(size: size, levelId: levelId)
            gameScene.scaleMode = scaleMode
            view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }
    
    private func showUnlockRequirement(forLevelId levelId: String) {
        guard let level = levels.first(where: { $0.id == levelId }) else { return }
        
        AudioManager.shared.playEffect(.menuTap)
        
        // Create an enhanced popup showing the unlock requirement
        let popup = SKNode()
        popup.name = "unlockPopup"
        popup.zPosition = 100
        
        // Background with improved styling
        let background = SKShapeNode(rectOf: CGSize(width: 320, height: 280), cornerRadius: 20)
        background.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.9) // Darker blue
        background.strokeColor = level.mapTheme.backgroundColor
        background.lineWidth = 3
        popup.addChild(background)
        
        // Add decoration
        let decorLine = SKShapeNode(rect: CGRect(x: -140, y: 55, width: 280, height: 2))
        decorLine.fillColor = UIColor.white.withAlphaComponent(0.5)
        decorLine.strokeColor = UIColor.clear
        popup.addChild(decorLine)
        
        // Header with lock icon
        let lockIcon = SKLabelNode(text: "🔒")
        lockIcon.fontSize = 30
        lockIcon.position = CGPoint(x: 0, y: 100)
        popup.addChild(lockIcon)
        
        // Title with improved styling
        let title = SKLabelNode(text: "LEVEL LOCKED")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 26
        title.fontColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0) // Gold color
        title.position = CGPoint(x: 0, y: 65)
        popup.addChild(title)
        
        // Level name with subtle glow
        let levelName = SKLabelNode(text: level.name)
        levelName.fontName = "AvenirNext-DemiBold"
        levelName.fontSize = 22
        levelName.fontColor = UIColor.white
        levelName.position = CGPoint(x: 0, y: 30)
        popup.addChild(levelName)
        
        // Difficulty display
        let difficultyLabel = SKLabelNode(text: "Difficulty: ")
        difficultyLabel.fontName = "AvenirNext-Medium"
        difficultyLabel.fontSize = 16
        difficultyLabel.fontColor = UIColor.lightGray
        difficultyLabel.horizontalAlignmentMode = .left
        difficultyLabel.position = CGPoint(x: -140, y: 0)
        popup.addChild(difficultyLabel)
        
        // Star rating
        for i in 0..<level.difficulty {
            let star = SKLabelNode(text: "⭐️")
            star.fontSize = 14
            star.horizontalAlignmentMode = .left
            star.position = CGPoint(x: -60 + CGFloat(i*18), y: 0)
            popup.addChild(star)
        }
        
        // Unlock requirement with icon
        let unlockHeader = SKLabelNode(text: "Unlock Requirement:")
        unlockHeader.fontName = "AvenirNext-Medium"
        unlockHeader.fontSize = 16
        unlockHeader.fontColor = UIColor.lightGray
        unlockHeader.horizontalAlignmentMode = .left
        unlockHeader.position = CGPoint(x: -140, y: -30)
        popup.addChild(unlockHeader)
        
        // Show icon based on requirement type
        var requirementIcon = "🏆"
        if case .purchasable = level.unlockRequirement {
            requirementIcon = "💰"
        } else if case .seasonal = level.unlockRequirement {
            requirementIcon = "📅"
        } else if case .playerLevel = level.unlockRequirement {
            requirementIcon = "👤"
        }
        
        let iconLabel = SKLabelNode(text: requirementIcon)
        iconLabel.fontSize = 20
        iconLabel.position = CGPoint(x: -120, y: -55)
        iconLabel.horizontalAlignmentMode = .left
        popup.addChild(iconLabel)
        
        // Unlock requirement text
        let requirement = SKLabelNode(text: level.unlockRequirement.description)
        requirement.fontName = "AvenirNext-Medium"
        requirement.fontSize = 16
        requirement.fontColor = UIColor.white
        requirement.preferredMaxLayoutWidth = 230
        requirement.numberOfLines = 0
        requirement.verticalAlignmentMode = .center
        requirement.horizontalAlignmentMode = .left
        requirement.position = CGPoint(x: -90, y: -55)
        popup.addChild(requirement)
        
        // Two buttons - Close and Shop (if applicable)
        let closeButton = SKShapeNode(rectOf: CGSize(width: 130, height: 45), cornerRadius: 10)
        closeButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 0.8)
        closeButton.strokeColor = .white
        closeButton.lineWidth = 2
        closeButton.name = "closePopup"
        
        // Position the button based on whether we need a shop button
        var showShopButton = false
        if case .purchasable = level.unlockRequirement {
            showShopButton = true
            closeButton.position = CGPoint(x: -70, y: -120)
        } else {
            closeButton.position = CGPoint(x: 0, y: -120)
        }
        
        let closeLabel = SKLabelNode(text: "Close")
        closeLabel.fontName = "AvenirNext-Bold"
        closeLabel.fontSize = 18
        closeLabel.fontColor = UIColor.white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position = CGPoint(x: 0, y: 0)
        closeButton.addChild(closeLabel)
        popup.addChild(closeButton)
        
        // Add shop button for purchasable levels
        if showShopButton {
            let shopButton = SKShapeNode(rectOf: CGSize(width: 130, height: 45), cornerRadius: 10)
            shopButton.fillColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 0.8)
            shopButton.strokeColor = .white
            shopButton.lineWidth = 2
            shopButton.position = CGPoint(x: 70, y: -120)
            shopButton.name = "shopButton"
            
            let shopLabel = SKLabelNode(text: "Shop")
            shopLabel.fontName = "AvenirNext-Bold"
            shopLabel.fontSize = 18
            shopLabel.fontColor = UIColor.white
            shopLabel.verticalAlignmentMode = .center
            shopLabel.position = CGPoint(x: 0, y: 0)
            shopButton.addChild(shopLabel)
            popup.addChild(shopButton)
        }
        
        // Center the popup
        popup.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Add the popup with animation
        popup.setScale(0.1)
        addChild(popup)
        
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        popup.run(scaleAction)
    }
    
    private func removePopup() {
        if let popup = childNode(withName: "unlockPopup") {
            let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([scaleDown, remove])
            popup.run(sequence)
        }
    }
}