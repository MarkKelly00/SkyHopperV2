import SpriteKit
import GameKit
import UIKit

class ModernLeaderboardScene: SKScene {
    
    // UI Elements
    private var backgroundGradient: SKSpriteNode!
    private var glassContainer: SKShapeNode!
    private var scrollContainer: SKNode!
    private var topBar: SKNode!
    
    // Tab System
    private var tabButtons: [TabButton] = []
    private var activeTab: LeaderboardTab = .global
    
    // Map selection
    private var mapSelector: SKNode!
    private var currentMapIndex = 0
    private let maps = ["city_escape", "forest_run", "mountain_climb", "space_adventure",
                       "underwater_quest", "desert_escape", "arctic_expedition", "volcano_rush",
                       "jungle_maze", "sky_fortress", "crystal_caverns", "neon_city",
                       "halloween_special", "christmas_special", "summer_special"]
    private var mapLabel: SKLabelNode!
    
    // Leaderboard Data
    private var globalEntries: [LeaderboardUser] = []
    private var friendsEntries: [LeaderboardUser] = []
    private var currentEntries: [LeaderboardUser] = []
    
    // Touch Handling
    private var lastTouchY: CGFloat = 0
    private var isScrolling = false
    private var scrollVelocity: CGFloat = 0
    
    // Animation
    private var glowEffects: [SKEffectNode] = []
    
    enum LeaderboardTab {
        case global
        case friends
        case weekly
        
        var title: String {
            switch self {
            case .global: return "Global"
            case .friends: return "Friends"
            case .weekly: return "This Week"
            }
        }
    }
    
    struct TabButton {
        let node: SKNode
        let tab: LeaderboardTab
        let background: SKShapeNode
        let label: SKLabelNode
        let icon: SKSpriteNode?
    }
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupGlassContainer()
        setupTopBar()
        setupTabs()
        setupScrollContainer()
        
