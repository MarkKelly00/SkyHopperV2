import SpriteKit

class ShopScene: SKScene {
    
    // Currency manager
    private let currencyManager = CurrencyManager.shared
    
    // UI elements
    private var backButton: SKShapeNode!
    private var coinsLabel: SKLabelNode!
    private var gemsLabel: SKLabelNode!
    private var shopItems: [SKNode] = []
    
    // Tab control
    private var tabButtons: [SKShapeNode] = []
    private enum ShopTab {
        case coins
        case powerUps
        case characters
        case themes
    }
    private var currentTab: ShopTab = .coins
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
        showTabContent(.coins)
    }
    
    private func setupScene() {
        // Set background color
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Add background elements behind UI
        addCloudsBackground()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(text: "Shop")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 32
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        titleLabel.zPosition = 20
        addChild(titleLabel)
        
        // Back button
        createBackButton()
        
        // Display currency
        setupCurrencyDisplay()
        
        // Setup tab buttons
        createTabButtons()
    }
    
    private func createBackButton() {
        backButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        backButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        backButton.strokeColor = .white
        backButton.lineWidth = 2
        backButton.position = CGPoint(x: 80, y: size.height - 100)
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
        // Coins display
        let coinsIcon = SKLabelNode(text: "🪙")
        coinsIcon.fontSize = 24
        coinsIcon.position = CGPoint(x: size.width - 130, y: size.height - 40)
        coinsIcon.zPosition = 10
        addChild(coinsIcon)
        
        coinsLabel = SKLabelNode(text: "\(currencyManager.getCoins())")
        coinsLabel.fontName = "AvenirNext-Medium"
        coinsLabel.fontSize = 20
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: size.width - 110, y: size.height - 40)
        coinsLabel.zPosition = 10
        addChild(coinsLabel)
        
        // Gems display
        let gemsIcon = SKLabelNode(text: "💎")
        gemsIcon.fontSize = 24
        gemsIcon.position = CGPoint(x: size.width - 70, y: size.height - 40)
        gemsIcon.zPosition = 10
        addChild(gemsIcon)
        
        gemsLabel = SKLabelNode(text: "\(currencyManager.getGems())")
        gemsLabel.fontName = "AvenirNext-Medium"
        gemsLabel.fontSize = 20
        gemsLabel.horizontalAlignmentMode = .left
        gemsLabel.position = CGPoint(x: size.width - 50, y: size.height - 40)
        gemsLabel.zPosition = 10
        addChild(gemsLabel)
    }
    
    private func createTabButtons() {
        let tabWidth = size.width / 4
        let _: CGFloat = 40 // Was tabHeight but unused
        let tabY = size.height - 140
        
        // Create tab buttons
        let tabConfigs = [
            ("Coins", ShopTab.coins),
            ("Power-ups", ShopTab.powerUps),
            ("Characters", ShopTab.characters),
            ("Themes", ShopTab.themes)
        ]
        
        for (index, (title, tab)) in tabConfigs.enumerated() {
            let tabButton = createTabButton(
                title: title,
                position: CGPoint(x: tabWidth * CGFloat(index) + tabWidth/2, y: tabY),
                isSelected: tab == currentTab,
                tag: index
            )
            tabButtons.append(tabButton)
            addChild(tabButton)
        }
    }
    
    private func createTabButton(title: String, position: CGPoint, isSelected: Bool, tag: Int) -> SKShapeNode {
        let tabButton = SKShapeNode(rectOf: CGSize(width: size.width/4 - 10, height: 40), cornerRadius: 10)
        tabButton.fillColor = isSelected ? .blue : UIColor(white: 0.7, alpha: 0.5)
        tabButton.strokeColor = isSelected ? .white : UIColor(white: 0.8, alpha: 0.8)
        tabButton.lineWidth = isSelected ? 2 : 1
        tabButton.position = position
        tabButton.zPosition = 10
        tabButton.name = "tab_\(tag)"
        
        let tabLabel = SKLabelNode(text: title)
        tabLabel.fontName = "AvenirNext-Medium"
        tabLabel.fontSize = 18
        tabLabel.fontColor = isSelected ? .white : UIColor(white: 0.2, alpha: 1.0)
        tabLabel.verticalAlignmentMode = .center
        tabLabel.horizontalAlignmentMode = .center
        tabButton.addChild(tabLabel)
        
        return tabButton
    }
    
    private func updateTabButtons() {
        for (index, button) in tabButtons.enumerated() {
            let isSelected = (index == currentTab.hashValue)
            button.fillColor = isSelected ? .blue : UIColor(white: 0.7, alpha: 0.5)
            button.strokeColor = isSelected ? .white : UIColor(white: 0.8, alpha: 0.8)
            button.lineWidth = isSelected ? 2 : 1
            
            if let label = button.children.first as? SKLabelNode {
                label.fontColor = isSelected ? .white : UIColor(white: 0.2, alpha: 1.0)
            }
        }
    }
    
    private func clearShopItems() {
        for item in shopItems {
            item.removeFromParent()
        }
        shopItems.removeAll()
    }
    
    private func showTabContent(_ tab: ShopTab) {
        // Update current tab
        currentTab = tab
        updateTabButtons()
        
        // Clear existing content
        clearShopItems()
        
        // Show appropriate content
        switch tab {
        case .coins:
            showCoinsShop()
        case .powerUps:
            showPowerUpsShop()
        case .characters:
            showCharactersShop()
        case .themes:
            showThemesShop()
        }
    }
    
    // MARK: - Shop Content
    
    private func showCoinsShop() {
        // Coin packages
        let packages = [
            ("Small Pack", 500, 0.99),
            ("Medium Pack", 1500, 2.99),
            ("Large Pack", 5000, 9.99),
            ("Mega Pack", 12000, 19.99)
        ]
        
        let startY = size.height - 220
        let spacing = 120.0
        
        for (index, package) in packages.enumerated() {
            let item = createShopItem(
                title: package.0,
                description: "\(package.1) coins",
                price: "$\(package.2)",
                icon: "🪙",
                position: CGPoint(x: size.width / 2, y: startY - spacing * Double(index))
            )
            item.name = "coin_package_\(index)"
            shopItems.append(item)
            addChild(item)
        }
    }
    
    private func showPowerUpsShop() {
        // Power-up packages
        let packages = [
            ("Extra Life", "One-time revival", 1000, "❤️"),
            ("3x Shield", "Block 3 obstacles", 800, "🛡️"),
            ("3x Speed Boost", "Move faster", 600, "⚡️"),
            ("Missiles (2)", "Destroy obstacles", 2000, "🚀"),
            ("Sidewinders (4)", "Auto-targeting missiles", 3000, "🎯"),
            ("Double Time", "2x power-up duration", 1500, "⏱️")
        ]
        
        let startY = size.height - 220
        let spacing = 120.0
        
        for (index, package) in packages.enumerated() {
            let item = createShopItem(
                title: package.0,
                description: package.1,
                price: "\(package.2) 🪙",
                icon: package.3,
                position: CGPoint(x: size.width / 2, y: startY - spacing * Double(index))
            )
            item.name = "powerup_package_\(index)"
            shopItems.append(item)
            addChild(item)
        }
    }
    
    private func showCharactersShop() {
        // Message that this is available in Characters screen
        let message = SKLabelNode(text: "Characters are available in the Characters menu")
        message.fontName = "AvenirNext-Medium"
        message.fontSize = 20
        message.position = CGPoint(x: size.width / 2, y: size.height / 2)
        message.zPosition = 10
        shopItems.append(message)
        addChild(message)
    }
    
    private func showThemesShop() {
        // Theme packages
        let packages = [
            ("Forest Theme", "Play in the forest", 2000, "🌳"),
            ("Mountain Theme", "Mountain adventure", 3000, "🏔️"),
            ("Space Theme", "Outer space flight", 5000, "🚀"),
            ("Underwater Theme", "Underwater journey", 4000, "🌊")
        ]
        
        let startY = size.height - 220
        let spacing = 120.0
        
        for (index, package) in packages.enumerated() {
            let item = createShopItem(
                title: package.0,
                description: package.1,
                price: "\(package.2) 🪙",
                icon: package.3,
                position: CGPoint(x: size.width / 2, y: startY - spacing * Double(index))
            )
            item.name = "theme_package_\(index)"
            shopItems.append(item)
            addChild(item)
        }
    }
    
    private func createShopItem(title: String, description: String, price: String, icon: String, position: CGPoint) -> SKNode {
        let containerNode = SKNode()
        containerNode.position = position
        containerNode.zPosition = 10
        
        // Create background
        let background = SKShapeNode(rectOf: CGSize(width: size.width - 60, height: 100), cornerRadius: 15)
        background.fillColor = UIColor(white: 1.0, alpha: 0.3)
        background.strokeColor = .white
        background.lineWidth = 1
        containerNode.addChild(background)
        
        // Add icon
        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = 40
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.position = CGPoint(x: -background.frame.width/2 + 40, y: 0)
        containerNode.addChild(iconLabel)
        
        // Add title
        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 20
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .bottom
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: -background.frame.width/2 + 80, y: 10)
        containerNode.addChild(titleLabel)
        
        // Add description
        let descLabel = SKLabelNode(text: description)
        descLabel.fontName = "AvenirNext-Medium"
        descLabel.fontSize = 16
        descLabel.fontColor = UIColor(white: 0.9, alpha: 1.0)
        descLabel.verticalAlignmentMode = .top
        descLabel.horizontalAlignmentMode = .left
        descLabel.position = CGPoint(x: -background.frame.width/2 + 80, y: -10)
        containerNode.addChild(descLabel)
        
        // Add purchase button
        let buyButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        buyButton.fillColor = UIColor(red: 0.0, green: 0.6, blue: 0.3, alpha: 1.0)
        buyButton.strokeColor = .white
        buyButton.lineWidth = 1
        buyButton.position = CGPoint(x: background.frame.width/2 - 60, y: 0)
        buyButton.name = "buy_\(title.replacingOccurrences(of: " ", with: "_"))"
        containerNode.addChild(buyButton)
        
        // Add price label
        let priceLabel = SKLabelNode(text: price)
        priceLabel.fontName = "AvenirNext-Bold"
        priceLabel.fontSize = 16
        priceLabel.fontColor = .white
        priceLabel.verticalAlignmentMode = .center
        priceLabel.horizontalAlignmentMode = .center
        buyButton.addChild(priceLabel)
        
        return containerNode
    }
    
    // MARK: - Purchase Handling
    
    private func handlePurchase(itemName: String) {
        // This is where actual purchase logic would go
        // For now, just show a message
        showMessage("Purchase feature will be available soon!")
        
        // For demo purposes, add some coins
        if itemName == "buy_Small_Pack" {
            // Add some free coins for testing
            _ = currencyManager.addCoins(100)
            updateCurrencyDisplay()
            showMessage("+100 Coins (Demo)")
        }
    }
    
    private func updateCurrencyDisplay() {
        coinsLabel.text = "\(currencyManager.getCoins())"
        gemsLabel.text = "\(currencyManager.getGems())"
    }
    
    // MARK: - Helpers
    
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
                
                // Check for tab selection
                if let name = node.name, name.starts(with: "tab_"), 
                   let indexStr = name.split(separator: "_").last, let index = Int(indexStr) {
                    if index == 0 {
                        showTabContent(.coins)
                    } else if index == 1 {
                        showTabContent(.powerUps)
                    } else if index == 2 {
                        showTabContent(.characters)
                    } else if index == 3 {
                        showTabContent(.themes)
                    }
                    return
                }
                
                // Check for buy button
                if let name = node.name, name.starts(with: "buy_") {
                    handlePurchase(itemName: name)
                    return
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