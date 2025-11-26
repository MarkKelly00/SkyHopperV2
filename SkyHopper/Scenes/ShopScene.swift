import SpriteKit

class ShopScene: SKScene, CurrencyManagerDelegate {
    
    // Currency manager
    private let currencyManager = CurrencyManager.shared
    
    // UI elements
    private var backButton: SKShapeNode!
    private var coinsLabel: SKLabelNode!
    private var gemsLabel: SKLabelNode!
    private var shopItems: [SKNode] = []
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
        
        // Decor layer behind UI
        decorLayer.removeFromParent()
        decorLayer = SKNode()
        decorLayer.zPosition = UIConstants.Z.decor
        addChild(decorLayer)
        addCloudsBackground(into: decorLayer)
    }
    
    private func setupUI() {
        // Top bar via helper (creates title + currency row)
        topBar.removeFromParent()
        topBar = SafeAreaTopBar.build(in: self, title: "Shop") { [weak self] in
            self?.handleBackButton()
        }

        // Back button / currency row handled by topBar
        createTabButtons()
        setupScrollContainer()
    }
    
    private func setupScrollContainer() {
        // Get topBar bottom position for proper content placement
        let topBarBottomY = topBar.userData?["topBarBottomY"] as? CGFloat ?? (size.height - 120)
        let tabHeight: CGFloat = 60
        
        // Create crop node for masking scrollable content
        cropNode = SKCropNode()
        let contentTop = topBarBottomY - tabHeight - 20
        cropNode.position = CGPoint(x: size.width / 2, y: contentTop / 2)
        cropNode.zPosition = 5
        addChild(cropNode)
        
        // Calculate visible area
        visibleHeight = contentTop - 40  // Leave padding at bottom
        
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
    
    private func setupCurrencyDisplay() {
        // Coins display
        let safe = SafeAreaLayout(scene: self)

        // Right-aligned currency stack anchored to safe area to avoid Dynamic Island overlap
        _ = safe.safeRightX(offset: UIConstants.Spacing.xlarge)
        _ = safe.safeTopY(offset: UIConstants.Spacing.xsmall + 6)

        // Use safe area layout for currency display
        let safeArea = SafeAreaLayout(scene: self)
        let currencySafeTopY = safeArea.safeTopY(offset: -UIConstants.Spacing.medium) // Move up by 1rem for better fit
        
        // Coins display (left side of safe area)
        let coinsIcon = SKLabelNode(text: "🪙")
        coinsIcon.fontSize = 20
        coinsIcon.position = CGPoint(x: safeArea.safeLeftX() + 30, y: currencySafeTopY)
        coinsIcon.zPosition = UIConstants.Z.ui
        addChild(coinsIcon)

        coinsLabel = SKLabelNode(text: "\(currencyManager.getCoins())")
        coinsLabel.fontName = "AvenirNext-Medium"
        coinsLabel.fontSize = 18
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: safeArea.safeLeftX() + 55, y: currencySafeTopY)
        coinsLabel.zPosition = UIConstants.Z.ui
        addChild(coinsLabel)

        // Gems display (right side of safe area)
        let gemsIcon = SKLabelNode(text: "💎")
        gemsIcon.fontSize = 20
        gemsIcon.position = CGPoint(x: safeArea.safeRightX() - 55, y: currencySafeTopY)
        gemsIcon.zPosition = UIConstants.Z.ui
        addChild(gemsIcon)

        gemsLabel = SKLabelNode(text: "\(currencyManager.getGems())")
        gemsLabel.fontName = "AvenirNext-Medium"
        gemsLabel.fontSize = 18
        gemsLabel.horizontalAlignmentMode = .right
        gemsLabel.position = CGPoint(x: safeArea.safeRightX() - 30, y: currencySafeTopY)
        gemsLabel.zPosition = UIConstants.Z.ui
        addChild(gemsLabel)
    }
    
    private func createTabButtons() {
        // Get topBar metrics for proper positioning
        let topBarBottomY = topBar.userData?["topBarBottomY"] as? CGFloat ?? (size.height - 120)
        
        let tabWidth = size.width / 4
        let tabHeight: CGFloat = 40
        let tabY = topBarBottomY - tabHeight/2 - UIConstants.Spacing.small
        
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
        scrollContainer?.removeAllChildren()
        scrollContainer?.position = CGPoint(x: 0, y: 0)  // Reset scroll position
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
        guard scrollContainer != nil else { return }
        
        // Coin packages
        let packages = [
            ("Small Pack", 500, 0.99),
            ("Medium Pack", 1500, 2.99),
            ("Large Pack", 5000, 9.99),
            ("Mega Pack", 12000, 19.99)
        ]
        
        let spacing: CGFloat = 115
        contentHeight = CGFloat(packages.count) * spacing + 50
        let startY = visibleHeight / 2 - 60
        
        for (index, package) in packages.enumerated() {
            let item = createShopItem(
                title: package.0,
                description: "\(package.1) coins",
                price: "$\(package.2)",
                icon: "🪙",
                position: CGPoint(x: 0, y: startY - spacing * CGFloat(index))
            )
            item.name = "coin_package_\(index)"
            shopItems.append(item)
            scrollContainer.addChild(item)
        }
    }
    
    private func showPowerUpsShop() {
        guard scrollContainer != nil else { return }
        
        // Power-up packages
        let packages = [
            ("Extra Life", "One-time revival", 1000, "❤️"),
            ("3x Shield", "Block 3 obstacles", 800, "🛡️"),
            ("3x Speed Boost", "Move faster", 600, "⚡️"),
            ("Missiles (2)", "Destroy obstacles", 2000, "🚀"),
            ("Sidewinders (4)", "Auto-targeting missiles", 3000, "🎯"),
            ("Double Time", "2x power-up duration", 1500, "⏱️")
        ]
        
        let spacing: CGFloat = 115
        contentHeight = CGFloat(packages.count) * spacing + 50
        let startY = visibleHeight / 2 - 60
        
        for (index, package) in packages.enumerated() {
            let item = createShopItem(
                title: package.0,
                description: package.1,
                price: "\(package.2) 🪙",
                icon: package.3,
                position: CGPoint(x: 0, y: startY - spacing * CGFloat(index))
            )
            item.name = "powerup_package_\(index)"
            shopItems.append(item)
            scrollContainer.addChild(item)
        }
    }
    
    private func showCharactersShop() {
        guard scrollContainer != nil else { return }
        
        contentHeight = 100
        
        // Message that this is available in Characters screen
        let message = SKLabelNode(text: "Characters are available in the Characters menu")
        message.fontName = "AvenirNext-Medium"
        message.fontSize = 20
        message.position = CGPoint(x: 0, y: 0)
        message.zPosition = 10
        shopItems.append(message)
        scrollContainer.addChild(message)
    }
    
    private func showThemesShop() {
        guard scrollContainer != nil else { return }
        
        // Theme packages
        let packages = [
            ("Forest Theme", "Play in the forest", 2000, "🌳"),
            ("Mountain Theme", "Mountain adventure", 3000, "🏔️"),
            ("Space Theme", "Outer space flight", 5000, "🚀"),
            ("Underwater Theme", "Underwater journey", 4000, "🌊")
        ]
        
        let spacing: CGFloat = 115
        contentHeight = CGFloat(packages.count) * spacing + 50
        let startY = visibleHeight / 2 - 60
        
        for (index, package) in packages.enumerated() {
            let item = createShopItem(
                title: package.0,
                description: package.1,
                price: "\(package.2) 🪙",
                icon: package.3,
                position: CGPoint(x: 0, y: startY - spacing * CGFloat(index))
            )
            item.name = "theme_package_\(index)"
            shopItems.append(item)
            scrollContainer.addChild(item)
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // Check for back button first
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
        }
        
        // Check if touch is within scroll area
        if let crop = cropNode, crop.contains(location) {
            isScrolling = true
            lastTouchY = location.y
            scrollVelocity = 0
            scrollContainer?.removeAction(forKey: "momentum")
        }
        
        // Check for buy button
        for node in touchedNodes {
            if let name = node.name, name.starts(with: "buy_") {
                handlePurchase(itemName: name)
                return
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