        // Load initial data after all UI is setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.loadLeaderboardData()
        }
        
        // Add subtle animations
        // Note: addFloatingOrbs() and addShimmeringParticles() are called in setupBackground()
    }
    
    private func setupBackground() {
        // Create stunning animated gradient background
        let gradientTexture = SKTexture(size: size) { size, context in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0).cgColor,
                UIColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1.0).cgColor,
                UIColor(red: 0.15, green: 0.08, blue: 0.25, alpha: 1.0).cgColor,
                UIColor(red: 0.05, green: 0.12, blue: 0.2, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]

            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }

            context.drawLinearGradient(gradient,
                                     start: CGPoint(x: 0, y: size.height),
                                     end: CGPoint(x: 0, y: 0),
                                     options: [])
        }

        backgroundGradient = SKSpriteNode(texture: gradientTexture, size: size)
        backgroundGradient.position = CGPoint(x: size.width/2, y: size.height/2)
        backgroundGradient.zPosition = -100
        addChild(backgroundGradient)

        // Add animated floating orbs and particles
        addFloatingOrbs()
        addShimmeringParticles()
    }
    
    private func createAnimatedOverlay() -> SKNode {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor(white: 1.0, alpha: 0.02)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        
        // Subtle breathing animation
        let fadeIn = SKAction.fadeAlpha(to: 0.05, duration: 3.0)
        let fadeOut = SKAction.fadeAlpha(to: 0.02, duration: 3.0)
        overlay.run(SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut])))
        
        return overlay
    }
    
    private func setupMapSelector() {
        mapSelector = SKNode()
        mapSelector.position = CGPoint(x: size.width/2, y: size.height - 220)
        mapSelector.zPosition = 6  // Above tabs to ensure visibility
        addChild(mapSelector)
        
        // Map selector background
        let selectorBg = SKShapeNode(rectOf: CGSize(width: 280, height: 40), cornerRadius: 20)
        selectorBg.fillColor = UIColor(white: 0.1, alpha: 0.8)
        selectorBg.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        selectorBg.lineWidth = 1
        mapSelector.addChild(selectorBg)
        
        // Previous button
        let prevButton = createGlassButton(text: nil, icon: "chevron.left", size: CGSize(width: 36, height: 36))
        prevButton.position = CGPoint(x: -100, y: 0)
        prevButton.name = "prevMap"
        mapSelector.addChild(prevButton)
        
        // Map label
        mapLabel = SKLabelNode(text: formatMapName(maps[currentMapIndex]))
        mapLabel.fontName = "AvenirNext-Medium"
        mapLabel.fontSize = 16
        mapLabel.fontColor = .white
        mapLabel.position = CGPoint(x: 0, y: -5)
        mapSelector.addChild(mapLabel)
        
        // Next button
        let nextButton = createGlassButton(text: nil, icon: "chevron.right", size: CGSize(width: 36, height: 36))
        nextButton.position = CGPoint(x: 100, y: 0)
        nextButton.name = "nextMap"
        mapSelector.addChild(nextButton)
    }
    
    private func formatMapName(_ mapId: String) -> String {
        return mapId.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
    
    private func changeMap(direction: Int) {
        currentMapIndex = (currentMapIndex + direction + maps.count) % maps.count
        mapLabel.text = formatMapName(maps[currentMapIndex])
        
        // Reload leaderboard for new map
        loadLeaderboardData()
    }
    
    private func setupGlassContainer() {
        // Main glass container with modern design - properly centered
        let containerSize = CGSize(width: size.width - 40, height: size.height - 220)
        let glassPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -containerSize.width/2, y: -containerSize.height/2),
                                                         size: containerSize),
                                    cornerRadius: 24)
        
        glassContainer = SKShapeNode(path: glassPath.cgPath)
        glassContainer.position = CGPoint(x: size.width/2, y: size.height/2 - 20)
        glassContainer.zPosition = 1
        
        // Glass effect background with better contrast
        glassContainer.fillColor = UIColor(white: 0.1, alpha: 0.6)
        glassContainer.strokeColor = UIColor(white: 1.0, alpha: 0.3)
        glassContainer.lineWidth = 2.0
        
        // Add blur effect node
        let blurEffect = SKEffectNode()
        blurEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10])
        blurEffect.shouldRasterize = true
        
        // Inner glass highlight
        let innerGlass = SKShapeNode(path: glassPath.cgPath)
        innerGlass.fillColor = UIColor(white: 1.0, alpha: 0.05)
        innerGlass.strokeColor = .clear
        blurEffect.addChild(innerGlass)
        
        glassContainer.addChild(blurEffect)
        addChild(glassContainer)
        
        // Add glow effect
        addGlowEffect(to: glassContainer, color: .cyan, radius: 20)
    }
    
    private func setupTopBar() {
        topBar = SKNode()
        topBar.position = CGPoint(x: 0, y: size.height - 100)
        topBar.zPosition = 10
        addChild(topBar)
        
        // Back button with glass effect
        let backButton = createGlassButton(text: "Back", icon: "chevron.left", size: CGSize(width: 100, height: 34))
        backButton.position = CGPoint(x: 70, y: 0)
        backButton.name = "backButton"
        topBar.addChild(backButton)
        
        // Title - positioned above tabs, under notch for consistency
        let titleLabel = SKLabelNode(text: "Leaderboard")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: 36) // move up ~1rem
        topBar.addChild(titleLabel)
        
        // Profile button
        let profileButton = createGlassButton(text: nil, icon: "person.circle.fill", size: CGSize(width: 44, height: 44))
        profileButton.position = CGPoint(x: size.width - 160, y: 0)
        profileButton.name = "profileButton"
        topBar.addChild(profileButton)

        // Search friends button
        let searchButton = createGlassButton(text: nil, icon: "magnifyingglass", size: CGSize(width: 44, height: 44))
        searchButton.position = CGPoint(x: size.width - 105, y: 0)
        searchButton.name = "searchButton"
        topBar.addChild(searchButton)

        // Add friend button
        let addFriendButton = createGlassButton(text: nil, icon: "person.badge.plus", size: CGSize(width: 44, height: 44))
        addFriendButton.position = CGPoint(x: size.width - 50, y: 0)
        addFriendButton.name = "addFriendButton"
        topBar.addChild(addFriendButton)
    }
    
    private func setupTabs() {
        let tabs: [LeaderboardTab] = [.global, .friends, .weekly]
        let tabWidth: CGFloat = 110
        let tabHeight: CGFloat = 44
        let spacing: CGFloat = 5
        let totalWidth = (tabWidth * CGFloat(tabs.count)) + (spacing * CGFloat(tabs.count - 1))
        let startX = (size.width - totalWidth) / 2 + tabWidth/2
        
        for (index, tab) in tabs.enumerated() {
            let xPos = startX + CGFloat(index) * (tabWidth + spacing)
            let tabButton = createTabButton(tab: tab, size: CGSize(width: tabWidth, height: tabHeight))
            tabButton.node.position = CGPoint(x: xPos, y: size.height - 166) // add top padding below title
            tabButton.node.zPosition = 5
            addChild(tabButton.node)
            tabButtons.append(tabButton)
        }
        
        // Add map selector below tabs
        setupMapSelector()
        
        // Activate first tab
        selectTab(.global)
    }
    
    private func createTabButton(tab: LeaderboardTab, size: CGSize) -> TabButton {
        let container = SKNode()
        
        // Glass background with better contrast
        let background = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
        background.fillColor = UIColor(white: 0.15, alpha: 0.7)
        background.strokeColor = UIColor(white: 1.0, alpha: 0.4)
        background.lineWidth = 1.5
        container.addChild(background)
        
        // Icon
        var icon: SKSpriteNode? = nil
        let iconName: String
        switch tab {
        case .global:
            iconName = "globe"
        case .friends:
            iconName = "person.2.fill"
        case .weekly:
            iconName = "calendar"
        }
        
        if let image = UIImage(systemName: iconName) {
            let texture = SKTexture(image: image)
            icon = SKSpriteNode(texture: texture)
            icon?.size = CGSize(width: 20, height: 20)
            icon?.position = CGPoint(x: -size.width/2 + 25, y: 0)
            icon?.colorBlendFactor = 1.0
            icon?.color = .white
            container.addChild(icon!)
        }
        
        // Label with better contrast
        let label = SKLabelNode(text: tab.title)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 17
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 10, y: 0)
        container.addChild(label)
        
        return TabButton(node: container, tab: tab, background: background, label: label, icon: icon)
    }
    
    private func selectTab(_ tab: LeaderboardTab) {
        activeTab = tab
        
        // Update tab appearances
        for tabButton in tabButtons {
            let isActive = tabButton.tab == tab
            
            // Animate tab selection
            let scaleAction = SKAction.scale(to: isActive ? 1.05 : 1.0, duration: 0.2)
            tabButton.node.run(scaleAction)
            
            // Update colors with better contrast
            tabButton.background.fillColor = isActive ?
                UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8) :
                UIColor(white: 0.15, alpha: 0.7)
            
            tabButton.background.strokeColor = isActive ?
                UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.5) :
                UIColor(white: 1.0, alpha: 0.1)
            
            tabButton.label.fontColor = isActive ? .white : UIColor(white: 0.8, alpha: 1.0)
            tabButton.icon?.color = isActive ? .white : UIColor(white: 0.8, alpha: 1.0)
            
            // Add glow for active tab
            if isActive {
                addGlowEffect(to: tabButton.node, color: .cyan, radius: 15)
            } else {
                tabButton.node.enumerateChildNodes(withName: "glow") { node, _ in
                    node.removeFromParent()
                }
            }
        }
        
        // Load appropriate data
        loadDataForTab(tab)
    }
    
    private func setupScrollContainer() {
        scrollContainer = SKNode()
        // Position relative to cropNode (which is already centered in glassContainer)
        // Entries will be centered at x: 0 within this container
        scrollContainer.position = CGPoint(x: 0, y: 0)
        scrollContainer.zPosition = 2
        
        // Create mask node - centered mask
        let maskSize = CGSize(width: size.width - 60, height: size.height - 340)
        let mask = SKShapeNode(rectOf: maskSize, cornerRadius: 16)
        mask.fillColor = .white
        
        let cropNode = SKCropNode()
        cropNode.maskNode = mask
        cropNode.addChild(scrollContainer)
        // CropNode is centered within glassContainer (which is already positioned)
        cropNode.position = CGPoint(x: 0, y: 0)
        
        glassContainer.addChild(cropNode)
    }
    
    private func loadLeaderboardData() {
        // Mock data - replace with actual data loading
        createMockData()
        displayLeaderboard()
    }
    
    private func createMockData() {
        // Create privacy settings for mock users
        var publicPrivacy = UserProfile.PrivacySettings()
        publicPrivacy.emailVisibility = .everyone
        publicPrivacy.mutualFriendsVisibility = .everyone
        publicPrivacy.regionVisibility = .everyone
        
        var friendsOnlyPrivacy = UserProfile.PrivacySettings()
        friendsOnlyPrivacy.emailVisibility = .friendsOnly
        friendsOnlyPrivacy.mutualFriendsVisibility = .friendsOnly
        friendsOnlyPrivacy.regionVisibility = .friendsOnly
        
        // Global leaderboard
        globalEntries = [
            LeaderboardUser(userId: "1", username: "SkyMaster", score: 2430, rank: 1,
                          avatarURL: nil, customAvatar: nil, isOnline: true, isFriend: false, recentActivity: Date(),
                          privacySettings: publicPrivacy, region: UserProfile.RegionInfo(state: "California", country: "USA"),
                          email: "skymaster@example.com"),
            LeaderboardUser(userId: "2", username: "CloudNinja", score: 2240, rank: 2,
                          avatarURL: nil, customAvatar: nil, isOnline: false, isFriend: true, recentActivity: Date(),
                          privacySettings: friendsOnlyPrivacy, region: UserProfile.RegionInfo(state: "New York", country: "USA"),
                          email: "cloudninja@example.com"),
            LeaderboardUser(userId: "3", username: "AeroAce", score: 2100, rank: 3,
                          avatarURL: nil, customAvatar: nil, isOnline: true, isFriend: false, recentActivity: Date(),
                          privacySettings: publicPrivacy, region: UserProfile.RegionInfo(state: nil, country: "Canada"),
                          email: "aeroace@example.com"),
            LeaderboardUser(userId: "4", username: "Player123", score: 1850, rank: 4,
                          avatarURL: nil, customAvatar: nil, isOnline: false, isFriend: false, recentActivity: Date(),
                          privacySettings: friendsOnlyPrivacy, region: nil, email: nil),
            LeaderboardUser(userId: "5", username: "You", score: 1674, rank: 5,
                          avatarURL: nil, customAvatar: nil, isOnline: true, isFriend: false, recentActivity: Date(),
                          privacySettings: friendsOnlyPrivacy, region: UserProfile.RegionInfo(state: "Texas", country: "USA"),
                          email: AuthenticationManager.shared.currentUser?.email)
        ]
        
        // Friends leaderboard
        friendsEntries = globalEntries.filter { $0.isFriend || $0.username == "You" }
    }
    
    private func loadDataForTab(_ tab: LeaderboardTab) {
        switch tab {
        case .global:
            // For global, show empty for now (will be populated from actual game data)
            currentEntries = []
        case .friends:
            currentEntries = friendsEntries
        case .weekly:
            // Show the mock data for weekly to demonstrate the UI
            currentEntries = globalEntries
        }
        
        displayLeaderboard()
    }
    
    private func displayLeaderboard() {
        guard scrollContainer != nil else {
            print("WARNING: scrollContainer is nil, skipping displayLeaderboard")
            return
        }
        
        scrollContainer.removeAllChildren()
        
        // Check if there's no data to display
        if currentEntries.isEmpty {
            showNoDataMessage()
            return
        }
        
        let entryHeight: CGFloat = 80
        let spacing: CGFloat = 12
        var yPosition: CGFloat = 100
        
        for (index, entry) in currentEntries.enumerated() {
            let entryNode = createLeaderboardEntry(entry: entry, index: index)
            entryNode.position = CGPoint(x: 0, y: yPosition)
            scrollContainer.addChild(entryNode)
            
            yPosition -= (entryHeight + spacing)
            
            // Animate entries
            entryNode.alpha = 0
            entryNode.setScale(0.9)
            let delay = SKAction.wait(forDuration: Double(index) * 0.1)
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
            let group = SKAction.group([fadeIn, scaleUp])
            entryNode.run(SKAction.sequence([delay, group]))
        }
    }
    
    private func showNoDataMessage() {
        let messageContainer = SKNode()
        messageContainer.position = CGPoint(x: 0, y: 0)
        
        // Icon
        if let iconImage = UIImage(systemName: "chart.bar.xaxis") {
            let texture = SKTexture(image: iconImage)
            let iconNode = SKSpriteNode(texture: texture)
            iconNode.size = CGSize(width: 60, height: 60)
            iconNode.colorBlendFactor = 1.0
            iconNode.color = UIColor(white: 0.5, alpha: 1.0)
            iconNode.position = CGPoint(x: 0, y: 40)
            messageContainer.addChild(iconNode)
        }
        
        // Message
        let message: String
        switch activeTab {
        case .global:
            message = "No global high scores yet.\nBe the first to set a record!"
        case .friends:
            message = "No friends on the leaderboard yet.\nInvite friends to compete!"
        case .weekly:
            message = "No scores this week.\nStart playing to set a record!"
        }
        
        let messageLabel = SKLabelNode(text: message)
        messageLabel.fontName = "AvenirNext-Medium"
        messageLabel.fontSize = 18
        messageLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = size.width - 100
        messageLabel.verticalAlignmentMode = .center
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.position = CGPoint(x: 0, y: -20)
        messageContainer.addChild(messageLabel)
        
        scrollContainer.addChild(messageContainer)
    }
    
    private func createLeaderboardEntry(entry: LeaderboardUser, index: Int) -> SKNode {
        let container = SKNode()
        let width: CGFloat = size.width - 60  // Match mask width, properly centered
        let height: CGFloat = 80
        
        // Glass card background
        let cardPath = UIBezierPath(roundedRect: CGRect(x: -width/2, y: -height/2, width: width, height: height),
                                   cornerRadius: 16)
        let card = SKShapeNode(path: cardPath.cgPath)
        
        // Special styling for top 3
        if entry.rank <= 3 {
            let colors: [UIColor] = [
                UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.3),  // Gold
                UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.3), // Silver
                UIColor(red: 0.72, green: 0.45, blue: 0.2, alpha: 0.3)  // Bronze
            ]
            card.fillColor = colors[entry.rank - 1]
            card.strokeColor = colors[entry.rank - 1].withAlphaComponent(0.8)
            card.lineWidth = 2
            
            // Add shimmer effect for top 3
            addShimmerEffect(to: card, color: colors[entry.rank - 1])
        } else {
            card.fillColor = UIColor(white: 0.1, alpha: 0.5)
            card.strokeColor = UIColor(white: 1.0, alpha: 0.3)
            card.lineWidth = 1.5
        }
        
        container.addChild(card)
        
        // Rank badge - left of avatar with spacing
        let rankBadge = createRankBadge(rank: entry.rank)
        rankBadge.position = CGPoint(x: -width/2 + 25, y: 0)
        container.addChild(rankBadge)
        
        // Avatar - after medal with spacing
        let avatar = createAvatar(for: entry)
        avatar.position = CGPoint(x: -width/2 + 85, y: 0)
        container.addChild(avatar)
        
        // Username - positioned left of center with padding after avatar
        let usernameLabel = SKLabelNode(text: entry.username)
        usernameLabel.fontName = "AvenirNext-DemiBold"
        usernameLabel.fontSize = 18
        usernameLabel.fontColor = entry.username == "You" ? UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0) : .white
        usernameLabel.horizontalAlignmentMode = .left
        usernameLabel.position = CGPoint(x: -width/2 + 130, y: 0)
        container.addChild(usernameLabel)
        
        // Online status indicator next to username
        if entry.isOnline {
            let onlineIndicator = SKShapeNode(circleOfRadius: 4)
            onlineIndicator.fillColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            onlineIndicator.strokeColor = .clear
            onlineIndicator.position = CGPoint(x: -width/2 + 130 + usernameLabel.frame.width + 8, y: 5)
            container.addChild(onlineIndicator)
            
            // Pulsing animation
            let pulse = SKAction.scale(to: 1.2, duration: 0.5)
            let shrink = SKAction.scale(to: 1.0, duration: 0.5)
            onlineIndicator.run(SKAction.repeatForever(SKAction.sequence([pulse, shrink])))
        }
        
        // Friend indicator below username
        if entry.isFriend && entry.username != "You" {
            let friendBadge = createFriendBadge()
            friendBadge.position = CGPoint(x: -width/2 + 130, y: -18)
            container.addChild(friendBadge)
        }
        
        // Score section - stacked on the right side
        let scoreContainer = SKNode()
        scoreContainer.position = CGPoint(x: width/2 - 30, y: 0)
        container.addChild(scoreContainer)
        
        // Score value
        let scoreLabel = SKLabelNode(text: "\(entry.score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: 8)
        scoreContainer.addChild(scoreLabel)
        
        // Points label below score
        let pointsLabel = SKLabelNode(text: "pts")
        pointsLabel.fontName = "AvenirNext-Regular"
        pointsLabel.fontSize = 13
        pointsLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
        pointsLabel.horizontalAlignmentMode = .right
        pointsLabel.verticalAlignmentMode = .center
        pointsLabel.position = CGPoint(x: 0, y: -10)
        scoreContainer.addChild(pointsLabel)
        
        // Make entire entry tappable
        container.name = "leaderboardEntry_\(entry.userId)"
        card.name = "leaderboardEntry_\(entry.userId)" // Also name the card for easier detection
        
        return container
    }
    
    private func createRankBadge(rank: Int) -> SKNode {
        let container = SKNode()
        
        if rank <= 3 {
            // Trophy for top 3
            let trophyNames = ["🏆", "🥈", "🥉"]
            let trophy = SKLabelNode(text: trophyNames[rank - 1])
            trophy.fontSize = 32
            trophy.verticalAlignmentMode = .center
            container.addChild(trophy)
        } else {
            // Number badge
            let circle = SKShapeNode(circleOfRadius: 20)
            circle.fillColor = UIColor(white: 1.0, alpha: 0.1)
            circle.strokeColor = UIColor(white: 1.0, alpha: 0.2)
            circle.lineWidth = 1
            container.addChild(circle)
            
            let numberLabel = SKLabelNode(text: "#\(rank)")
            numberLabel.fontName = "AvenirNext-Bold"
            numberLabel.fontSize = 16
            numberLabel.fontColor = .white
            numberLabel.verticalAlignmentMode = .center
            container.addChild(numberLabel)
        }
        
        return container
    }
    
    private func createAvatar(for user: LeaderboardUser) -> SKNode {
        let container = SKNode()
        
        // Avatar circle with gradient border
        let avatarSize: CGFloat = 44
        let borderNode = SKShapeNode(circleOfRadius: avatarSize/2 + 2)
        
        // Create gradient texture for border
        let gradientTexture = SKTexture(size: CGSize(width: 50, height: 50)) { size, context in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1.0).cgColor
            ] as CFArray
            
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil) else { return }
            
            let center = CGPoint(x: size.width/2, y: size.height/2)
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                                     endCenter: center, endRadius: size.width/2, options: [])
        }
        
        borderNode.fillTexture = gradientTexture
        borderNode.fillColor = .white
        borderNode.strokeColor = .clear
        container.addChild(borderNode)
        
        // Avatar background
        let avatarBg = SKShapeNode(circleOfRadius: avatarSize/2)
        avatarBg.fillColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        avatarBg.strokeColor = .clear
        container.addChild(avatarBg)
        
        // User icon or initial
        if user.customAvatar != nil || user.avatarURL != nil {
            // Would load actual avatar here
            let initial = String(user.username.prefix(1)).uppercased()
            let initialLabel = SKLabelNode(text: initial)
            initialLabel.fontName = "AvenirNext-Bold"
            initialLabel.fontSize = 20
            initialLabel.fontColor = .white
            initialLabel.verticalAlignmentMode = .center
            container.addChild(initialLabel)
        } else {
            // Default user icon
            if let image = UIImage(systemName: "person.fill") {
                let texture = SKTexture(image: image)
                let icon = SKSpriteNode(texture: texture)
                icon.size = CGSize(width: 24, height: 24)
                icon.colorBlendFactor = 1.0
                icon.color = .white
                container.addChild(icon)
            }
        }
        
        return container
    }
    
    private func createFriendBadge() -> SKNode {
        let container = SKNode()
        
        let badge = SKShapeNode(rectOf: CGSize(width: 60, height: 20), cornerRadius: 10)
        badge.fillColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.2)
        badge.strokeColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.5)
        badge.lineWidth = 1
        container.addChild(badge)
        
        let label = SKLabelNode(text: "Friend")
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 12
        label.fontColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
    }
    
    private func createGlassButton(text: String?, icon: String?, size: CGSize) -> SKNode {
        let container = SKNode()
        
        let button = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
        button.fillColor = UIColor(white: 0.2, alpha: 0.8)
        button.strokeColor = UIColor(white: 1.0, alpha: 0.5)
        button.lineWidth = 2
        container.addChild(button)
        
        var xOffset: CGFloat = 0
        
        if let iconName = icon, let uiImage = UIImage(systemName: iconName)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
            let texture = SKTexture(image: uiImage)
            let iconNode = SKSpriteNode(texture: texture)
            iconNode.size = CGSize(width: 20, height: 20)
            iconNode.colorBlendFactor = 0.0 // already tinted
            
            if text != nil {
                // Add subtle circular background behind the icon for visibility
                let bg = SKShapeNode(circleOfRadius: 14)
                bg.fillColor = UIColor(white: 1.0, alpha: 0.12)
                bg.strokeColor = UIColor(white: 1.0, alpha: 0.2)
                bg.lineWidth = 1
                bg.position = CGPoint(x: -size.width/4, y: 0)
                container.addChild(bg)
                
                iconNode.position = bg.position
                xOffset = 10
            }
            
            container.addChild(iconNode)
        }
        
        // Text
        if let text = text {
            let label = SKLabelNode(text: text)
            label.fontName = "AvenirNext-Medium"
            label.fontSize = 16
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: xOffset, y: 0)
            container.addChild(label)
        }
        
        return container
    }
    
    private func addGlowEffect(to node: SKNode, color: UIColor, radius: CGFloat) {
        node.enumerateChildNodes(withName: "glow") { existingGlow, _ in
            existingGlow.removeFromParent()
        }
        
        let glowNode = SKEffectNode()
        glowNode.name = "glow"
        glowNode.shouldRasterize = true
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": radius])
        
        if let shapeNode = node as? SKShapeNode {
            let glowShape = shapeNode.copy() as! SKShapeNode
            glowShape.strokeColor = color
            glowShape.fillColor = .clear
            glowShape.lineWidth = 3
            glowNode.addChild(glowShape)
        }
        
        node.insertChild(glowNode, at: 0)
    }
    
    private func addShimmerEffect(to node: SKShapeNode, color: UIColor) {
        let shimmer = SKShapeNode(rect: CGRect(x: -20, y: -40, width: 40, height: 80))
        shimmer.fillColor = color.withAlphaComponent(0.3)
        shimmer.strokeColor = .clear
        shimmer.zRotation = .pi / 6
        
        let mask = SKCropNode()
        mask.maskNode = node.copy() as? SKNode
        mask.addChild(shimmer)
        node.addChild(mask)
        
        // Animate shimmer
        let moveRight = SKAction.moveBy(x: node.frame.width + 40, y: 0, duration: 2.0)
        let moveLeft = SKAction.moveBy(x: -(node.frame.width + 80), y: 0, duration: 0)
        let wait = SKAction.wait(forDuration: 1.0)
        shimmer.run(SKAction.repeatForever(SKAction.sequence([wait, moveRight, moveLeft])))
    }
    
    private func addFloatingOrbs() {
        // Create floating geometric orbs for modern aesthetic
        for i in 0..<8 {
            let orbSize = CGFloat.random(in: 30...80)
            let orb = SKShapeNode(circleOfRadius: orbSize/2)
            orb.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.1)
            orb.strokeColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.3)
            orb.lineWidth = 1
            orb.position = CGPoint(
                x: CGFloat.random(in: 50...size.width-50),
                y: CGFloat.random(in: 100...size.height-100)
            )
            orb.zPosition = -90
            addChild(orb)

            // Floating animation
            let float = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 20, duration: 3.0 + Double(i)),
                SKAction.moveBy(x: 0, y: -20, duration: 3.0 + Double(i))
            ])
            orb.run(SKAction.repeatForever(float))

            // Add subtle glow
            addGlowEffect(to: orb, color: UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.5), radius: 15)
        }
    }

    private func addShimmeringParticles() {
        // Create shimmering particles for modern effect
        let particleEmitter = SKEmitterNode()
        particleEmitter.particleTexture = createParticleTexture()
        particleEmitter.particleBirthRate = 1.0
        particleEmitter.particleLifetime = 8
        particleEmitter.particleLifetimeRange = 4
        particleEmitter.particlePositionRange = CGVector(dx: size.width, dy: size.height * 0.6)
        particleEmitter.position = CGPoint(x: size.width/2, y: size.height/2)
        particleEmitter.particleScale = 0.05
        particleEmitter.particleScaleRange = 0.03
        particleEmitter.particleAlpha = 0.4
        particleEmitter.particleAlphaRange = 0.2
        particleEmitter.particleSpeed = 15
        particleEmitter.particleSpeedRange = 10
        particleEmitter.emissionAngleRange = .pi * 2
        particleEmitter.particleColor = .white
        particleEmitter.particleColorBlendFactor = 1.0
        particleEmitter.zPosition = -95

        addChild(particleEmitter)
    }

    private func createParticleTexture() -> SKTexture {
        // Create a simple spark texture
        let size = CGSize(width: 4, height: 4)
        return SKTexture(size: size) { size, context in
            let rect = CGRect(origin: .zero, size: size)
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: rect)
            context.setFillColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            context.fillEllipse(in: rect.insetBy(dx: 1, dy: 1))
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Check for button taps
        if touchedNode.name == "backButton" || touchedNode.parent?.name == "backButton" {
            // Return to previous scene
            let transition = SKTransition.fade(withDuration: 0.5)
            let previousScene = MainMenuScene(size: size)
            previousScene.scaleMode = .aspectFill
            view?.presentScene(previousScene, transition: transition)
            return
        }
        
        if touchedNode.name == "profileButton" || touchedNode.parent?.name == "profileButton" {
            // Navigate to profile settings
            let transition = SKTransition.fade(withDuration: 0.5)
            let profileScene = ProfileSettingsScene(size: size)
            profileScene.scaleMode = .aspectFill
            view?.presentScene(profileScene, transition: transition)
            return
        }
        
        if touchedNode.name == "prevMap" || touchedNode.parent?.name == "prevMap" {
            changeMap(direction: -1)
            return
        }
        
        if touchedNode.name == "nextMap" || touchedNode.parent?.name == "nextMap" {
            changeMap(direction: 1)
            return
        }
        
        if touchedNode.name == "searchButton" || touchedNode.parent?.name == "searchButton" {
            // Show friend search
            showFriendSearchDialog()
            return
        }

        if touchedNode.name == "addFriendButton" || touchedNode.parent?.name == "addFriendButton" {
            // Show add friend dialog
            showAddFriendDialog()
            return
        }

        if touchedNode.name == "closeSearchDialog" || touchedNode.parent?.name == "closeSearchDialog" {
            // Close search dialog
            if let dialog = childNode(withName: "searchDialog") {
                dialog.removeFromParent()
            }
            return
        }
        
        // Check for leaderboard entry taps
        if let nodeName = touchedNode.name ?? touchedNode.parent?.name ?? touchedNode.parent?.parent?.name,
           nodeName.starts(with: "leaderboardEntry_") {
            let userId = String(nodeName.dropFirst("leaderboardEntry_".count))
            if let entry = currentEntries.first(where: { $0.userId == userId }) {
                showUserProfileDialog(for: entry)
                return
            }
        }
        
        // Check for profile dialog close button
        if touchedNode.name == "closeProfileDialog" || touchedNode.parent?.name == "closeProfileDialog" {
            if let dialog = childNode(withName: "userProfileDialog") {
                dialog.removeFromParent()
            }
            return
        }
        
        // Check for leaderboard entry taps (before scrolling check)
        if let nodeName = touchedNode.name ?? touchedNode.parent?.name ?? touchedNode.parent?.parent?.name,
           nodeName.starts(with: "leaderboardEntry_") {
            let userId = String(nodeName.dropFirst("leaderboardEntry_".count))
            if let entry = currentEntries.first(where: { $0.userId == userId }) {
                showUserProfileDialog(for: entry)
                return
            }
        }
        
        // Check for profile dialog interactions
        if touchedNode.name == "closeProfileDialog" || touchedNode.parent?.name == "closeProfileDialog" {
            if let dialog = childNode(withName: "userProfileDialog") {
                dialog.removeFromParent()
            }
            return
        }
        
        if touchedNode.name == "addFriendFromProfile" || touchedNode.parent?.name == "addFriendFromProfile" {
            if let dialog = childNode(withName: "userProfileDialog"),
               let userId = dialog.userData?["userId"] as? String {
                sendFriendRequestByUserId(userId)
                dialog.removeFromParent()
            }
            return
        }
        
        // Check for tab taps
        for tabButton in tabButtons {
            if tabButton.node.contains(location) {
                selectTab(tabButton.tab)
                return
            }
        }
        
        // Start scrolling (only if not tapping on an entry)
        lastTouchY = location.y
        isScrolling = true
        scrollVelocity = 0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isScrolling else { return }
        let location = touch.location(in: self)
        
        let deltaY = location.y - lastTouchY
        scrollContainer.position.y += deltaY
        scrollVelocity = deltaY
        lastTouchY = location.y
        
        // Limit scrolling
        let maxY: CGFloat = 0
        let minY: CGFloat = -(CGFloat(currentEntries.count) * 92 - 400)
        scrollContainer.position.y = max(minY, min(maxY, scrollContainer.position.y))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrolling = false
        
        // Apply momentum scrolling
        if abs(scrollVelocity) > 1 {
            let deceleration = SKAction.customAction(withDuration: 1.0) { [weak self] _, elapsedTime in
                guard let self = self else { return }
                let decay = 1.0 - (elapsedTime / 1.0)
                let velocity = self.scrollVelocity * decay * 0.1
                self.scrollContainer.position.y += velocity
                
                // Limit scrolling
                let maxY: CGFloat = 0
                let minY: CGFloat = -(CGFloat(self.currentEntries.count) * 92 - 400)
                self.scrollContainer.position.y = max(minY, min(maxY, self.scrollContainer.position.y))
            }
            scrollContainer.run(deceleration)
        }
    }
    
    private func showFriendSearchDialog() {
        // Create a modern search dialog
        let dialogSize = CGSize(width: 320, height: 200)
        let dialog = SKShapeNode(rectOf: dialogSize, cornerRadius: 20)
        dialog.fillColor = UIColor(white: 0.1, alpha: 0.95)
        dialog.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        dialog.lineWidth = 1
        dialog.position = CGPoint(x: size.width/2, y: size.height/2)
        dialog.zPosition = 200
        dialog.name = "searchDialog"
        addChild(dialog)

        // Add glow effect
        addGlowEffect(to: dialog, color: .cyan, radius: 20)

        // Title
        let titleLabel = SKLabelNode(text: "Find Friends")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 20
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: dialogSize.height/2 - 40)
        dialog.addChild(titleLabel)

        // Search field background
        let searchBg = SKShapeNode(rectOf: CGSize(width: 280, height: 44), cornerRadius: 22)
        searchBg.fillColor = UIColor(white: 0.15, alpha: 1.0)
        searchBg.strokeColor = UIColor(white: 1.0, alpha: 0.1)
        searchBg.lineWidth = 1
        searchBg.position = CGPoint(x: 0, y: 10)
        dialog.addChild(searchBg)

        // Search icon
        if let searchImage = UIImage(systemName: "magnifyingglass") {
            let searchTexture = SKTexture(image: searchImage)
            let searchIcon = SKSpriteNode(texture: searchTexture)
            searchIcon.size = CGSize(width: 20, height: 20)
            searchIcon.colorBlendFactor = 1.0
            searchIcon.color = UIColor(white: 0.6, alpha: 1.0)
            searchIcon.position = CGPoint(x: -120, y: 10)
            dialog.addChild(searchIcon)
        }

        // Placeholder text
        let placeholderLabel = SKLabelNode(text: "Search by username...")
        placeholderLabel.fontName = "AvenirNext-Regular"
        placeholderLabel.fontSize = 16
        placeholderLabel.fontColor = UIColor(white: 0.6, alpha: 1.0)
        placeholderLabel.position = CGPoint(x: 0, y: 10)
        dialog.addChild(placeholderLabel)

        // Close button
        let closeButton = createGlassButton(text: "Cancel", icon: nil, size: CGSize(width: 100, height: 36))
        closeButton.position = CGPoint(x: 0, y: -dialogSize.height/2 + 30)
        closeButton.name = "closeSearchDialog"
        dialog.addChild(closeButton)
    }

    private func showAddFriendDialog() {
        // Simple add friend dialog
        let alert = UIAlertController(
            title: "Add Friend",
            message: "Enter a username to send a friend request",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Username"
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Send Request", style: .default) { [weak self] _ in
            if let username = alert.textFields?.first?.text, !username.isEmpty {
                self?.sendFriendRequest(to: username)
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }

    private func sendFriendRequest(to username: String) {
        AuthenticationManager.shared.sendFriendRequest(to: username) { result in
            switch result {
            case .success:
                // Show success message
                let alert = UIAlertController(
                    title: "Friend Request Sent",
                    message: "Your friend request has been sent to \(username)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                if let viewController = self.view?.window?.rootViewController {
                    viewController.present(alert, animated: true)
                }
            case .failure(let error):
                // Show error message
                let alert = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                if let viewController = self.view?.window?.rootViewController {
                    viewController.present(alert, animated: true)
                }
            }
        }
    }
    
    private func sendFriendRequestByUserId(_ userId: String) {
        // Find username from entries
        if let entry = currentEntries.first(where: { $0.userId == userId }) {
            sendFriendRequest(to: entry.username)
        }
    }
    
    private func showUserProfileDialog(for entry: LeaderboardUser) {
        // Remove existing dialog if any
        if let existingDialog = childNode(withName: "userProfileDialog") {
            existingDialog.removeFromParent()
        }
        
        guard let currentUser = AuthenticationManager.shared.currentUser else { return }
        let isCurrentUser = entry.userId == currentUser.id
        let isFriend = entry.isFriend || isCurrentUser
        
        // Determine what information to show based on privacy settings
        let privacySettings = entry.privacySettings ?? UserProfile.PrivacySettings()
        let canSeeEmail = isCurrentUser || isFriend || privacySettings.emailVisibility == .everyone
        let canSeeRegion = isCurrentUser || isFriend || privacySettings.regionVisibility == .everyone
        let canSeeMutualFriends = isCurrentUser || isFriend || privacySettings.mutualFriendsVisibility == .everyone
        
        // Calculate mutual friends (simplified - would need entry's friends list for full implementation)
        // For now, if they're already friends, we show mutual friends count
        let mutualFriends: [String] = entry.isFriend ? currentUser.friends : []
        
        // Create dialog
        let dialogSize = CGSize(width: 320, height: 450)
        let dialog = SKShapeNode(rectOf: dialogSize, cornerRadius: 24)
        dialog.fillColor = UIColor(white: 0.1, alpha: 0.95)
        dialog.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        dialog.lineWidth = 2
        dialog.position = CGPoint(x: size.width/2, y: size.height/2)
        dialog.zPosition = 200
        dialog.name = "userProfileDialog"
        dialog.userData = NSMutableDictionary()
        dialog.userData?["userId"] = entry.userId
        addChild(dialog)
        
        // Add glow effect
        addGlowEffect(to: dialog, color: .cyan, radius: 20)
        
        // Close button
        let closeButton = createGlassButton(text: nil, icon: "xmark.circle.fill", size: CGSize(width: 36, height: 36))
        closeButton.position = CGPoint(x: dialogSize.width/2 - 20, y: dialogSize.height/2 - 20)
        closeButton.name = "closeProfileDialog"
        dialog.addChild(closeButton)
        
        // Avatar
        let avatar = createAvatar(for: entry)
        avatar.position = CGPoint(x: 0, y: dialogSize.height/2 - 80)
        dialog.addChild(avatar)
        
        // Username
        let usernameLabel = SKLabelNode(text: entry.username)
        usernameLabel.fontName = "AvenirNext-Bold"
        usernameLabel.fontSize = 24
        usernameLabel.fontColor = .white
        usernameLabel.position = CGPoint(x: 0, y: dialogSize.height/2 - 140)
        dialog.addChild(usernameLabel)
        
        // Online status
        if entry.isOnline {
            let onlineLabel = SKLabelNode(text: "● Online")
            onlineLabel.fontName = "AvenirNext-Medium"
            onlineLabel.fontSize = 14
            onlineLabel.fontColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            onlineLabel.position = CGPoint(x: 0, y: dialogSize.height/2 - 165)
            dialog.addChild(onlineLabel)
        }
        
        // Score
        let scoreLabel = SKLabelNode(text: "Score: \(entry.score)")
        scoreLabel.fontName = "AvenirNext-DemiBold"
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        scoreLabel.position = CGPoint(x: 0, y: dialogSize.height/2 - 200)
        dialog.addChild(scoreLabel)
        
        // Rank
        let rankLabel = SKLabelNode(text: "Rank: #\(entry.rank)")
        rankLabel.fontName = "AvenirNext-Medium"
        rankLabel.fontSize = 16
        rankLabel.fontColor = UIColor(white: 0.8, alpha: 1.0)
        rankLabel.position = CGPoint(x: 0, y: dialogSize.height/2 - 225)
        dialog.addChild(rankLabel)
        
        var yOffset: CGFloat = -250
        
        // Email (if allowed)
        if canSeeEmail, let email = entry.email {
            let emailLabel = SKLabelNode(text: "Email: \(email)")
            emailLabel.fontName = "AvenirNext-Regular"
            emailLabel.fontSize = 14
            emailLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
            emailLabel.position = CGPoint(x: 0, y: dialogSize.height/2 + yOffset)
            dialog.addChild(emailLabel)
            yOffset -= 25
        }
        
        // Region (if allowed)
        if canSeeRegion, let region = entry.region {
            var regionText = region.country
            if let state = region.state {
                regionText = "\(state), \(regionText)"
            }
            let regionLabel = SKLabelNode(text: "Location: \(regionText)")
            regionLabel.fontName = "AvenirNext-Regular"
            regionLabel.fontSize = 14
            regionLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
            regionLabel.position = CGPoint(x: 0, y: dialogSize.height/2 + yOffset)
            dialog.addChild(regionLabel)
            yOffset -= 25
        }
        
        // Mutual friends (if allowed)
        if canSeeMutualFriends && !mutualFriends.isEmpty {
            let mutualLabel = SKLabelNode(text: "Mutual Friends: \(mutualFriends.count)")
            mutualLabel.fontName = "AvenirNext-Regular"
            mutualLabel.fontSize = 14
            mutualLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
            mutualLabel.position = CGPoint(x: 0, y: dialogSize.height/2 + yOffset)
            dialog.addChild(mutualLabel)
            yOffset -= 25
        }
        
        // Add Friend button (if not current user and not already friend)
        if !isCurrentUser && !isFriend {
            let addFriendButton = createGlassButton(text: "Add Friend", icon: "person.badge.plus", size: CGSize(width: 200, height: 44))
            addFriendButton.position = CGPoint(x: 0, y: -dialogSize.height/2 + 60)
            addFriendButton.name = "addFriendFromProfile"
            dialog.addChild(addFriendButton)
        } else if isFriend && !isCurrentUser {
            let friendLabel = SKLabelNode(text: "✓ Friends")
            friendLabel.fontName = "AvenirNext-DemiBold"
            friendLabel.fontSize = 16
            friendLabel.fontColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
            friendLabel.position = CGPoint(x: 0, y: -dialogSize.height/2 + 60)
            dialog.addChild(friendLabel)
        }
    }
}

// SKTexture extension removed - using shared extension from AuthenticationScene.swift
