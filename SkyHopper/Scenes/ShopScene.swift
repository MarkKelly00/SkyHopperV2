import SpriteKit
import StoreKit

class ShopScene: SKScene, CurrencyManagerDelegate, StoreKitManagerDelegate {
    
    // Currency manager
    private let currencyManager = CurrencyManager.shared
    
    // StoreKit manager for IAP
    private let storeKitManager = StoreKitManager.shared
    
    // UI elements
    private var backButton: SKShapeNode!
    private var coinsLabel: SKLabelNode!
    private var gemsLabel: SKLabelNode!
    private var shopItems: [SKNode] = []
    private var decorLayer = SKNode()
    private var topBar = SKNode()
    
    // Loading overlay
    private var loadingOverlay: SKNode?
    
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
        
        // Set up delegates
        currencyManager.delegate = self
        storeKitManager.delegate = self
        
        // Load products if not already loaded
        Task { @MainActor in
            if storeKitManager.products.isEmpty {
                showLoadingOverlay(message: "Loading Store...")
                await storeKitManager.loadProducts()
                hideLoadingOverlay()
            }
            showTabContent(.coins)
        }
        
        #if DEBUG
        UILinter.run(scene: self, topBar: topBar)
        #endif
    }
    
    // MARK: - Currency Manager Delegate
    
    func currencyDidChange() {
        SafeAreaTopBar.updateCurrency(in: topBar)
    }
    
    // MARK: - StoreKit Manager Delegate
    
    func purchaseDidComplete(productID: String, success: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingOverlay()
            
            if success {
                self?.showMessage("Purchase Successful! ✓")
            } else {
                self?.showMessage("Purchase Failed")
            }
        }
    }
    
    func purchaseDidDeliver(productID: String, coins: Int) {
        DispatchQueue.main.async { [weak self] in
            if coins > 0 {
                self?.showMessage("+\(coins) Coins! 🪙")
            }
            // Refresh currency display
            self?.currencyDidChange()
        }
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
        createRestoreButton()
    }
    
    private func createRestoreButton() {
        let safeArea = SafeAreaLayout(scene: self)
        
        // Create restore purchases button at bottom
        let restoreButton = SKShapeNode(rectOf: CGSize(width: 180, height: 36), cornerRadius: 18)
        restoreButton.fillColor = UIColor(white: 0.3, alpha: 0.8)
        restoreButton.strokeColor = .white
        restoreButton.lineWidth = 1
        restoreButton.position = CGPoint(x: size.width / 2, y: safeArea.safeBottomY(offset: 30))
        restoreButton.zPosition = UIConstants.Z.ui
        restoreButton.name = "restoreButton"
        addChild(restoreButton)
        
        let restoreLabel = SKLabelNode(text: "Restore Purchases")
        restoreLabel.fontName = "AvenirNext-Medium"
        restoreLabel.fontSize = 14
        restoreLabel.fontColor = .white
        restoreLabel.verticalAlignmentMode = .center
        restoreButton.addChild(restoreLabel)
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
        
        // Calculate visible area (leave room for restore button)
        visibleHeight = contentTop - 80  // Leave padding at bottom for restore button
        
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
        
        let compact = size.width < 420
        let tabHeight: CGFloat = compact ? 36 : 40
        let availableWidth = size.width - 24
        let tabWidth = availableWidth / 4
        let startX = (size.width - availableWidth) / 2 + tabWidth / 2
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
                position: CGPoint(x: startX + tabWidth * CGFloat(index), y: tabY),
                isSelected: tab == currentTab,
                tag: index,
                width: tabWidth - 6
            )
            tabButtons.append(tabButton)
            addChild(tabButton)
        }
    }
    
    private func createTabButton(title: String, position: CGPoint, isSelected: Bool, tag: Int, width: CGFloat) -> SKShapeNode {
        let compact = size.width < 420
        let buttonHeight: CGFloat = compact ? 36 : 40
        let tabButton = SKShapeNode(rectOf: CGSize(width: width, height: buttonHeight), cornerRadius: 10)
        tabButton.fillColor = isSelected ? .blue : UIColor(white: 0.7, alpha: 0.5)
        tabButton.strokeColor = isSelected ? .white : UIColor(white: 0.8, alpha: 0.8)
        tabButton.lineWidth = isSelected ? 2 : 1
        tabButton.position = position
        tabButton.zPosition = 10
        tabButton.name = "tab_\(tag)"
        
        let tabLabel = SKLabelNode(text: title)
        tabLabel.fontName = "AvenirNext-Medium"
        tabLabel.fontSize = compact ? 14 : 18
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
        
        // Get real products from StoreKit
        let coinProducts = storeKitManager.coinPackProducts
        
        if coinProducts.isEmpty {
            // Show clear message if products aren't loaded (e.g., not submitted for review)
            let unavailableText = storeKitManager.errorMessage ?? "Store unavailable. Products pending review or network issue."
            let message = SKLabelNode(text: unavailableText)
            message.fontName = "AvenirNext-Medium"
            message.fontSize = 16
            message.position = CGPoint(x: 0, y: 0)
            message.zPosition = 10
            shopItems.append(message)
            scrollContainer.addChild(message)
            
            contentHeight = 100
            return
        }
        
        let spacing: CGFloat = 115
        contentHeight = CGFloat(coinProducts.count) * spacing + 50
        let startY = visibleHeight / 2 - 60
        
        for (index, product) in coinProducts.enumerated() {
            // Get coin amount from ProductID
            let productID = StoreKitManager.ProductID(rawValue: product.id)
            let coinAmount = productID?.coinAmount ?? 0
            
            let item = createShopItem(
                title: product.displayName,
                description: "\(coinAmount) coins",
                price: product.displayPrice,
                icon: "🪙",
                position: CGPoint(x: 0, y: startY - spacing * CGFloat(index)),
                productID: product.id
            )
            item.name = "coin_package_\(index)"
            shopItems.append(item)
            scrollContainer.addChild(item)
        }
    }
    
    private func showPowerUpsShop() {
        guard scrollContainer != nil else { return }
        
        // Power-up packages (using in-game currency)
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
                position: CGPoint(x: 0, y: startY - spacing * CGFloat(index)),
                productID: nil  // Not an IAP product
            )
            item.name = "powerup_package_\(index)"
            item.userData = ["coinPrice": package.2]
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
        
        // Theme packages (using in-game currency)
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
                position: CGPoint(x: 0, y: startY - spacing * CGFloat(index)),
                productID: nil  // Not an IAP product
            )
            item.name = "theme_package_\(index)"
            item.userData = ["coinPrice": package.2]
            shopItems.append(item)
            scrollContainer.addChild(item)
        }
    }
    
    private func createShopItem(title: String, description: String, price: String, icon: String, position: CGPoint, productID: String?) -> SKNode {
        let containerNode = SKNode()
        containerNode.position = position
        containerNode.zPosition = 10
        
        // Store product ID for IAP items
        if let productID = productID {
            containerNode.userData = containerNode.userData ?? NSMutableDictionary()
            containerNode.userData?["productID"] = productID
        }
        
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
        
        // Add purchase button - green for IAP (real money), blue for in-game currency
        let buyButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        buyButton.fillColor = productID != nil 
            ? UIColor(red: 0.0, green: 0.6, blue: 0.3, alpha: 1.0)  // Green for real money
            : UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)  // Blue for coins
        buyButton.strokeColor = .white
        buyButton.lineWidth = 1
        buyButton.position = CGPoint(x: background.frame.width/2 - 60, y: 0)
        buyButton.name = "buy_\(title.replacingOccurrences(of: " ", with: "_"))"
        containerNode.addChild(buyButton)
        
        // Add price label
        let priceLabel = SKLabelNode(text: price)
        priceLabel.fontName = "AvenirNext-Bold"
        priceLabel.fontSize = 14
        priceLabel.fontColor = .white
        priceLabel.verticalAlignmentMode = .center
        priceLabel.horizontalAlignmentMode = .center
        buyButton.addChild(priceLabel)
        
        return containerNode
    }
    
    // MARK: - Loading Overlay
    
    private func showLoadingOverlay(message: String = "Processing...") {
        guard loadingOverlay == nil else { return }
        
        let overlay = SKNode()
        overlay.zPosition = 1000
        
        // Dark background
        let background = SKShapeNode(rectOf: size)
        background.fillColor = UIColor(white: 0, alpha: 0.7)
        background.strokeColor = .clear
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(background)
        
        // Loading container
        let container = SKShapeNode(rectOf: CGSize(width: 200, height: 100), cornerRadius: 15)
        container.fillColor = UIColor(white: 0.2, alpha: 0.95)
        container.strokeColor = .white
        container.lineWidth = 2
        container.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(container)
        
        // Loading text
        let loadingLabel = SKLabelNode(text: message)
        loadingLabel.fontName = "AvenirNext-Bold"
        loadingLabel.fontSize = 18
        loadingLabel.fontColor = .white
        loadingLabel.verticalAlignmentMode = .center
        loadingLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(loadingLabel)
        
        // Spinner animation
        let spinner = SKLabelNode(text: "⟳")
        spinner.fontSize = 30
        spinner.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        let rotate = SKAction.rotate(byAngle: -.pi * 2, duration: 1.0)
        spinner.run(SKAction.repeatForever(rotate))
        overlay.addChild(spinner)
        
        addChild(overlay)
        loadingOverlay = overlay
    }
    
    private func hideLoadingOverlay() {
        loadingOverlay?.removeFromParent()
        loadingOverlay = nil
    }
    
    // MARK: - Purchase Handling
    
    private func handlePurchase(itemName: String, node: SKNode) {
        if let _ = node.userData?["productID"], !storeKitManager.isStoreReady {
            showMessage("Store unavailable. Please try again later.")
            return
        }
        
        // Check if this is an IAP product
        if let productID = node.userData?["productID"] as? String {
            // Real money purchase via StoreKit
            handleIAPPurchase(productID: productID)
        } else if let coinPrice = node.userData?["coinPrice"] as? Int {
            // In-game currency purchase
            handleCoinPurchase(itemName: itemName, coinPrice: coinPrice)
        }
    }
    
    private func handleIAPPurchase(productID: String) {
        guard let product = storeKitManager.products.first(where: { $0.id == productID }) else {
            showMessage("Product not available")
            return
        }
        
        showLoadingOverlay(message: "Processing Purchase...")
        
        Task { @MainActor in
            let success = await storeKitManager.purchase(product)
            hideLoadingOverlay()
            
            if !success && storeKitManager.errorMessage == nil {
                // User cancelled, no message needed
            }
        }
    }
    
    private func handleCoinPurchase(itemName: String, coinPrice: Int) {
        if currencyManager.spendCoins(coinPrice) {
            showMessage("Purchased \(itemName)!")
            // TODO: Grant the purchased item (power-up, theme, etc.)
        } else {
            showMessage("Not enough coins!")
        }
    }
    
    private func handleRestorePurchases() {
        showLoadingOverlay(message: "Restoring Purchases...")
        
        Task { @MainActor in
            await storeKitManager.restorePurchases()
            hideLoadingOverlay()
            showMessage("Purchases Restored!")
        }
    }
    
    private func updateCurrencyDisplay() {
        coinsLabel?.text = "\(currencyManager.getCoins())"
        gemsLabel?.text = "\(currencyManager.getGems())"
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
        let wait = SKAction.wait(forDuration: 1.5)
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
            
            // Check for restore button
            if node.name == "restoreButton" || node.parent?.name == "restoreButton" {
                handleRestorePurchases()
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
                // Find the parent container node that has the product info
                if let containerNode = node.parent {
                    handlePurchase(itemName: name, node: containerNode)
                }
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isScrolling, let container = scrollContainer else { return }
        
        let location = touch.location(in: self)
        let deltaY = location.y - lastTouchY
        // CORRECTED iOS-style scrolling:
        // Swipe UP (negative deltaY) = show content below (move container UP = positive position)
        // Swipe DOWN (positive deltaY) = show content above (move container DOWN = negative position)
        container.position.y -= deltaY  // INVERTED for correct iOS direction
        scrollVelocity = -deltaY * 0.8 + scrollVelocity * 0.2  // Invert velocity too
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
        guard isScrolling, let container = scrollContainer else {
            isScrolling = false
            return
        }
        
        isScrolling = false
        
        // Calculate scroll bounds (matching touchesMoved)
        let maxScrollUp: CGFloat = max(contentHeight - visibleHeight, 0)
        let maxScrollDown: CGFloat = 0
        
        // Apply momentum scrolling with corrected direction
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
