import SpriteKit

class CharacterSelectionScene: SKScene {
    
    // Character manager
    private let characterManager = CharacterManager.shared
    private let currencyManager = CurrencyManager.shared
    
    // UI elements
    private var backButton: SKShapeNode!
    private var titleLabel: SKLabelNode!
    private var characterNodes: [SKNode] = []
    private var coinsLabel: SKLabelNode!
    
    // Character selection
    private var selectedIndex: Int = 0
    private var characters: [CharacterManager.Aircraft] = []
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
    }
    
    private func setupScene() {
        // Set background color
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Add background elements (ensure behind tiles)
        addCloudsBackground()
    }
    
    private func setupUI() {
        // Title (lower to avoid notch)
        titleLabel = SKLabelNode(text: "Characters")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 40
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        // Back button
        createBackButton()
        
        // Display currency
        setupCurrencyDisplay()
        
        // Load characters
        loadCharacters()
        
        // Display characters
        displayCharacters()
    }
    
    private func createBackButton() {
        backButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        backButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        backButton.strokeColor = .white
        backButton.lineWidth = 2
        // Keep back button clear of the notch
        backButton.position = CGPoint(x: 80, y: size.height - 120)
        backButton.zPosition = 10
        backButton.name = "backButton"
        
        let backLabel = SKLabelNode(text: "Back")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 20
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backLabel.horizontalAlignmentMode = .center
        backLabel.zPosition = 1
        backButton.addChild(backLabel)
        
        addChild(backButton)
    }
    
    private func setupCurrencyDisplay() {
        // Coins icon
        let coinsIcon = SKLabelNode(text: "🪙")
        coinsIcon.fontSize = 24
        coinsIcon.position = CGPoint(x: size.width - 100, y: size.height - 40)
        coinsIcon.zPosition = 10
        addChild(coinsIcon)
        
        // Coins value
        coinsLabel = SKLabelNode(text: "\(currencyManager.getCoins())")
        coinsLabel.fontName = "AvenirNext-Medium"
        coinsLabel.fontSize = 20
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: size.width - 80, y: size.height - 40)
        coinsLabel.zPosition = 10
        addChild(coinsLabel)
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
        // Clear existing character nodes
        for node in characterNodes {
            node.removeFromParent()
        }
        characterNodes.removeAll()
        
        // Setup grid layout
        let startX = size.width * 0.2
        // Raise grid and tighten spacing for better visibility; enable more items per screen
        let startY = size.height * 0.68
        let xSpacing = size.width * 0.3
        let ySpacing = size.height * 0.22
        
        for (index, aircraft) in characters.enumerated() {
            let row = index / 3
            let col = index % 3
            
            let x = startX + CGFloat(col) * xSpacing
            let y = startY - CGFloat(row) * ySpacing
            
            let node = createCharacterNode(aircraft: aircraft, isSelected: index == selectedIndex, position: CGPoint(x: x, y: y))
            node.name = "character_\(index)"
            characterNodes.append(node)
            addChild(node)
        }
    }
    
    private func createCharacterNode(aircraft: CharacterManager.Aircraft, isSelected: Bool, position: CGPoint) -> SKNode {
        let containerNode = SKNode()
        containerNode.position = position
        containerNode.zPosition = 5
        
        // Create frame
        let frameSize = CGSize(width: 100, height: 100)
        let frame = SKShapeNode(rectOf: frameSize, cornerRadius: 10)
        frame.fillColor = isSelected ? .white : UIColor(white: 0.8, alpha: 0.5)
        frame.strokeColor = isSelected ? .yellow : .white
        frame.lineWidth = isSelected ? 3 : 1
        containerNode.addChild(frame)
        
        // Create character sprite
        let characterSprite = characterManager.createAircraftSprite(for: aircraft.type)
        characterSprite.setScale(0.8)
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
        coinsLabel.text = "\(currencyManager.getCoins())"
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
    
    private func addCloudsBackground() {
        // Add clouds in the background
        for _ in 0..<10 {
            let cloud = createCloud()
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            cloud.zPosition = -5
            addChild(cloud)
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
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            for node in touchedNodes {
                if node.name == "backButton" || node.parent?.name == "backButton" {
                    handleBackButton()
                    return
                }
                
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
    }
    
    private func handleBackButton() {
        // Transition back to main menu
        let mainMenu = MainMenuScene(size: size)
        mainMenu.scaleMode = scaleMode
        view?.presentScene(mainMenu, transition: SKTransition.fade(withDuration: 0.5))
    }
}