import SpriteKit
import UIKit
import GameKit

class LeaderboardScene: SKScene {
    
    // UI Elements
    private var titleLabel: SKLabelNode!
    private var backButton: SKShapeNode!
    private var mapTabs: [SKShapeNode] = []
    private var tabsContainer = SKNode()
    private var topBar = SKNode()
    private var lastTouchX: CGFloat?
    private var leaderboardContainer: SKNode!
    private var scrollView: SKNode!
    
    // Vertical content scrolling
    private var contentScrollContainer: SKNode!
    private var contentCropNode: SKCropNode!
    private var lastTouchY: CGFloat?
    private var isScrollingContent = false
    private var scrollVelocity: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var visibleContentHeight: CGFloat = 0
    
    // Map data - COMPLETE list including all seasonal/special maps
    private let maps = [
        ("level_1", "City Beginnings"),        // 1
        ("level_2", "Downtown Rush"),          // 2  
        ("desert_escape", "Stargate Escape"),  // 3
        ("level_3", "Forest Valley"),          // 4
        ("level_4", "Deep Woods"),             // 5
        ("level_5", "Mountain Pass"),          // 6
        ("level_6", "Summit Challenge"),       // 7
        ("level_7", "Reef Void"),              // 8
        ("level_8", "Deep Sea Trenches"),      // 9
        ("level_9", "Space Frontier"),         // 10
        ("level_10", "Cosmic Challenge"),      // 11
        // Special/Seasonal Maps
        ("halloween_special", "Haunted Flight"),    // 12
        ("christmas_special", "Winter Wonderland"),  // 13
        ("summer_special", "Beach Escape")           // 14
    ]
    
    private var currentMapIndex = 0
    private var leaderboardEntries: [LeaderboardEntry] = []
    
    struct LeaderboardEntry {
        let rank: Int
        let playerName: String
        let score: Int
        let isLocalPlayer: Bool
        let avatarData: Data?
    }
    
    // Sky Hopper themed titles for top 3
    private let rankTitles = [
        1: "Top Sky Hopper",
        2: "Elite Pilot",
        3: "Ace Navigator"
    ]
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupUI()
        #if DEBUG
        UILinter.run(scene: self, topBar: topBar)
        #endif
        
        // Find the map with the most recent high score to show by default
        let mapWithRecentScore = findMapWithMostRecentScore()
        if let mapIndex = mapWithRecentScore {
            currentMapIndex = mapIndex
            updateTabSelection()
        }
        
        loadLeaderboard(for: maps[currentMapIndex].0)
        
