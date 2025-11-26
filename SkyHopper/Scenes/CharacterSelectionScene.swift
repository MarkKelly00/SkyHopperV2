import SpriteKit

class CharacterSelectionScene: SKScene, CurrencyManagerDelegate {
    
    // Character manager
    private let characterManager = CharacterManager.shared
    private let currencyManager = CurrencyManager.shared
    
    // UI elements
    private var backButton: SKShapeNode!
    private var titleLabel: SKLabelNode!
    private var characterNodes: [SKNode] = []
    private var decorLayer = SKNode()
    private var topBar = SKNode()
    
    // Scroll container for smooth scrolling
    private var scrollContainer: SKNode!
    private var scrollMask: SKShapeNode!
    private var cropNode: SKCropNode!
    
    // Scroll tracking
    private var lastTouchY: CGFloat = 0
    private var isScrolling = false
    private var scrollVelocity: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var visibleHeight: CGFloat = 0
    
    // Character selection
    private var selectedIndex: Int = 0
    private var characters: [CharacterManager.Aircraft] = []
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
        
        // Register as currency delegate to update display
        currencyManager.delegate = self
        
        #if DEBUG
        UILinter.run(scene: self, topBar: topBar)
        #endif
    }
    
    // MARK: - Currency Manager Delegate
    
    func currencyDidChange() {
        SafeAreaTopBar.updateCurrency(in: topBar)
    }
    
    private func setupScene() {
        // Set background color
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Decor layer for clouds behind UI
        decorLayer.removeFromParent()
        decorLayer = SKNode()
        decorLayer.zPosition = UIConstants.Z.decor
        addChild(decorLayer)
        addCloudsBackground(into: decorLayer)
    }
    
    private func setupUI() {
        // Top bar via helper (includes back button and currency row)
        topBar.removeFromParent()
        topBar = SafeAreaTopBar.build(in: self, title: "Characters") { [weak self] in
            self?.handleBackButton()
        }

        // Back button and currency handled by topBar
        
        // Setup scroll container
        setupScrollContainer()
        
        // Load characters
        loadCharacters()
        
        // Display characters
        displayCharacters()
    }
    
    private func setupScrollContainer() {
        // Get topBar bottom position for proper content placement
        let topBarBottomY = topBar.userData?["topBarBottomY"] as? CGFloat ?? (size.height - 120)
        
        // Create crop node for masking scrollable content
        cropNode = SKCropNode()
        cropNode.position = CGPoint(x: size.width / 2, y: topBarBottomY / 2 - 20)
        cropNode.zPosition = 5
        addChild(cropNode)
        
        // Calculate visible area
        visibleHeight = topBarBottomY - 60  // Leave padding at bottom
        
        // Create mask
        scrollMask = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: visibleHeight), cornerRadius: 12)
        scrollMask.fillColor = .white
        cropNode.maskNode = scrollMask
        
        // Create scroll container
        scrollContainer = SKNode()
        scrollContainer.position = CGPoint(x: 0, y: 0)
        cropNode.addChild(scrollContainer)
    }
    
    private func createBackButton() {
        // Back handled by SafeAreaTopBar
    }
    
    private func loadCharacters() {
        // Load available characters from the allAircraft property
        characters = CharacterManager.shared.allAircraft
        
        // Set the selected index to the current character
        if let currentIndex = characters.firstIndex(where: { $0.type == characterManager.selectedAircraft }) {
            selectedIndex = currentIndex
        }
    }
    
    private func displayCharacters() {
        guard scrollContainer != nil else { return }
        
        // Clear existing character nodes
        for node in characterNodes {
            node.removeFromParent()
        }
        characterNodes.removeAll()
        scrollContainer.removeAllChildren()
        
        // Setup grid layout within scroll container
        let columns = 3
        let xSpacing: CGFloat = 120
        let ySpacing: CGFloat = 170
        let totalGridWidth = xSpacing * CGFloat(columns - 1)
        
        // Calculate number of rows
        let rows = (characters.count + columns - 1) / columns
        contentHeight = CGFloat(rows) * ySpacing + 50
        
        // Start from top of scroll container
        let startY = visibleHeight / 2 - 80
        
        for (index, aircraft) in characters.enumerated() {
            let row = index / columns
            let col = index % columns
            
            // Center horizontally within scroll container
            let x = -totalGridWidth / 2 + CGFloat(col) * xSpacing
            let y = startY - CGFloat(row) * ySpacing
            
            let node = createCharacterNode(aircraft: aircraft, isSelected: index == selectedIndex, position: CGPoint(x: x, y: y))
            node.name = "character_\(index)"
            characterNodes.append(node)
            scrollContainer.addChild(node)
        }
    }
    
    private func createCharacterNode(aircraft: CharacterManager.Aircraft, isSelected: Bool, position: CGPoint) -> SKNode {
        let containerNode = SKNode()
        containerNode.position = position
        containerNode.zPosition = 5
        
        // Create frame
        let frameSize = CGSize(width: 116, height: 116)
        let frame = SKShapeNode(rectOf: frameSize, cornerRadius: 10)
        frame.fillColor = isSelected ? UIColor(white: 1.0, alpha: 0.6) : UIColor(white: 0.7, alpha: 0.35)
        frame.strokeColor = isSelected ? .yellow : .white
        frame.lineWidth = isSelected ? 3 : 1
        containerNode.addChild(frame)
        
        // Create character sprite
        let characterSprite = characterManager.createAircraftSprite(for: aircraft.type)
        characterSprite.setScale(0.9)
        characterSprite.zPosition = 1
        containerNode.addChild(characterSprite)
        
        // Add name label
        let nameLabel = SKLabelNode(text: aircraft.type.rawValue.capitalized)
        nameLabel.fontName = "AvenirNext-Medium"
        nameLabel.fontSize = 14
        nameLabel.fontColor = .black
        nameLabel.position = CGPoint(x: 0, y: -frameSize.height/2 - 15)
        containerNode.addChild(nameLabel)
        
        // Add lock or select button
        if aircraft.isUnlocked {
            // Display "Selected" or "Select" button
            let buttonText = isSelected ? "Selected" : "Select"
            let selectButton = SKShapeNode(rectOf: CGSize(width: 80, height: 30), cornerRadius: 5)
            selectButton.fillColor = isSelected ? .green : .blue
            selectButton.strokeColor = .white
            selectButton.lineWidth = 1
            selectButton.position = CGPoint(x: 0, y: -frameSize.height/2 - 40)
            selectButton.name = "select_\(aircraft.type.rawValue)"
            
            let buttonLabel = SKLabelNode(text: buttonText)
            buttonLabel.fontName = "AvenirNext-Medium"
            buttonLabel.fontSize = 14
            buttonLabel.fontColor = .white
            buttonLabel.verticalAlignmentMode = .center
            buttonLabel.horizontalAlignmentMode = .center
            selectButton.addChild(buttonLabel)
            
            containerNode.addChild(selectButton)
        } else {
            // Display lock with price
            let lockNode = SKNode()
            lockNode.position = CGPoint(x: 0, y: -frameSize.height/2 - 40)
            
            let lockIcon = SKLabelNode(text: "🔒")
            lockIcon.fontSize = 20
            lockIcon.verticalAlignmentMode = .center
            lockIcon.position = CGPoint(x: -20, y: 0)
            lockNode.addChild(lockIcon)
            
            let priceLabel = SKLabelNode(text: "\(aircraft.unlockCost)")
            priceLabel.fontName = "AvenirNext-Medium"
            priceLabel.fontSize = 14
            priceLabel.fontColor = .yellow
            priceLabel.verticalAlignmentMode = .center
            priceLabel.horizontalAlignmentMode = .left
            priceLabel.position = CGPoint(x: -5, y: 0)
            lockNode.addChild(priceLabel)
            
            let coinIcon = SKLabelNode(text: "🪙")
            coinIcon.fontSize = 16
            coinIcon.verticalAlignmentMode = .center
            coinIcon.position = CGPoint(x: 25, y: 0)
            lockNode.addChild(coinIcon)
            
            // Make the whole lock node tappable to purchase
            let unlockButton = SKShapeNode(rectOf: CGSize(width: 80, height: 30), cornerRadius: 5)
            unlockButton.fillColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 0.7)
            unlockButton.strokeColor = .white
            unlockButton.lineWidth = 1
            unlockButton.name = "unlock_\(aircraft.type.rawValue)"
            unlockButton.alpha = 0.5 // Semi-transparent to indicate it's a button
            lockNode.addChild(unlockButton)
            
            containerNode.addChild(lockNode)
        }
        
        return containerNode
    }
    
    private func selectCharacter(at index: Int) {
        guard index >= 0 && index < characters.count else { return }
        
        let aircraft = characters[index]
        if aircraft.isUnlocked {
            // Update selection
            selectedIndex = index
            _ = characterManager.selectAircraft(type: aircraft.type) // Ignore return value
            
            // Update display
            displayCharacters()
            
            // Show confirmation
            showMessage("Selected \(aircraft.type.rawValue.capitalized)")
        }
    }
    
    private func unlockCharacter(at index: Int) {
        guard index >= 0 && index < characters.count else { return }
        
        let aircraft = characters[index]
        if !aircraft.isUnlocked {
            if currencyManager.spendCoins(aircraft.unlockCost) {
                // Unlock the character
                _ = characterManager.unlockAircraft(type: aircraft.type) // Ignore return value
                
                // Refresh display
                loadCharacters()
                displayCharacters()
                updateCurrencyDisplay()
                
                // Show confirmation
                showMessage("\(aircraft.type.rawValue.capitalized) Unlocked!")
            } else {
                showMessage("Not enough coins!")
            }
        }
    }
    
    private func updateCurrencyDisplay() {
        // Update currency via SafeAreaTopBar (coinsLabel is handled by topBar now)
        SafeAreaTopBar.updateCurrency(in: topBar)
    }
    
    private func showMessage(_ text: String) {
        let message = SKLabelNode(text: text)
        message.fontName = "AvenirNext-Bold"
        message.fontSize = 24
        message.position = CGPoint(x: size.width / 2, y: size.height / 2)
        message.zPosition = 100
        message.alpha = 0
        addChild(message)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        message.run(sequence)
    }
    
    // MARK: - Background
    
    private func addCloudsBackground(into parent: SKNode) {
        // Add clouds in the background
        for _ in 0..<10 {
            let cloud = createCloud()
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            cloud.zPosition = UIConstants.Z.background
            parent.addChild(cloud)
        }
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
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // Check for back button first
        for node in touchedNodes {
            if node.name == "backButton" || node.parent?.name == "backButton" {
                handleBackButton()
                return
            }
        }
        
        // Check if touch is within scroll area
        if let crop = cropNode, crop.contains(location) {
            isScrolling = true
            lastTouchY = location.y
            scrollVelocity = 0
            scrollContainer?.removeAction(forKey: "momentum")
        }
        
        // Check for button interactions (only if not scrolling significantly)
        for node in touchedNodes {
            // Check for character selection
            if let name = node.name, name.starts(with: "select_") {
                let characterName = String(name.dropFirst("select_".count))
                if let index = characters.firstIndex(where: { $0.type.rawValue == characterName }) {
                    selectCharacter(at: index)
                    return
                }
            }
            
            // Check for character unlock
            if let name = node.name, name.starts(with: "unlock_") {
                let characterName = String(name.dropFirst("unlock_".count))
                if let index = characters.firstIndex(where: { $0.type.rawValue == characterName }) {
                    unlockCharacter(at: index)
                    return
                }
            }
            
            // Check for character node selection
            if let name = node.name, name.starts(with: "character_") {
                if let indexStr = name.split(separator: "_").last, let index = Int(indexStr) {
                    if characters[index].isUnlocked {
                        selectCharacter(at: index)
                    } else {
                        unlockCharacter(at: index)
                    }
                    return
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isScrolling, let container = scrollContainer else { return }
        
        let location = touch.location(in: self)
        let deltaY = location.y - lastTouchY
        container.position.y += deltaY
        scrollVelocity = deltaY * 0.8 + scrollVelocity * 0.2
        lastTouchY = location.y
        
        // Calculate scroll bounds
        let maxScrollY: CGFloat = 0
        let minScrollY: CGFloat = max(contentHeight - visibleHeight, 0)
        
        // Rubber band effect at edges
        if container.position.y > maxScrollY {
            let overscroll = container.position.y - maxScrollY
            container.position.y = maxScrollY + overscroll * 0.3
        } else if container.position.y < -minScrollY {
            let overscroll = -minScrollY - container.position.y
            container.position.y = -minScrollY - overscroll * 0.3
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isScrolling, let container = scrollContainer else {
            isScrolling = false
            return
        }
        
        isScrolling = false
        
        // Calculate scroll bounds
        let maxScrollY: CGFloat = 0
        let minScrollY: CGFloat = max(contentHeight - visibleHeight, 0)
        
        // Apply momentum scrolling
        let momentumAction = SKAction.customAction(withDuration: 1.5) { [weak self] node, elapsedTime in
            guard let self = self else { return }
            let decay = pow(0.95, Double(elapsedTime * 60))
            let velocity = self.scrollVelocity * CGFloat(decay)
            
            if abs(velocity) > 0.5 {
                node.position.y += velocity
                
                // Clamp to bounds during momentum
                if node.position.y > maxScrollY {
                    node.position.y = maxScrollY
                    self.scrollVelocity = 0
                } else if node.position.y < -minScrollY {
                    node.position.y = -minScrollY
                    self.scrollVelocity = 0
                }
            }
        }
        
        // Snap back if overscrolled
        let currentY = container.position.y
        if currentY > maxScrollY {
            let snapBack = SKAction.moveTo(y: maxScrollY, duration: 0.3)
            snapBack.timingMode = .easeOut
            container.run(snapBack, withKey: "momentum")
        } else if currentY < -minScrollY {
            let snapBack = SKAction.moveTo(y: -minScrollY, duration: 0.3)
            snapBack.timingMode = .easeOut
            container.run(snapBack, withKey: "momentum")
        } else {
            container.run(momentumAction, withKey: "momentum")
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrolling = false
    }
    
    private func handleBackButton() {
        // Transition back to main menu
        let mainMenu = MainMenuScene(size: size)
        mainMenu.scaleMode = scaleMode
        view?.presentScene(mainMenu, transition: SKTransition.fade(withDuration: 0.5))
    }
}