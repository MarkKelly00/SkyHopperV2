import SpriteKit

/// Helper to create a consistent safe-area top bar with a back button and centered title.
final class SafeAreaTopBar {
    /// Updates the currency display in the top bar with current values from CurrencyManager
    static func updateCurrency(in topBar: SKNode) {
        let currencyManager = CurrencyManager.shared
        if let coinsLabel = topBar.childNode(withName: "topbar_coinsLabel") as? SKLabelNode {
            coinsLabel.text = "\(currencyManager.getCoins())"
        }
        if let gemsLabel = topBar.childNode(withName: "topbar_gemsLabel") as? SKLabelNode {
            gemsLabel.text = "\(currencyManager.getGems())"
        }
    }
    static func build(in scene: SKScene, title: String, backAction: @escaping () -> Void) -> SKNode {
        let container = SKNode()
        container.zPosition = UIConstants.Z.topBar
        scene.addChild(container)

        let safe = SafeAreaLayout(scene: scene)

        // Title
        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = UIConstants.Text.titleFont
        titleLabel.fontSize = 34
        titleLabel.zPosition = UIConstants.Z.title
        container.addChild(titleLabel)
        // Place title below the back button to create a clear top-bar band
        let titleHeight = titleLabel.frame.height
        let backSize = CGSize(width: 84, height: 36)
        // Back button baseline (safe-area aware)
        let backY = safe.safeTopY(offset: UIConstants.Spacing.xsmall + backSize.height/2)
        // Title sits below the back button with a medium spacing to create a top band for tabs
        let titleYOffset = UIConstants.Spacing.medium + backSize.height + UIConstants.Spacing.medium + (titleHeight / 2)
        titleLabel.position = CGPoint(x: scene.size.width / 2, y: safe.safeTopY(offset: titleYOffset))

        // Back button
        let backButton = SKShapeNode(rectOf: backSize, cornerRadius: UIConstants.Radius.medium)
        backButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 0.9)
        backButton.strokeColor = .white
        backButton.lineWidth = 2
        backButton.name = "backButton"
        backButton.position = CGPoint(
            x: safe.safeLeftX(offset: UIConstants.Spacing.medium + backSize.width/2),
            y: backY
        )

        let backLabel = SKLabelNode(text: "Back")
        backLabel.fontName = UIConstants.Text.boldFont
        backLabel.fontSize = 18
        backLabel.verticalAlignmentMode = .center
        backLabel.horizontalAlignmentMode = .center
        backButton.addChild(backLabel)
        container.addChild(backButton)

        // Touch handling proxy
        let proxy = TopBarTouchProxy(backAction: backAction)
        proxy.isUserInteractionEnabled = true
        proxy.zPosition = backButton.zPosition + 1
        proxy.name = "backProxy"
        proxy.frameNode = backButton
        container.addChild(proxy)

        // Add a right-aligned currency row inside the top bar (safe-area aware)
        let rightX = safe.safeRightX(offset: UIConstants.Spacing.xlarge)
        let currencyTopY = backY - (UIConstants.Spacing.xsmall / 2)

        let coinsIcon = SKLabelNode(text: "🪙")
        coinsIcon.name = "topbar_coinsIcon"
        coinsIcon.fontSize = 20
        coinsIcon.position = CGPoint(x: rightX - 100, y: currencyTopY)
        coinsIcon.zPosition = UIConstants.Z.ui
        container.addChild(coinsIcon)

        let coinsLabel = SKLabelNode(text: "\(CurrencyManager.shared.getCoins())")
        coinsLabel.name = "topbar_coinsLabel"
        coinsLabel.fontName = UIConstants.Text.mediumFont
        coinsLabel.fontSize = 16
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: rightX - 80, y: currencyTopY - 2)
        coinsLabel.zPosition = UIConstants.Z.ui
        container.addChild(coinsLabel)

        let gemsIcon = SKLabelNode(text: "💎")
        gemsIcon.name = "topbar_gemsIcon"
        gemsIcon.fontSize = 20
        gemsIcon.position = CGPoint(x: rightX - 40, y: currencyTopY)
        gemsIcon.zPosition = UIConstants.Z.ui
        container.addChild(gemsIcon)

        let gemsLabel = SKLabelNode(text: "\(CurrencyManager.shared.getGems())")
        gemsLabel.name = "topbar_gemsLabel"
        gemsLabel.fontName = UIConstants.Text.mediumFont
        gemsLabel.fontSize = 16
        gemsLabel.horizontalAlignmentMode = .left
        gemsLabel.position = CGPoint(x: rightX - 18, y: currencyTopY - 2)
        gemsLabel.zPosition = UIConstants.Z.ui
        container.addChild(gemsLabel)

        // Expose top bar metrics for downstream layout (e.g., tabs/grid)
        let bottomY = titleLabel.position.y - titleHeight / 2
        let topBarHeight = (scene.size.height - safe.safeTopY()) - bottomY
        container.userData = NSMutableDictionary()
        container.userData?["topBarBottomY"] = bottomY
        container.userData?["topBarHeight"] = topBarHeight

        return container
    }
}

/// Transparent node to capture touches on back button reliably.
private final class TopBarTouchProxy: SKNode {
    let backAction: () -> Void
    weak var frameNode: SKShapeNode?
    init(backAction: @escaping () -> Void) {
        self.backAction = backAction
        super.init()
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let f = frameNode else { return }
        let p = t.location(in: parent!)
        if f.contains(p) { backAction() }
    }
}