        // Listen for profile updates to refresh avatar display
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileUpdate),
            name: AuthenticationManager.profileDidUpdateNotification,
            object: nil
        )
        
        // Also listen for app becoming active to refresh if needed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    override func willMove(from view: SKView) {
        // Remove observers when scene is removed
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleProfileUpdate() {
        // Refresh the current leaderboard to show updated profile picture
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadLeaderboard(for: self.maps[self.currentMapIndex].0)
        }
    }
    
    @objc private func handleAppBecameActive() {
        // Refresh on app return in case profile was changed externally
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.displayLeaderboard()
        }
    }

    private func safeTopInset() -> CGFloat {
        // Approximate if not available
        return view?.safeAreaInsets.top ?? 44
    }
    
    private func findMapWithMostRecentScore() -> Int? {
        var mostRecentDate: TimeInterval = 0
        var mostRecentMapIndex: Int? = nil
        
        // Check each map for leaderboard data
        for (index, mapData) in maps.enumerated() {
            let mapID = mapData.0
            
            // Check if this map has any leaderboard entries
            if let leaderboardData = UserDefaults.standard.dictionary(forKey: "leaderboard_\(mapID)") as? [String: [String: Any]] {
                
                // Find the most recent entry in this map
                for (_, entryData) in leaderboardData {
                    if let date = entryData["date"] as? TimeInterval {
                        if date > mostRecentDate {
                            mostRecentDate = date
                            mostRecentMapIndex = index
                        }
                    }
                }
            }
        }
        
        if let mapIndex = mostRecentMapIndex {
            print("DEBUG: Found most recent score on map: \(maps[mapIndex].1) (index: \(mapIndex))")
        } else {
            print("DEBUG: No recent scores found, using default map")
        }
        
        return mostRecentMapIndex
    }
    
    private func setupBackground() {
        backgroundColor = UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1.0)
        
        // Add subtle animated background
        for _ in 0..<50 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
            star.fillColor = .white
            star.alpha = CGFloat.random(in: 0.3...0.7)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                   y: CGFloat.random(in: 0...size.height))
            
            // Twinkling animation
            let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: TimeInterval.random(in: 1...3))
            let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: TimeInterval.random(in: 1...3))
            star.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
            
            addChild(star)
        }
    }
    
    private func setupUI() {
        // Title + Back via SafeAreaTopBar
        topBar.removeFromParent()
        topBar = SafeAreaTopBar.build(in: self, title: "LEADERBOARDS") { [weak self] in
            // Return to main menu
            let transition = SKTransition.fade(withDuration: 0.5)
            let mainMenu = MainMenuScene(size: self?.size ?? CGSize(width: 390, height: 844))
            mainMenu.scaleMode = .aspectFill
            self?.view?.presentScene(mainMenu, transition: transition)
        }
        
        // Create map tabs below title by 12pt
        addChild(tabsContainer)
        if let bottomY = topBar.userData?["topBarBottomY"] as? CGFloat {
            // Place tabs just below title
            tabsContainer.position.y = bottomY - UIConstants.Spacing.large
        }
        createMapTabs()
        
        // Create leaderboard container with crop node for scrolling
        let topBarBottomY = topBar.userData?["topBarBottomY"] as? CGFloat ?? (size.height - 120)
        let contentTopY = topBarBottomY - (UIConstants.Spacing.large * 2) - 40
        let bottomPadding: CGFloat = 40
        visibleContentHeight = contentTopY - bottomPadding
        
        // Crop node for masking scrollable content
        contentCropNode = SKCropNode()
        contentCropNode.position = CGPoint(x: size.width / 2, y: contentTopY / 2 + bottomPadding / 2)
        contentCropNode.zPosition = 5
        addChild(contentCropNode)
        
        // Create mask
        let scrollMask = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: visibleContentHeight), cornerRadius: 12)
        scrollMask.fillColor = .white
        contentCropNode.maskNode = scrollMask
        
        // Scrollable content container
        contentScrollContainer = SKNode()
        contentScrollContainer.position = CGPoint(x: 0, y: 0)
        contentCropNode.addChild(contentScrollContainer)
        
        // Legacy container reference (for backward compat)
        leaderboardContainer = contentScrollContainer
    }
    
    private func createMapTabs() {
        // Clear existing
        mapTabs.forEach { $0.removeFromParent() }
        mapTabs.removeAll()
        
        let tabHeight: CGFloat = 40
        let tabSpacing: CGFloat = 12
        var x: CGFloat = 0
        
        for (index, map) in maps.enumerated() {
            let label = SKLabelNode(text: map.1)
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 14
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            
            // Size tab to fit text nicely
            let labelWidth = min(max(100, label.frame.width + 28), 220)
            let tab = SKShapeNode(rectOf: CGSize(width: labelWidth, height: tabHeight), cornerRadius: UIConstants.Radius.medium)
            tab.fillColor = index == currentMapIndex ?
                UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.9) :
                UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 0.7)
            tab.strokeColor = .white
            tab.lineWidth = index == currentMapIndex ? 2 : 1
            // Position at container origin (we offset container earlier)
            tab.position = CGPoint(x: x + labelWidth/2, y: 0)
            tab.name = "tab_\(index)"
            tab.addChild(label)
            
            mapTabs.append(tab)
            tabsContainer.addChild(tab)
            x += labelWidth + tabSpacing
        }
        // Center tabs horizontally
        tabsContainer.position.x = (size.width - x) / 2
    }
    
    private func updateTabSelection() {
        for (index, tab) in mapTabs.enumerated() {
            tab.fillColor = index == currentMapIndex ? 
                UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.9) : 
                UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 0.7)
            tab.lineWidth = index == currentMapIndex ? 2 : 1
        }
    }
    
    private func loadLeaderboard(for mapID: String) {
        // Clear existing entries
        leaderboardContainer.removeAllChildren()
        leaderboardEntries.removeAll()
        
        // Show loading indicator
        let loadingLabel = SKLabelNode(text: "Loading...")
        loadingLabel.fontName = "AvenirNext-Regular"
        loadingLabel.fontSize = 24
        loadingLabel.fontColor = .white
        loadingLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        leaderboardContainer.addChild(loadingLabel)
        
        // Load from local storage first (our new system)
        loadLocalLeaderboard(for: mapID)
    }
    
    private func loadLocalLeaderboard(for mapID: String) {
        // Load leaderboard entries from UserDefaults
        guard let leaderboardData = UserDefaults.standard.dictionary(forKey: "leaderboard_\(mapID)") as? [String: [String: Any]] else {
            print("DEBUG: No local leaderboard data found for \(mapID)")
            // Fallback to Game Center or mock data
            loadGameCenterLeaderboard(for: mapID)
            return
        }
        
        print("DEBUG: Loading local leaderboard for \(mapID): \(leaderboardData)")
        
        // Convert to LeaderboardEntry objects and sort by score
        var entries: [LeaderboardEntry] = []
        
        for (_, entryData) in leaderboardData {
            guard let playerName = entryData["playerName"] as? String,
                  let score = entryData["score"] as? Int else {
                continue
            }
            
            // Check if this is the local player - check multiple sources
            let currentUser = AuthenticationManager.shared.currentUser
            let gameCenterName = GameCenterManager.shared.getPlayerDisplayName()
            let authUsername = currentUser?.username ?? ""
            
            // Match against Game Center name, AuthenticationManager username, or common defaults
            let isLocalPlayer = (playerName == gameCenterName && !gameCenterName.isEmpty) ||
                               (playerName == authUsername && !authUsername.isEmpty) ||
                               (playerName == "Player" && gameCenterName.isEmpty && authUsername.isEmpty)
            
            // ALWAYS use current profile picture for local player (not stored avatar)
            let avatarData: Data? = isLocalPlayer ? currentUser?.customAvatar : (entryData["avatar"] as? Data)
            
            entries.append(LeaderboardEntry(
                rank: 0, // Will be set after sorting
                playerName: playerName,
                score: score,
                isLocalPlayer: isLocalPlayer,
                avatarData: avatarData
            ))
        }
        
        // Sort by score (highest first) and assign ranks
        entries.sort { $0.score > $1.score }
        
        for (index, _) in entries.enumerated() {
            entries[index] = LeaderboardEntry(
                rank: index + 1,
                playerName: entries[index].playerName,
                score: entries[index].score,
                isLocalPlayer: entries[index].isLocalPlayer,
                avatarData: entries[index].avatarData
            )
        }
        
        self.leaderboardEntries = entries
        
        // Update display
        DispatchQueue.main.async {
            self.displayLeaderboard()
        }
    }
    
    private func loadGameCenterLeaderboard(for mapID: String) {
        // Load from Game Center as fallback
        let leaderboardID = "com.skyhopper.\(mapID)"
        
        if #available(iOS 14.0, *) {
            GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { [weak self] leaderboards, error in
                guard let self = self, let leaderboard = leaderboards?.first else {
                    self?.showNoDataMessage()
                    return
                }
                
                leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100)) { [weak self] localPlayer, entries, _, error in
                    guard let self = self, let entries = entries else {
                        self?.loadMockData() // Final fallback
                        return
                    }
                    
                    // Process entries
                    for entry in entries {
                        let leaderboardEntry = LeaderboardEntry(
                            rank: entry.rank,
                            playerName: entry.player.displayName,
                            score: entry.score,
                            isLocalPlayer: entry.player == GKLocalPlayer.local,
                            avatarData: nil
                        )
                        self.leaderboardEntries.append(leaderboardEntry)
                    }
                    
                    // Update display
                    DispatchQueue.main.async {
                        self.displayLeaderboard()
                    }
                }
            }
        } else {
            // Fallback for older iOS versions - show mock data
            loadMockData()
        }
    }
    
    private func loadMockData() {
        // For testing/demo purposes
        leaderboardEntries = [
            LeaderboardEntry(rank: 1, playerName: "SkyMaster", score: 1250, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 2, playerName: "AceFlyer", score: 1100, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 3, playerName: "You", score: 950, isLocalPlayer: true, avatarData: nil),
            LeaderboardEntry(rank: 4, playerName: "CloudHopper", score: 875, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 5, playerName: "JetStream", score: 720, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 6, playerName: "WindRider", score: 650, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 7, playerName: "SkyDancer", score: 580, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 8, playerName: "AirBender", score: 510, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 9, playerName: "StormPilot", score: 445, isLocalPlayer: false, avatarData: nil),
            LeaderboardEntry(rank: 10, playerName: "CloudSurfer", score: 380, isLocalPlayer: false, avatarData: nil)
        ]
        displayLeaderboard()
    }
    
    private func displayLeaderboard() {
        leaderboardContainer.removeAllChildren()
        contentScrollContainer?.position = CGPoint(x: 0, y: 0) // Reset scroll position
        
        print("DEBUG: displayLeaderboard called with \(leaderboardEntries.count) entries")
        
        // If no entries, show the no data message
        if leaderboardEntries.isEmpty {
            showNoDataMessage()
            return
        }
        
        let entryHeight: CGFloat = 50
        // Start from top of visible area (positive Y in crop node)
        let startY: CGFloat = visibleContentHeight / 2 - 30
        
        // Calculate total content height for scrolling
        contentHeight = 60 + CGFloat(min(leaderboardEntries.count, 20)) * entryHeight + 40
        
        // Create header - centered in crop node (x = 0)
        let headerBG = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 40), cornerRadius: 5)
        headerBG.fillColor = UIColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 0.9)
        headerBG.strokeColor = .white
        headerBG.position = CGPoint(x: 0, y: startY)
        leaderboardContainer.addChild(headerBG)
        
        // All X positions relative to center (0) since content is in centered crop node
        let halfWidth = (size.width - 40) / 2
        let rankX: CGFloat = -halfWidth + 60
        let trophyX: CGFloat = -halfWidth + 20
        let avatarX: CGFloat = -60
        let nameX: CGFloat = 0
        let scoreX: CGFloat = halfWidth - 40
        
        let rankHeader = SKLabelNode(text: "RANK")
        rankHeader.fontName = "AvenirNext-Bold"
        rankHeader.fontSize = 16
        rankHeader.fontColor = .white
        rankHeader.position = CGPoint(x: rankX, y: startY)
        rankHeader.verticalAlignmentMode = .center
        leaderboardContainer.addChild(rankHeader)
        
        let nameHeader = SKLabelNode(text: "PILOT")
        nameHeader.fontName = "AvenirNext-Bold"
        nameHeader.fontSize = 16
        nameHeader.fontColor = .white
        nameHeader.position = CGPoint(x: nameX, y: startY)
        nameHeader.verticalAlignmentMode = .center
        leaderboardContainer.addChild(nameHeader)
        
        let scoreHeader = SKLabelNode(text: "SCORE")
        scoreHeader.fontName = "AvenirNext-Bold"
        scoreHeader.fontSize = 16
        scoreHeader.fontColor = .white
        scoreHeader.position = CGPoint(x: scoreX, y: startY)
        scoreHeader.verticalAlignmentMode = .center
        leaderboardContainer.addChild(scoreHeader)
        
        // Display entries
        for (index, entry) in leaderboardEntries.prefix(20).enumerated() {
            let yPos = startY - CGFloat(index + 1) * entryHeight - 20
            
            // Entry background (centered at x = 0)
            let entryBG = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: entryHeight - 5), cornerRadius: 5)
            
            // Special colors for top 3
            if entry.rank <= 3 {
                switch entry.rank {
                case 1:
                    entryBG.fillColor = UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 0.3) // Gold
                case 2:
                    entryBG.fillColor = UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 0.3) // Silver
                case 3:
                    entryBG.fillColor = UIColor(red: 0.7, green: 0.4, blue: 0.2, alpha: 0.3) // Bronze
                default:
                    break
                }
            } else if entry.isLocalPlayer {
                entryBG.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 0.3) // Highlight local player
            } else {
                entryBG.fillColor = UIColor(red: 0.2, green: 0.25, blue: 0.3, alpha: 0.5)
            }
            
            entryBG.strokeColor = entry.isLocalPlayer ? .yellow : .white
            entryBG.lineWidth = entry.isLocalPlayer ? 2 : 1
            entryBG.position = CGPoint(x: 0, y: yPos)
            leaderboardContainer.addChild(entryBG)
            
            // Rank with title for top 3
            let rankText: String
            if let title = rankTitles[entry.rank] {
                rankText = "#\(entry.rank)\n\(title)"
            } else {
                rankText = "#\(entry.rank)"
            }
            
            let rankLabel = SKLabelNode(text: rankText)
            rankLabel.fontName = entry.rank <= 3 ? "AvenirNext-Heavy" : "AvenirNext-Bold"
            rankLabel.fontSize = entry.rank <= 3 ? 14 : 16
            rankLabel.fontColor = entry.rank == 1 ? UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0) :
                                 entry.rank == 2 ? UIColor(red: 0.8, green: 0.8, blue: 0.9, alpha: 1.0) :
                                 entry.rank == 3 ? UIColor(red: 0.8, green: 0.5, blue: 0.3, alpha: 1.0) : .white
            rankLabel.numberOfLines = 2
            rankLabel.position = CGPoint(x: rankX, y: yPos)
            rankLabel.verticalAlignmentMode = .center
            leaderboardContainer.addChild(rankLabel)
            
            // Trophy icon for top 3
            if entry.rank <= 3 {
                let trophy = SKLabelNode(text: "🏆")
                trophy.fontSize = 20
                trophy.position = CGPoint(x: trophyX, y: yPos)
                trophy.verticalAlignmentMode = .center
                leaderboardContainer.addChild(trophy)
            }
            
            // Avatar - use current user's profile picture if local player
            var avatarImage: UIImage? = nil
            if entry.isLocalPlayer, let currentAvatar = AuthenticationManager.shared.currentUser?.customAvatar {
                avatarImage = UIImage(data: currentAvatar)
            } else if let avatarData = entry.avatarData {
                avatarImage = UIImage(data: avatarData)
            }
            
            if let image = avatarImage {
                let texture = SKTexture(image: image)
                let avatarSprite = SKSpriteNode(texture: texture)
                avatarSprite.size = CGSize(width: 36, height: 36)
                avatarSprite.position = CGPoint(x: avatarX, y: yPos)
                
                let maskNode = SKShapeNode(circleOfRadius: 18)
                maskNode.fillColor = .white
                
                let cropNode = SKCropNode()
                cropNode.maskNode = maskNode
                cropNode.addChild(avatarSprite)
                leaderboardContainer.addChild(cropNode)
            } else {
                if let image = UIImage(systemName: "person.fill") {
                    let texture = SKTexture(image: image)
                    let defaultAvatar = SKSpriteNode(texture: texture)
                    defaultAvatar.size = CGSize(width: 28, height: 28)
                    defaultAvatar.colorBlendFactor = 1.0
                    defaultAvatar.color = .white
                    defaultAvatar.position = CGPoint(x: avatarX, y: yPos)
                    leaderboardContainer.addChild(defaultAvatar)
                }
            }
            
            // Player name
            let nameLabel = SKLabelNode(text: entry.playerName)
            nameLabel.fontName = entry.isLocalPlayer ? "AvenirNext-Heavy" : "AvenirNext-Regular"
            nameLabel.fontSize = 16
            nameLabel.fontColor = entry.isLocalPlayer ? .yellow : .white
            nameLabel.position = CGPoint(x: nameX + 20, y: yPos)
            nameLabel.verticalAlignmentMode = .center
            leaderboardContainer.addChild(nameLabel)
            
            // Score
            let scoreLabel = SKLabelNode(text: "\(entry.score)")
            scoreLabel.fontName = "AvenirNext-Bold"
            scoreLabel.fontSize = 18
            scoreLabel.fontColor = .white
            scoreLabel.position = CGPoint(x: scoreX, y: yPos)
            scoreLabel.verticalAlignmentMode = .center
            leaderboardContainer.addChild(scoreLabel)
        }
    }
    
    private func showNoDataMessage() {
        leaderboardContainer.removeAllChildren()
        contentHeight = 0 // No scroll needed for empty state
        
        let messageLabel = SKLabelNode(text: "No scores yet for this map!")
        messageLabel.fontName = "AvenirNext-Regular"
        messageLabel.fontSize = 24
        messageLabel.fontColor = .white
        messageLabel.position = CGPoint(x: 0, y: 20)
        leaderboardContainer.addChild(messageLabel)
        
        let subLabel = SKLabelNode(text: "Be the first to set a high score!")
        subLabel.fontName = "AvenirNext-Regular"
        subLabel.fontSize = 18
        subLabel.fontColor = UIColor(white: 0.8, alpha: 1.0)
        subLabel.position = CGPoint(x: 0, y: -20)
        leaderboardContainer.addChild(subLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        lastTouchX = location.x
        lastTouchY = location.y
        isScrollingContent = false
        scrollVelocity = 0
        contentScrollContainer?.removeAction(forKey: "momentum")
        
        if touchedNode.name == "backButton" || touchedNode.parent?.name == "backButton" {
            // Return to main menu
            let transition = SKTransition.fade(withDuration: 0.5)
            let mainMenu = MainMenuScene(size: size)
            mainMenu.scaleMode = .aspectFill
            view?.presentScene(mainMenu, transition: transition)
        } else if let nodeName = touchedNode.name ?? touchedNode.parent?.name,
                  nodeName.starts(with: "tab_") {
            // Tab selection
            if let indexStr = nodeName.split(separator: "_").last,
               let index = Int(indexStr) {
                currentMapIndex = index
                updateTabSelection()
                loadLeaderboard(for: maps[index].0)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)
        
        // Check if touch is in the tabs area (upper region) or content area (lower region)
        let topBarBottomY = topBar.userData?["topBarBottomY"] as? CGFloat ?? (size.height - 120)
        let tabsRegionBottom = topBarBottomY - 80
        
        if p.y > tabsRegionBottom, let last = lastTouchX {
            // Horizontal tab scrolling
            let dx = p.x - last
            tabsContainer.position.x += dx
            lastTouchX = p.x
        } else if let lastY = lastTouchY, contentHeight > visibleContentHeight {
            // Vertical content scrolling - standard iOS style
            let deltaY = p.y - lastY
            // Standard iOS scrolling:
            // Swipe UP (positive deltaY in SpriteKit) = show content below = container moves UP
            // Swipe DOWN (negative deltaY) = show content above = container moves DOWN
            contentScrollContainer.position.y += deltaY
            scrollVelocity = deltaY * 0.8 + scrollVelocity * 0.2
            lastTouchY = p.y
            isScrollingContent = true
            
            // Calculate scroll bounds
            let maxScrollUp: CGFloat = max(contentHeight - visibleContentHeight, 0)
            let maxScrollDown: CGFloat = 0
            
            // Rubber band effect at edges
            if contentScrollContainer.position.y > maxScrollUp {
                let overscroll = contentScrollContainer.position.y - maxScrollUp
                contentScrollContainer.position.y = maxScrollUp + overscroll * 0.3
            } else if contentScrollContainer.position.y < maxScrollDown {
                let overscroll = maxScrollDown - contentScrollContainer.position.y
                contentScrollContainer.position.y = maxScrollDown - overscroll * 0.3
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchX = nil
        lastTouchY = nil
        snapTabsToNearest()
        
        // Apply momentum scrolling for content if needed
        if isScrollingContent && abs(scrollVelocity) > 1 {
            let maxScrollUp: CGFloat = max(contentHeight - visibleContentHeight, 0)
            let maxScrollDown: CGFloat = 0
            
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
            let currentY = contentScrollContainer.position.y
            if currentY > maxScrollUp {
                let snapBack = SKAction.moveTo(y: maxScrollUp, duration: 0.3)
                snapBack.timingMode = .easeOut
                contentScrollContainer.run(snapBack, withKey: "momentum")
            } else if currentY < maxScrollDown {
                let snapBack = SKAction.moveTo(y: maxScrollDown, duration: 0.3)
                snapBack.timingMode = .easeOut
                contentScrollContainer.run(snapBack, withKey: "momentum")
            } else {
                contentScrollContainer.run(momentumAction, withKey: "momentum")
            }
        }
        
        isScrollingContent = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchX = nil
        lastTouchY = nil
        isScrollingContent = false
    }

    private func snapTabsToNearest() {
        // Snap tabs so the nearest tab centers under the middle of the screen
        guard !mapTabs.isEmpty else { return }
        // Compute target centers in world space
        let desiredX = size.width / 2
        // Find tab whose converted position is closest to center
        var bestIndex = currentMapIndex
        var bestDist = CGFloat.greatestFiniteMagnitude
        for (idx, tab) in mapTabs.enumerated() {
            let worldX = tabsContainer.convert(tab.position, to: self).x
            let d = abs(worldX - desiredX)
            if d < bestDist {
                bestDist = d
                bestIndex = idx
            }
        }
        currentMapIndex = bestIndex
        updateTabSelection()
        loadLeaderboard(for: maps[bestIndex].0)
        // Animate container so selected tab is centered
        let selected = mapTabs[bestIndex]
        let selectedWorldX = tabsContainer.convert(selected.position, to: self).x
        let shift = desiredX - selectedWorldX
        tabsContainer.run(SKAction.moveBy(x: shift, y: 0, duration: 0.2))
    }
}

// Helper extension for Bool
// Note: Bool.random(percentage:) is defined in GameScene.swift; avoid re-declaration here