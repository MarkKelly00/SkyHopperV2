import SpriteKit
import GameKit

class LevelSelectionScene: SKScene, CurrencyManagerDelegate {
    
    // Currency manager
    private let currencyManager = CurrencyManager.shared
    
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
    private var decorLayer = SKNode()
    private var topBar = SKNode()
    private var safe: SafeAreaLayout { SafeAreaLayout(scene: self) }
    
    // Swipe gesture tracking for page navigation
    private var swipeStartX: CGFloat?
    private var swipeStartY: CGFloat?
    private var isSwiping = false
    private let swipeThreshold: CGFloat = 60  // Minimum horizontal distance for swipe
    private let swipeVerticalLimit: CGFloat = 80  // Maximum vertical distance allowed
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        loadLevels()
        setupUI()
        setupLevelDisplay()
        
        // Register as currency delegate to update display
        currencyManager.delegate = self
    }
    
    // MARK: - Currency Manager Delegate
    
    func currencyDidChange() {
        SafeAreaTopBar.updateCurrency(in: topBar)
    }
    
    private func setupScene() {
        // Set background color based on current map theme
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Decor layer for clouds
        decorLayer.removeFromParent()
        decorLayer = SKNode()
        decorLayer.zPosition = UIConstants.Z.decor
        addChild(decorLayer)
        addCloudsBackground(into: decorLayer)
    }
    
    private func loadLevels() {
        // Load level data
        levels = LevelData.loadUnlockedLevels()
    }
    
    private func setupUI() {
        // Top bar via helper
        topBar.removeFromParent()
        topBar = SafeAreaTopBar.build(in: self, title: "Select Level") { [weak self] in
            self?.handleBackButton()
        }
        
        // Page indicator
        pageIndicator = SKLabelNode(text: "Page 1/\(ceil(Double(levels.count) / Double(levelsPerPage)))")
        pageIndicator.fontName = "AvenirNext-Medium"
        pageIndicator.fontSize = 18
        pageIndicator.position = CGPoint(x: size.width / 2, y: safe.safeBottomY(offset: 60))
        pageIndicator.zPosition = UIConstants.Z.ui
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
        prevButton.position = CGPoint(x: safe.safeLeftX(offset: 50), y: safe.safeBottomY(offset: 52))
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
        nextButton.position = CGPoint(x: safe.safeRightX(offset: 50), y: safe.safeBottomY(offset: 52))
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
        // Back handled by SafeAreaTopBar
    }
    
    private func setupLevelDisplay() {
        // Remove existing level nodes
        levelNodes.forEach { $0.removeFromParent() }
        levelNodes.removeAll()
        
        // Calculate start index and number of levels to display
        let startIndex = currentPage * levelsPerPage
        let endIndex = min(startIndex + levelsPerPage, levels.count)
        
        // Layout bounds from safe area
        let contentLeft = safe.safeLeftX(offset: UIConstants.Spacing.xlarge)
        let contentRight = safe.safeRightX(offset: UIConstants.Spacing.xlarge)
        let gridWidth = contentRight - contentLeft

        // Responsive card sizing
        let padding: CGFloat = 25
        let levelWidth: CGFloat = (gridWidth - padding) / 2
        let levelHeight: CGFloat = max(200, min(250, levelWidth * 0.62))
        
        // Create level cards
        for i in startIndex..<endIndex {
            let level = levels[i]
            let levelNode = createLevelNode(for: level, width: levelWidth, height: levelHeight)
            
            // Position in grid (2x2)
            let column = (i - startIndex) % 2
            let row = (i - startIndex) / 2

            var gridTop = safe.safeTopY(offset: UIConstants.Spacing.xlarge + 44)
            if let bottomY = topBar.userData?["topBarBottomY"] as? CGFloat {
                gridTop = bottomY - UIConstants.Spacing.large
            }
            let row0CenterY = gridTop - levelHeight / 2

            let xPosition = contentLeft + (CGFloat(column) * (levelWidth + padding)) + (levelWidth / 2)
            let yPosition = row0CenterY - (CGFloat(row) * (levelHeight + padding))
            
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
        let background = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        background.fillColor = level.mapTheme.backgroundColor
        background.strokeColor = UIColor(white: 1.0, alpha: 0.6)
        background.lineWidth = 1.5
        background.name = "levelBackground"
        containerNode.addChild(background)
        
        // Add a semi-transparent panel behind text for better readability
        let textPanel = SKShapeNode(rectOf: CGSize(width: width - 12, height: height - 12), cornerRadius: 14)
        textPanel.fillColor = UIColor.black.withAlphaComponent(0.2)
        textPanel.strokeColor = UIColor.clear
        textPanel.position = CGPoint(x: 0, y: 0)
        textPanel.zPosition = 1
        containerNode.addChild(textPanel)
        
        // --- Measure-based layout ---
        let baseHeight: CGFloat = 230
        let scale = min(max(height / baseHeight, 0.92), 1.15)
        let inset: CGFloat = 10 * scale
        let topY: CGFloat = height/2 - inset
        let bottomY: CGFloat = -height/2 + inset
        let controlMargin: CGFloat = 12 * scale
        let playRadius: CGFloat = 16 * scale
        let controlBarH: CGFloat = (playRadius * 2) + (controlMargin * 2)

        // Title - force single line with adaptive font sizing
        let titleLabel = SKLabelNode(text: level.name)
        titleLabel.fontName = "AvenirNext-Bold"
        
        // Force single line with dynamically scaled font size
        titleLabel.numberOfLines = 1
        // Width constraint for the title - used for font size calculation
        let _ = width - 32 // Constraint is used implicitly in the layout calculations
        
        // Start with a base font size and scale down if needed
        let baseFontSize = 22.0
        var fontSize = baseFontSize
        
        // Reduce font size based on title length
        if level.name.count > 12 {
            fontSize = baseFontSize - 2.0
        }
        if level.name.count > 15 {
            fontSize = baseFontSize - 4.0
        }
        
        titleLabel.fontSize = fontSize * scale
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 2
        containerNode.addChild(titleLabel)
        
        // Measure title height and position it
        let titleH = max(20 * scale, titleLabel.frame.height)
        titleLabel.position = CGPoint(x: 0, y: topY - titleH/2 - (6 * scale))

        // Description
        let descLabel = SKLabelNode(text: level.description)
        descLabel.fontName = "AvenirNext-Medium"
        descLabel.fontSize = 14 * scale
        descLabel.fontColor = .white
        descLabel.preferredMaxLayoutWidth = width - 24
        descLabel.numberOfLines = 3
        descLabel.verticalAlignmentMode = .center
        descLabel.horizontalAlignmentMode = .center
        descLabel.zPosition = 2
        containerNode.addChild(descLabel)
        let descH = max(18 * scale, descLabel.calculateAccumulatedFrame().height)
        // Reserve a bottom control bar for play button + best score
        descLabel.position = CGPoint(x: 0, y: bottomY + controlBarH + descH/2)

        // Position stars at a fixed distance from the title - consistent across all tiles
        let titleBottomY = titleLabel.position.y - titleH/2
        let descTopY = descLabel.position.y + descH/2
        
        // Fixed gap from title (guaranteed consistent placement)
        let fixedGapFromTitle: CGFloat = 24 * scale
        var starRowY = titleBottomY - fixedGapFromTitle
        
        // Enforce minimum spacing from description for safety
        let minGapDesc: CGFloat = 14 * scale
        if starRowY < descTopY + minGapDesc {
            starRowY = descTopY + minGapDesc
        }

        // Normalize star sizing for consistency across tiles
        let starSpacing: CGFloat = 10 * scale
        let starSize: CGFloat = 16 * scale
        let totalStarWidth = (CGFloat(level.difficulty) * starSize) + (CGFloat(max(0, level.difficulty - 1)) * starSpacing)
        var starX = -totalStarWidth / 2
        for _ in 0..<level.difficulty {
            let star = SKLabelNode(text: "⭐️")
            star.fontSize = starSize
            star.verticalAlignmentMode = .center
            star.position = CGPoint(x: starX + starSize/2, y: starRowY)
            star.zPosition = 2
            containerNode.addChild(star)
            starX += starSize + starSpacing
        }
        
                // Removed colored map icon box as requested
        
        // High score with improved readability
        let highScore = PlayerData.shared.mapHighScores[level.id] ?? 0
        let scoreLabel = SKLabelNode(text: "Best: \(highScore)")
        scoreLabel.fontName = "AvenirNext-Medium"
        scoreLabel.fontSize = 14 * scale
        scoreLabel.fontColor = UIColor.white
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .right
        let baselineY = bottomY + controlMargin + playRadius
        scoreLabel.position = CGPoint(x: width/2 - (14 * scale), y: baselineY)
        scoreLabel.zPosition = 2
        containerNode.addChild(scoreLabel)
        
        // Handle locked/unlocked level styling
        if !level.isUnlocked {
            // Create an interactive overlay node for the entire level card
            let interactiveOverlay = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 15)
            interactiveOverlay.fillColor = UIColor.clear // Clear but interactive
            interactiveOverlay.strokeColor = UIColor.clear
            interactiveOverlay.zPosition = 10 // Above everything for touch detection
            interactiveOverlay.name = "infoTapTarget_\(level.id)" // Named with level ID for direct identification
            interactiveOverlay.isUserInteractionEnabled = true // Make sure it responds to touches
            containerNode.addChild(interactiveOverlay)
            
            // Create a semi-transparent overlay for locked levels
            let lockOverlay = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 15)
            lockOverlay.fillColor = UIColor.black.withAlphaComponent(0.5)
            lockOverlay.strokeColor = UIColor.clear
            lockOverlay.zPosition = 5 // Above other elements but below the interactive overlay
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
            lockIcon.name = "lockIcon_\(level.id)" // Named with level ID
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
            
            // Play button icon in lower left corner (scales with card)
        let playButtonCircle = SKShapeNode(circleOfRadius: playRadius)
        playButtonCircle.fillColor = UIColor(red: 0.18, green: 0.68, blue: 0.32, alpha: 0.95)
        playButtonCircle.strokeColor = UIColor(white: 1.0, alpha: 0.8)
        playButtonCircle.lineWidth = 1.5 * scale
        // Mirror the right-side margin used by Best score
        playButtonCircle.position = CGPoint(x: -width/2 + (14 * scale + playRadius), y: baselineY)
            playButtonCircle.zPosition = 4
            playButtonCircle.name = "playButton_\(level.id)" // Add ID to the button name
            containerNode.addChild(playButtonCircle)
            
            // Play icon (triangle) - proportionally sized
            let playTriangle = SKShapeNode()
            let trianglePath = UIBezierPath()
            trianglePath.move(to: CGPoint(x: -3.8 * scale, y: -5.0 * scale))
            trianglePath.addLine(to: CGPoint(x: -3.8 * scale, y: 5.0 * scale))
            trianglePath.addLine(to: CGPoint(x: 6.2 * scale, y: 0))
            trianglePath.close()
            playTriangle.path = trianglePath.cgPath
        playTriangle.fillColor = UIColor(white: 1.0, alpha: 0.95)
            playTriangle.strokeColor = UIColor.clear
            playTriangle.position = CGPoint(x: 1, y: 0) // Slight offset for visual centering
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
    
    private func addCloudsBackground(into parent: SKNode) {
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
            cloud.zPosition = UIConstants.Z.background
            
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
            parent.addChild(cloud)
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // Record swipe start position
        swipeStartX = location.x
        swipeStartY = location.y
        isSwiping = false
        
        for _ in [touch] {
            
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
                
                // Direct check for the interactive overlay - highest priority
                if nodeName.starts(with: "infoTapTarget_") {
                    // Extract level ID directly from the node name
                    let levelId = nodeName.components(separatedBy: "infoTapTarget_").last!
                    print("Direct info tap target hit for level: \(levelId)")
                    AudioManager.shared.playEffect(.menuTap)
                    showUnlockRequirement(forLevelId: levelId)
                    return
                }
                
                // Check if clicked on lock icon with level ID
                if nodeName.starts(with: "lockIcon_") {
                    let levelId = nodeName.components(separatedBy: "lockIcon_").last!
                    print("Lock icon tapped for level: \(levelId)")
                    AudioManager.shared.playEffect(.menuTap)
                    showUnlockRequirement(forLevelId: levelId)
                    return
                }
                
                // Check all the other possible tap locations
                if nodeName == "infoText" || parentName == "infoText" || 
                   nodeName == "🔒" || nodeName == "lockOverlay" || 
                   parentName == "lockOverlay" {
                    // Find the level ID from the parent chain - more thorough traversal
                    var currentNode: SKNode? = node
                    var foundId: String? = nil
                    
                    // Keep moving up the node hierarchy until we find a level node
                    while currentNode != nil && foundId == nil {
                        // Check if the current node is a level node
                        if let nodeName = currentNode?.name, nodeName.starts(with: "level_") {
                            foundId = nodeName.components(separatedBy: "level_").last
                            break
                        }
                        
                        // Check if the parent is a level node
                        if let parentName = currentNode?.parent?.name, parentName.starts(with: "level_") {
                            foundId = parentName.components(separatedBy: "level_").last
                            break
                        }
                        
                        // Move up to the parent
                        currentNode = currentNode?.parent
                    }
                    
                    // If we found a level ID, show the unlock requirement
                    if let id = foundId {
                        print("Showing unlock requirement through hierarchy for level: \(id)")
                        AudioManager.shared.playEffect(.menuTap)
                        showUnlockRequirement(forLevelId: id)
                        return
                    }
                }
                
                // Check for general level node selection (container, background, etc.)
                // This will be a fallback if the above specific checks don't match
                var levelId: String? = nil
                
                if nodeName.starts(with: "level_") {
                    levelId = nodeName.components(separatedBy: "level_").last
                } else if parentName.starts(with: "level_") {
                    levelId = parentName.components(separatedBy: "level_").last
                } else {
                    // For any other nodes (background, etc.), try to find parent level node
                    var currentNode: SKNode? = node
                    var foundId: String? = nil
                    
                    // Check entire parent hierarchy for level node
                    while currentNode != nil && foundId == nil {
                        // Check current node
                        if let nodeName = currentNode?.name, nodeName.starts(with: "level_") {
                            foundId = nodeName.components(separatedBy: "level_").last
                            break
                        }
                        
                        // Check parent node
                        if let parentName = currentNode?.parent?.name, parentName.starts(with: "level_") {
                            foundId = parentName.components(separatedBy: "level_").last
                            break
                        }
                        
                        // Move up to parent
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startX = swipeStartX,
              let startY = swipeStartY else { return }
        
        let location = touch.location(in: self)
        let deltaX = location.x - startX
        let deltaY = abs(location.y - startY)
        
        // Only consider horizontal swipe if vertical movement is limited
        if deltaY < swipeVerticalLimit && abs(deltaX) > swipeThreshold / 2 {
            isSwiping = true
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startX = swipeStartX,
              let startY = swipeStartY else {
            resetSwipeState()
            return
        }
        
        let location = touch.location(in: self)
        let deltaX = location.x - startX
        let deltaY = abs(location.y - startY)
        
        // Check for valid horizontal swipe
        if deltaY < swipeVerticalLimit && abs(deltaX) >= swipeThreshold {
            let totalPages = Int(ceil(Double(levels.count) / Double(levelsPerPage)))
            
            if deltaX > 0 && currentPage > 0 {
                // Swipe RIGHT = go to PREVIOUS page
                currentPage -= 1
                animatePageTransition(direction: .right)
                AudioManager.shared.playEffect(.menuTap)
            } else if deltaX < 0 && currentPage < totalPages - 1 {
                // Swipe LEFT = go to NEXT page
                currentPage += 1
                animatePageTransition(direction: .left)
                AudioManager.shared.playEffect(.menuTap)
            }
        }
        
        resetSwipeState()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetSwipeState()
    }
    
    private func resetSwipeState() {
        swipeStartX = nil
        swipeStartY = nil
        isSwiping = false
    }
    
    private enum SwipeDirection {
        case left
        case right
    }
    
    private func animatePageTransition(direction: SwipeDirection) {
        // Animate level nodes out
        let moveAmount: CGFloat = direction == .left ? -size.width : size.width
        
        for node in levelNodes {
            let moveOut = SKAction.moveBy(x: moveAmount, y: 0, duration: 0.2)
            moveOut.timingMode = .easeIn
            node.run(moveOut)
        }
        
        // After animation, reload with new page
        run(SKAction.wait(forDuration: 0.15)) { [weak self] in
            guard let self = self else { return }
            self.setupLevelDisplay()
            self.updateNavigationButtons()
            
            // Animate new nodes in from opposite direction
            let startOffset: CGFloat = direction == .left ? self.size.width : -self.size.width
            for node in self.levelNodes {
                node.position.x += startOffset
                let moveIn = SKAction.moveBy(x: -startOffset, y: 0, duration: 0.25)
                moveIn.timingMode = .easeOut
                node.run(moveIn)
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
