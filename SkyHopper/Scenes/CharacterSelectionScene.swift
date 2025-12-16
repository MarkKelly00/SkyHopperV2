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
    private var touchStartY: CGFloat = 0  // Track initial touch position
    private var totalScrollDistance: CGFloat = 0  // Track total scroll distance
    private var isScrolling = false
    private var scrollVelocity: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var visibleHeight: CGFloat = 0
    private let scrollThreshold: CGFloat = 10  // Minimum distance to consider as scroll vs tap
    
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
        
        // Setup grid layout within scroll container - professional consistent spacing
        let columns = 3
        let cardWidth: CGFloat = 116  // Card size
        let cardHeight: CGFloat = 116
        let horizontalGap: CGFloat = 14  // Gap between cards horizontally
        let verticalGap: CGFloat = 85    // Gap between rows (includes name + button + padding)
        
        // Calculate spacing based on card size + gaps
        let xSpacing: CGFloat = cardWidth + horizontalGap
        let ySpacing: CGFloat = cardHeight + verticalGap
        let totalGridWidth = xSpacing * CGFloat(columns - 1)
        
        // Calculate number of rows
        let rows = (characters.count + columns - 1) / columns
        contentHeight = CGFloat(rows) * ySpacing + 120  // Extra padding at bottom for last row
        
        // Start from top of scroll container - move grid up closer to title
        let startY = visibleHeight / 2 - 60
        
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
        
        // Add name label - format nicely with spaces for camelCase
        let displayName = formatCharacterName(aircraft.type.rawValue)
        let nameLabel = SKLabelNode(text: displayName)
        nameLabel.fontName = "AvenirNext-DemiBold"
        nameLabel.fontSize = 13
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -frameSize.height/2 - 18)
        containerNode.addChild(nameLabel)
        
        // Add lock or select button
        if aircraft.isUnlocked {
            // Display "Selected" or "Select" button - clean iOS style
            let buttonText = isSelected ? "Selected" : "Select"
            let selectButton = SKShapeNode(rectOf: CGSize(width: 90, height: 32), cornerRadius: 8)
            selectButton.fillColor = isSelected ? UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0) : UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
            selectButton.strokeColor = .clear
            selectButton.lineWidth = 0
            selectButton.position = CGPoint(x: 0, y: -frameSize.height/2 - 48)
            selectButton.name = "select_\(aircraft.type.rawValue)"
            
            let buttonLabel = SKLabelNode(text: buttonText)
            buttonLabel.fontName = "AvenirNext-Bold"
            buttonLabel.fontSize = 14
            buttonLabel.fontColor = .white
            buttonLabel.verticalAlignmentMode = .center
            buttonLabel.horizontalAlignmentMode = .center
            selectButton.addChild(buttonLabel)
            
            containerNode.addChild(selectButton)
        } else {
            // Display professional price button with lock icon
            let priceButton = SKShapeNode(rectOf: CGSize(width: 90, height: 32), cornerRadius: 8)
            priceButton.fillColor = UIColor(red: 0.55, green: 0.45, blue: 0.25, alpha: 1.0)
            priceButton.strokeColor = UIColor(red: 0.75, green: 0.65, blue: 0.35, alpha: 1.0)
            priceButton.lineWidth = 1.5
            priceButton.position = CGPoint(x: 0, y: -frameSize.height/2 - 48)
            priceButton.name = "unlock_\(aircraft.type.rawValue)"
            
            // Lock icon on the left
            let lockIcon = SKLabelNode(text: "🔒")
            lockIcon.fontSize = 14
            lockIcon.verticalAlignmentMode = .center
            lockIcon.position = CGPoint(x: -32, y: 0)
            priceButton.addChild(lockIcon)
            
            // Price text - formatted with comma for thousands
            let formattedPrice = formatPrice(aircraft.unlockCost)
            let priceLabel = SKLabelNode(text: formattedPrice)
            priceLabel.fontName = "AvenirNext-Bold"
            priceLabel.fontSize = 13
            priceLabel.fontColor = .white
            priceLabel.verticalAlignmentMode = .center
            priceLabel.horizontalAlignmentMode = .center
            priceLabel.position = CGPoint(x: 8, y: 0)
            priceButton.addChild(priceLabel)
            
            containerNode.addChild(priceButton)
        }
        
        return containerNode
    }
    
    // Helper to format character names with spaces
    private func formatCharacterName(_ name: String) -> String {
        var result = ""
        for char in name {
            if char.isUppercase && !result.isEmpty {
                result += " "
            }
            result += String(char)
        }
        return result.capitalized
    }
    
    // Helper to format price with comma separator
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
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
        
        // Check if touch is within scroll area - start tracking for potential scroll
        if let crop = cropNode, crop.contains(location) {
            isScrolling = true
            lastTouchY = location.y
            touchStartY = location.y  // Remember start position
            totalScrollDistance = 0   // Reset scroll distance
            scrollVelocity = 0
            scrollContainer?.removeAction(forKey: "momentum")
        }
        
        // Don't handle character selection on touchesBegan
        // Wait for touchesEnded to distinguish taps from scrolls
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isScrolling, let container = scrollContainer else { return }
        
        let location = touch.location(in: self)
        let deltaY = location.y - lastTouchY
        
        // Track total scroll distance to distinguish scrolls from taps
        totalScrollDistance += abs(deltaY)
        
        // Standard iOS-style scrolling:
        // Swipe UP (positive deltaY in SpriteKit) = show content below = container moves UP (positive)
        // Swipe DOWN (negative deltaY) = show content above = container moves DOWN (negative)
        container.position.y += deltaY
        scrollVelocity = deltaY * 0.8 + scrollVelocity * 0.2
        lastTouchY = location.y
        
        // Calculate scroll bounds
        // maxScrollUp = how far we can scroll up to show bottom content (positive)
        // maxScrollDown = 0 (starting position, can't go negative)
        let maxScrollUp: CGFloat = max(contentHeight - visibleHeight, 0)
        let maxScrollDown: CGFloat = 0
        
        // Rubber band effect at edges
        if container.position.y > maxScrollUp {
            let overscroll = container.position.y - maxScrollUp
            container.position.y = maxScrollUp + overscroll * 0.3
        } else if container.position.y < maxScrollDown {
            let overscroll = maxScrollDown - container.position.y
            container.position.y = maxScrollDown - overscroll * 0.3
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            isScrolling = false
            return
        }
        
        let location = touch.location(in: self)
        let wasTap = totalScrollDistance < scrollThreshold
        
        // If it was a tap (not a scroll), handle character selection
        if wasTap {
            let touchedNodes = nodes(at: location)
            for node in touchedNodes {
                // Check for character selection button
                if let name = node.name, name.starts(with: "select_") {
                    let characterName = String(name.dropFirst("select_".count))
                    if let index = characters.firstIndex(where: { $0.type.rawValue == characterName }) {
                        selectCharacter(at: index)
                        isScrolling = false
                        return
                    }
                }
                
                // Check for character unlock button
                if let name = node.name, name.starts(with: "unlock_") {
                    let characterName = String(name.dropFirst("unlock_".count))
                    if let index = characters.firstIndex(where: { $0.type.rawValue == characterName }) {
                        unlockCharacter(at: index)
                        isScrolling = false
                        return
                    }
                }
                
                // Check for character node tap (anywhere on the card)
                if let name = node.name, name.starts(with: "character_") {
                    if let indexStr = name.split(separator: "_").last, let index = Int(indexStr) {
                        if characters[index].isUnlocked {
                            selectCharacter(at: index)
                        } else {
                            unlockCharacter(at: index)
                        }
                        isScrolling = false
                        return
                    }
                }
            }
        }
        
        // Handle momentum scrolling
        guard let container = scrollContainer else {
            isScrolling = false
            return
        }
        
        isScrolling = false
        
        // Calculate scroll bounds (matching touchesMoved)
        let maxScrollUp: CGFloat = max(contentHeight - visibleHeight, 0)
        let maxScrollDown: CGFloat = 0
        
        // Apply momentum scrolling (standard iOS direction)
        let momentumAction = SKAction.customAction(withDuration: 1.5) { [weak self] node, elapsedTime in
            guard let self = self else { return }
            let decay = pow(0.95, Double(elapsedTime * 60))
            let velocity = self.scrollVelocity * CGFloat(decay)
            
            if abs(velocity) > 0.5 {
                node.position.y += velocity
                
                // Clamp to bounds during momentum
                if node.position.y > maxScrollUp {
                    node.position.y = maxScrollUp
                    self.scrollVelocity = 0
                } else if node.position.y < maxScrollDown {
                    node.position.y = maxScrollDown
                    self.scrollVelocity = 0
                }
            }
        }
        
        // Snap back if overscrolled
        let currentY = container.position.y
        if currentY > maxScrollUp {
            let snapBack = SKAction.moveTo(y: maxScrollUp, duration: 0.3)
            snapBack.timingMode = .easeOut
            container.run(snapBack, withKey: "momentum")
        } else if currentY < maxScrollDown {
            let snapBack = SKAction.moveTo(y: maxScrollDown, duration: 0.3)
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