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
    
    // Map selection - Uses actual level IDs from LevelData.swift
    private var mapSelector: SKNode!
    private var currentMapIndex = 0
    // Map tuples: (levelId, displayName)
    private let maps: [(id: String, name: String)] = [
        ("level_1", "City Beginnings"),
        ("level_2", "Downtown Rush"),
        ("desert_escape", "Stargate Escape"),
        ("level_3", "Forest Valley"),
        ("level_4", "Deep Woods"),
        ("level_5", "Mountain Pass"),
        ("level_6", "Summit Challenge"),
        ("level_7", "Reef Void"),
        ("level_8", "Deep Sea Trenches"),
        ("level_9", "Space Frontier"),
        ("level_10", "Cosmic Challenge"),
        ("halloween_special", "Haunted Flight"),
        ("christmas_special", "Winter Wonderland"),
        ("summer_special", "Beach Party"),
        ("premium_level_1", "Lost City")
    ]
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
        mapSelector.position = CGPoint(x: size.width/2, y: size.height - 158)
        mapSelector.zPosition = 6  // Above tabs to ensure visibility
        addChild(mapSelector)
        
        // Map selector background - wider for better touch targets
        let selectorWidth: CGFloat = size.width - 60
        let selectorBg = SKShapeNode(rectOf: CGSize(width: selectorWidth, height: 44), cornerRadius: 22)
        selectorBg.fillColor = UIColor(white: 0.1, alpha: 0.8)
        selectorBg.strokeColor = UIColor(white: 1.0, alpha: 0.3)
        selectorBg.lineWidth = 1.5
        mapSelector.addChild(selectorBg)
        
        // Previous button - left side
        let prevButton = createGlassButton(text: nil, icon: "chevron.left", size: CGSize(width: 40, height: 40))
        prevButton.position = CGPoint(x: -selectorWidth/2 + 30, y: 0)
        prevButton.name = "prevMap"
        mapSelector.addChild(prevButton)
        
        // Map label - centered (use display name directly)
        mapLabel = SKLabelNode(text: maps[currentMapIndex].name)
        mapLabel.fontName = "AvenirNext-DemiBold"
        mapLabel.fontSize = 16
        mapLabel.fontColor = .white
        mapLabel.verticalAlignmentMode = .center
        mapLabel.horizontalAlignmentMode = .center
        mapLabel.position = CGPoint(x: 0, y: 0)
        mapSelector.addChild(mapLabel)
        
        // Next button - right side
        let nextButton = createGlassButton(text: nil, icon: "chevron.right", size: CGSize(width: 40, height: 40))
        nextButton.position = CGPoint(x: selectorWidth/2 - 30, y: 0)
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
        mapLabel.text = maps[currentMapIndex].name
        
        // Reload leaderboard for new map
        loadLeaderboardData()
    }
    
    private func setupGlassContainer() {
        // Main glass container with modern design - properly centered below map selector
        let containerSize = CGSize(width: size.width - 40, height: size.height - 250)
        let glassPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -containerSize.width/2, y: -containerSize.height/2),
                                                         size: containerSize),
                                    cornerRadius: 24)
        
        glassContainer = SKShapeNode(path: glassPath.cgPath)
        glassContainer.position = CGPoint(x: size.width/2, y: size.height/2 - 55)
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
        topBar.position = CGPoint(x: 0, y: size.height - 55)
        topBar.zPosition = 10
        addChild(topBar)
        
        // Back button - text only, no icon (cleaner look)
        let backButton = createGlassButton(text: "Back", icon: nil, size: CGSize(width: 70, height: 34))
        backButton.position = CGPoint(x: 50, y: 0)
        backButton.name = "backButton"
        topBar.addChild(backButton)
        
        // Title - positioned after back button, left-center aligned to avoid overlap
        let titleLabel = SKLabelNode(text: "Leaderboard")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 20
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: 100, y: 0)  // Left-aligned after back button
        topBar.addChild(titleLabel)
        
        // Action buttons - right aligned with consistent spacing (smaller buttons)
        let buttonSize: CGFloat = 32
        let buttonSpacing: CGFloat = 6
        let rightMargin: CGFloat = 14
        
        // Add friend button (rightmost)
        let addFriendButton = createGlassButton(text: nil, icon: "person.badge.plus", size: CGSize(width: buttonSize, height: buttonSize))
        addFriendButton.position = CGPoint(x: size.width - rightMargin - buttonSize/2, y: 0)
        addFriendButton.name = "addFriendButton"
        topBar.addChild(addFriendButton)

        // Search friends button
        let searchButton = createGlassButton(text: nil, icon: "magnifyingglass", size: CGSize(width: buttonSize, height: buttonSize))
        searchButton.position = CGPoint(x: size.width - rightMargin - buttonSize - buttonSpacing - buttonSize/2, y: 0)
        searchButton.name = "searchButton"
        topBar.addChild(searchButton)
        
        // Profile button
        let profileButton = createGlassButton(text: nil, icon: "person.circle.fill", size: CGSize(width: buttonSize, height: buttonSize))
        profileButton.position = CGPoint(x: size.width - rightMargin - (buttonSize + buttonSpacing) * 2 - buttonSize/2, y: 0)
        profileButton.name = "profileButton"
        topBar.addChild(profileButton)
    }
    
    private func setupTabs() {
        let tabs: [LeaderboardTab] = [.global, .friends, .weekly]
        let tabWidth: CGFloat = (size.width - 50) / 3  // Evenly distribute across screen with margins
        let tabHeight: CGFloat = 36
        let spacing: CGFloat = 6
        let totalWidth = (tabWidth * CGFloat(tabs.count)) + (spacing * CGFloat(tabs.count - 1))
        let startX = (size.width - totalWidth) / 2 + tabWidth/2
        
        for (index, tab) in tabs.enumerated() {
            let xPos = startX + CGFloat(index) * (tabWidth + spacing)
            let tabButton = createTabButton(tab: tab, size: CGSize(width: tabWidth, height: tabHeight))
            tabButton.node.position = CGPoint(x: xPos, y: size.height - 110)
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
        
        // Icon - smaller to not crowd text
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
            icon?.size = CGSize(width: 14, height: 14)
            icon?.position = CGPoint(x: -size.width/2 + 18, y: 0)
            icon?.colorBlendFactor = 1.0
            icon?.color = .white
            container.addChild(icon!)
        }
        
        // Label - smaller font to fit "This Week"
        let label = SKLabelNode(text: tab.title)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 6, y: 0)
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
        
        // Create mask node - centered mask, adjusted for new container size
        let maskSize = CGSize(width: size.width - 60, height: size.height - 320)
        let mask = SKShapeNode(rectOf: maskSize, cornerRadius: 16)
        mask.fillColor = .white
        
        let cropNode = SKCropNode()
        cropNode.maskNode = mask
        cropNode.addChild(scrollContainer)
        // CropNode is centered within glassContainer (which is already positioned)
        cropNode.position = CGPoint(x: 0, y: -10)
        
        glassContainer.addChild(cropNode)
    }
    
    private func loadLeaderboardData() {
        // Load map-specific data from UserDefaults
        loadMapSpecificData()
        
        // Update currentEntries based on the active tab
        loadDataForTab(activeTab)
    }
    
    private func loadMapSpecificData() {
        // Get the current map ID (the actual level ID used in the game)
        let mapID = maps[currentMapIndex].id
        let mapName = maps[currentMapIndex].name
        
        // The key format used by the game is "leaderboard_\(levelId)"
        // Each level has ONE specific key - no need for multiple mappings
        let leaderboardKey = "leaderboard_\(mapID)"
        
        var entries: [LeaderboardUser] = []
        var foundData = false
        
        print("DEBUG: Loading leaderboard for map: \(mapName) (id: \(mapID))")
        print("DEBUG: Checking key: \(leaderboardKey)")
        
        // Load data from the single correct key
        if let leaderboardData = UserDefaults.standard.dictionary(forKey: leaderboardKey) as? [String: [String: Any]] {
            print("DEBUG: Found leaderboard data with key: \(leaderboardKey)")
            foundData = true
            
            for (_, entryData) in leaderboardData {
                guard let playerName = entryData["playerName"] as? String,
                      let score = entryData["score"] as? Int else {
                    continue
                }
                
                // Check if this is the current user
                let currentPlayerName = AuthenticationManager.shared.currentUser?.username ?? 
                                      GameCenterManager.shared.getPlayerDisplayName()
                let isCurrentUser = (playerName == currentPlayerName) || 
                                   (playerName == "Player" && currentPlayerName.isEmpty) ||
                                   playerName == "You"
                
                // Create a unique ID for this entry
                let uniqueId = "\(playerName)_\(score)_\(mapID)"
                
                entries.append(LeaderboardUser(
                    userId: uniqueId,
                    username: isCurrentUser ? "You" : playerName,
                    score: score,
                    rank: 0, // Will be set after sorting
                    avatarURL: nil,
                    customAvatar: nil,
                    isOnline: isCurrentUser,
                    isFriend: false,
                    recentActivity: Date(),
                    privacySettings: nil,
                    region: nil,
                    email: nil
                ))
            }
        }
        
        // Sort by score (highest first) and assign ranks
        entries.sort { $0.score > $1.score }
        
        for (index, entry) in entries.enumerated() {
            entries[index] = LeaderboardUser(
                userId: entry.userId,
                username: entry.username,
                score: entry.score,
                rank: index + 1,
                avatarURL: entry.avatarURL,
                customAvatar: entry.customAvatar,
                isOnline: entry.isOnline,
                isFriend: entry.isFriend,
                recentActivity: entry.recentActivity,
                privacySettings: entry.privacySettings,
                region: entry.region,
                email: entry.email
            )
        }
        
        // Store in global entries
        globalEntries = entries
        
        // Friends entries - filter for friends and current user
        friendsEntries = entries.filter { $0.isFriend || $0.username == "You" }
        
        print("DEBUG: Loaded \(entries.count) entries for map \(mapID)")
        
        // If no data found, show empty state (don't use mock data)
        if !foundData {
            print("DEBUG: No leaderboard data found for \(mapID)")
            globalEntries = []
            friendsEntries = []
        }
    }
    
    private func loadDataForTab(_ tab: LeaderboardTab) {
        switch tab {
        case .global:
            // Show all entries for global leaderboard
            currentEntries = globalEntries
        case .friends:
            // Show only friends and current user
            currentEntries = friendsEntries
        case .weekly:
            // For weekly, show the same global data (would filter by date in production)
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
        
        // Reset scroll position to top
        scrollContainer.position = CGPoint(x: 0, y: 0)
        
        // Check if there's no data to display
        if currentEntries.isEmpty {
            showNoDataMessage()
            return
        }
        
        let entryHeight: CGFloat = 70
        let spacing: CGFloat = 10
        
        // Calculate starting Y position - start from top of visible area
        // The mask is centered at y: -10, with height of size.height - 320
        let maskHeight = size.height - 320
        let topOfMask = maskHeight / 2 - 20  // Start slightly below top of mask
        var yPosition: CGFloat = topOfMask
        
        for (index, entry) in currentEntries.enumerated() {
            let entryNode = createLeaderboardEntry(entry: entry, index: index)
            entryNode.position = CGPoint(x: 0, y: yPosition)
            scrollContainer.addChild(entryNode)
            
            yPosition -= (entryHeight + spacing)
            
            // Smooth staggered entry animation
            entryNode.alpha = 0
            entryNode.setScale(0.95)
            let delay = SKAction.wait(forDuration: Double(index) * 0.08)
            let fadeIn = SKAction.fadeIn(withDuration: 0.25)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.25)
            let group = SKAction.group([fadeIn, scaleUp])
            group.timingMode = .easeOut
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
        let width: CGFloat = size.width - 60  // Slightly narrower than mask for padding
        let height: CGFloat = 70
        
        // Glass card background
        let cardPath = UIBezierPath(roundedRect: CGRect(x: -width/2, y: -height/2, width: width, height: height),
                                   cornerRadius: 14)
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
        
        // Layout constants for proper spacing
        let leftPadding: CGFloat = -width/2 + 16
        let rankWidth: CGFloat = 40
        let avatarSize: CGFloat = 44
        let avatarX: CGFloat = leftPadding + rankWidth + 8
        let textStartX: CGFloat = avatarX + avatarSize/2 + 28  // Increased from 12 to 28 (~1rem more spacing)
        let scoreRightPadding: CGFloat = width/2 - 16
        
        // Rank badge - leftmost
        let rankBadge = createRankBadge(rank: entry.rank)
        rankBadge.position = CGPoint(x: leftPadding + rankWidth/2, y: 0)
        container.addChild(rankBadge)
        
        // Avatar - after rank badge
        let avatar = createAvatar(for: entry)
        avatar.position = CGPoint(x: avatarX + avatarSize/2, y: 0)
        container.addChild(avatar)
        
        // Username and status container - proper vertical layout
        let userInfoContainer = SKNode()
        userInfoContainer.position = CGPoint(x: textStartX, y: 0)
        container.addChild(userInfoContainer)
        
        // Username label - top line
        let usernameLabel = SKLabelNode(text: entry.username)
        usernameLabel.fontName = "AvenirNext-DemiBold"
        usernameLabel.fontSize = 16
        usernameLabel.fontColor = entry.username == "You" ? UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0) : .white
        usernameLabel.horizontalAlignmentMode = .left
        usernameLabel.verticalAlignmentMode = .center
        
        // Position username based on whether there's a friend badge
        let hasSecondLine = entry.isFriend && entry.username != "You"
        usernameLabel.position = CGPoint(x: 0, y: hasSecondLine ? 10 : 0)
        userInfoContainer.addChild(usernameLabel)
        
        // Online status indicator - small dot next to username
        if entry.isOnline {
            let onlineIndicator = SKShapeNode(circleOfRadius: 4)
            onlineIndicator.fillColor = UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1.0)
            onlineIndicator.strokeColor = UIColor(white: 1.0, alpha: 0.3)
            onlineIndicator.lineWidth = 1
            // Position right after username text (estimate width based on character count)
            let estimatedWidth = CGFloat(entry.username.count) * 9
            onlineIndicator.position = CGPoint(x: estimatedWidth + 10, y: usernameLabel.position.y)
            userInfoContainer.addChild(onlineIndicator)
            
            // Subtle pulsing animation
            let pulse = SKAction.scale(to: 1.3, duration: 0.6)
            let shrink = SKAction.scale(to: 1.0, duration: 0.6)
            onlineIndicator.run(SKAction.repeatForever(SKAction.sequence([pulse, shrink])))
        }
        
        // Friend badge - below username
        if hasSecondLine {
            let friendBadge = createFriendBadge()
            friendBadge.position = CGPoint(x: 30, y: -10)  // Centered below username
            userInfoContainer.addChild(friendBadge)
        }
        
        // Score section - right aligned with proper spacing
        let scoreContainer = SKNode()
        scoreContainer.position = CGPoint(x: scoreRightPadding, y: 0)
        container.addChild(scoreContainer)
        
        // Score value - larger and prominent
        let scoreLabel = SKLabelNode(text: "\(entry.score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: 6)
        scoreContainer.addChild(scoreLabel)
        
        // Points label below score
        let pointsLabel = SKLabelNode(text: "pts")
        pointsLabel.fontName = "AvenirNext-Regular"
        pointsLabel.fontSize = 11
        pointsLabel.fontColor = UIColor(white: 0.6, alpha: 1.0)
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
        scrollVelocity = deltaY * 0.8 + scrollVelocity * 0.2  // Smooth velocity calculation
        lastTouchY = location.y
        
        // Calculate scroll bounds
        let entryHeight: CGFloat = 80
        let contentHeight = CGFloat(currentEntries.count) * entryHeight
        let visibleHeight = size.height - 320
        let maxScrollY: CGFloat = 0
        let minScrollY: CGFloat = max(-(contentHeight - visibleHeight + 50), 0)
        
        // Apply with rubber band effect at edges
        if scrollContainer.position.y > maxScrollY {
            let overscroll = scrollContainer.position.y - maxScrollY
            scrollContainer.position.y = maxScrollY + overscroll * 0.3
        } else if scrollContainer.position.y < -minScrollY {
            let overscroll = -minScrollY - scrollContainer.position.y
            scrollContainer.position.y = -minScrollY - overscroll * 0.3
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrolling = false
        
        // Calculate scroll bounds
        let entryHeight: CGFloat = 80
        let contentHeight = CGFloat(currentEntries.count) * entryHeight
        let visibleHeight = size.height - 320
        let maxScrollY: CGFloat = 0
        let minScrollY: CGFloat = max(contentHeight - visibleHeight + 50, 0)
        
        // Snap back if overscrolled
        if scrollContainer.position.y > maxScrollY {
            let snapBack = SKAction.moveTo(y: maxScrollY, duration: 0.3)
            snapBack.timingMode = .easeOut
            scrollContainer.run(snapBack)
            return
        } else if scrollContainer.position.y < -minScrollY {
            let snapBack = SKAction.moveTo(y: -minScrollY, duration: 0.3)
            snapBack.timingMode = .easeOut
            scrollContainer.run(snapBack)
            return
        }
        
        // Apply smooth momentum scrolling
        if abs(scrollVelocity) > 2 {
            let momentumDuration: TimeInterval = 0.8
            let friction: CGFloat = 0.95
            
            let deceleration = SKAction.customAction(withDuration: momentumDuration) { [weak self] _, elapsedTime in
                guard let self = self else { return }
                
                // Exponential decay for smooth deceleration
                let progress = elapsedTime / CGFloat(momentumDuration)
                let decayFactor = pow(friction, elapsedTime * 60)  // 60 fps equivalent
                let velocity = self.scrollVelocity * decayFactor * 0.15
                
                // Stop if velocity is negligible
                guard abs(velocity) > 0.1 else { return }
                
                self.scrollContainer.position.y += velocity
                
                // Clamp to bounds
                if self.scrollContainer.position.y > maxScrollY {
                    self.scrollContainer.position.y = maxScrollY
                    self.scrollContainer.removeAllActions()
                } else if self.scrollContainer.position.y < -minScrollY {
                    self.scrollContainer.position.y = -minScrollY
                    self.scrollContainer.removeAllActions()
                }
            }
            scrollContainer.run(deceleration, withKey: "momentum")
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
