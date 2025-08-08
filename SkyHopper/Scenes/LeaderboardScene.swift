import SpriteKit
import GameKit

class LeaderboardScene: SKScene {
    
    // UI Elements
    private var titleLabel: SKLabelNode!
    private var backButton: SKShapeNode!
    private var mapTabs: [SKShapeNode] = []
    private var leaderboardContainer: SKNode!
    private var scrollView: SKNode!
    
    // Map data
    private let maps = [
        ("level_1", "City Beginnings"),
        ("desert_escape", "Stargate Escape"),
        ("level_3", "Forest Valley"),
        ("level_5", "Mountain Pass"),
        ("level_7", "Underwater Adventure"),
        ("level_9", "Space Frontier"),
        ("level_10", "Cosmic Challenge")
    ]
    
    private var currentMapIndex = 0
    private var leaderboardEntries: [LeaderboardEntry] = []
    
    struct LeaderboardEntry {
        let rank: Int
        let playerName: String
        let score: Int
        let isLocalPlayer: Bool
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
        loadLeaderboard(for: maps[currentMapIndex].0)
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
        // Title
        titleLabel = SKLabelNode(text: "LEADERBOARDS")
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = 36
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height - 60)
        addChild(titleLabel)
        
        // Back button
        backButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 8)
        backButton.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.8)
        backButton.strokeColor = .white
        backButton.lineWidth = 2
        backButton.position = CGPoint(x: 70, y: size.height - 60)
        backButton.name = "backButton"
        
        let backLabel = SKLabelNode(text: "BACK")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 18
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backButton.addChild(backLabel)
        
        addChild(backButton)
        
        // Create map tabs
        createMapTabs()
        
        // Create leaderboard container
        leaderboardContainer = SKNode()
        leaderboardContainer.position = CGPoint(x: 0, y: 100)
        addChild(leaderboardContainer)
    }
    
    private func createMapTabs() {
        let tabWidth: CGFloat = 120
        let tabHeight: CGFloat = 40
        let tabSpacing: CGFloat = 5
        let startX = (size.width - (CGFloat(maps.count) * (tabWidth + tabSpacing))) / 2 + tabWidth/2
        
        for (index, map) in maps.enumerated() {
            let tab = SKShapeNode(rectOf: CGSize(width: tabWidth, height: tabHeight), cornerRadius: 5)
            tab.fillColor = index == currentMapIndex ? 
                UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.9) : 
                UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 0.7)
            tab.strokeColor = .white
            tab.lineWidth = index == currentMapIndex ? 2 : 1
            tab.position = CGPoint(x: startX + CGFloat(index) * (tabWidth + tabSpacing),
                                 y: size.height - 120)
            tab.name = "tab_\(index)"
            
            let label = SKLabelNode(text: map.1)
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 12
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            tab.addChild(label)
            
            mapTabs.append(tab)
            addChild(tab)
        }
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
        
        // Load from Game Center
        let leaderboardID = "com.skyhopper.\(mapID)"
        
        if #available(iOS 14.0, *) {
            GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { [weak self] leaderboards, error in
                guard let self = self, let leaderboard = leaderboards?.first else {
                    self?.showNoDataMessage()
                    return
                }
                
                leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100)) { [weak self] localPlayer, entries, _, error in
                    guard let self = self, let entries = entries else {
                        self?.showNoDataMessage()
                        return
                    }
                    
                    // Process entries
                    for (index, entry) in entries.enumerated() {
                        let leaderboardEntry = LeaderboardEntry(
                            rank: entry.rank,
                            playerName: entry.player.displayName,
                            score: entry.score,
                            isLocalPlayer: entry.player == GKLocalPlayer.local
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
            LeaderboardEntry(rank: 1, playerName: "SkyMaster", score: 1250, isLocalPlayer: false),
            LeaderboardEntry(rank: 2, playerName: "AceFlyer", score: 1100, isLocalPlayer: false),
            LeaderboardEntry(rank: 3, playerName: "You", score: 950, isLocalPlayer: true),
            LeaderboardEntry(rank: 4, playerName: "CloudHopper", score: 875, isLocalPlayer: false),
            LeaderboardEntry(rank: 5, playerName: "JetStream", score: 720, isLocalPlayer: false),
            LeaderboardEntry(rank: 6, playerName: "WindRider", score: 650, isLocalPlayer: false),
            LeaderboardEntry(rank: 7, playerName: "SkyDancer", score: 580, isLocalPlayer: false),
            LeaderboardEntry(rank: 8, playerName: "AirBender", score: 510, isLocalPlayer: false),
            LeaderboardEntry(rank: 9, playerName: "StormPilot", score: 445, isLocalPlayer: false),
            LeaderboardEntry(rank: 10, playerName: "CloudSurfer", score: 380, isLocalPlayer: false)
        ]
        displayLeaderboard()
    }
    
    private func displayLeaderboard() {
        leaderboardContainer.removeAllChildren()
        
        let entryHeight: CGFloat = 50
        let startY = size.height - 200
        
        // Create header
        let headerBG = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 40), cornerRadius: 5)
        headerBG.fillColor = UIColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 0.9)
        headerBG.strokeColor = .white
        headerBG.position = CGPoint(x: size.width/2, y: startY)
        leaderboardContainer.addChild(headerBG)
        
        let rankHeader = SKLabelNode(text: "RANK")
        rankHeader.fontName = "AvenirNext-Bold"
        rankHeader.fontSize = 16
        rankHeader.fontColor = .white
        rankHeader.position = CGPoint(x: 100, y: startY)
        rankHeader.verticalAlignmentMode = .center
        leaderboardContainer.addChild(rankHeader)
        
        let nameHeader = SKLabelNode(text: "PILOT")
        nameHeader.fontName = "AvenirNext-Bold"
        nameHeader.fontSize = 16
        nameHeader.fontColor = .white
        nameHeader.position = CGPoint(x: size.width/2, y: startY)
        nameHeader.verticalAlignmentMode = .center
        leaderboardContainer.addChild(nameHeader)
        
        let scoreHeader = SKLabelNode(text: "SCORE")
        scoreHeader.fontName = "AvenirNext-Bold"
        scoreHeader.fontSize = 16
        scoreHeader.fontColor = .white
        scoreHeader.position = CGPoint(x: size.width - 100, y: startY)
        scoreHeader.verticalAlignmentMode = .center
        leaderboardContainer.addChild(scoreHeader)
        
        // Display entries
        for (index, entry) in leaderboardEntries.prefix(20).enumerated() {
            let yPos = startY - CGFloat(index + 1) * entryHeight - 20
            
            // Entry background
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
            entryBG.position = CGPoint(x: size.width/2, y: yPos)
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
            rankLabel.position = CGPoint(x: 100, y: yPos)
            rankLabel.verticalAlignmentMode = .center
            leaderboardContainer.addChild(rankLabel)
            
            // Trophy icon for top 3
            if entry.rank <= 3 {
                let trophy = SKLabelNode(text: "🏆")
                trophy.fontSize = 20
                trophy.position = CGPoint(x: 60, y: yPos)
                trophy.verticalAlignmentMode = .center
                leaderboardContainer.addChild(trophy)
            }
            
            // Player name
            let nameLabel = SKLabelNode(text: entry.playerName)
            nameLabel.fontName = entry.isLocalPlayer ? "AvenirNext-Heavy" : "AvenirNext-Regular"
            nameLabel.fontSize = 16
            nameLabel.fontColor = entry.isLocalPlayer ? .yellow : .white
            nameLabel.position = CGPoint(x: size.width/2, y: yPos)
            nameLabel.verticalAlignmentMode = .center
            leaderboardContainer.addChild(nameLabel)
            
            // Score
            let scoreLabel = SKLabelNode(text: "\(entry.score)")
            scoreLabel.fontName = "AvenirNext-Bold"
            scoreLabel.fontSize = 18
            scoreLabel.fontColor = .white
            scoreLabel.position = CGPoint(x: size.width - 100, y: yPos)
            scoreLabel.verticalAlignmentMode = .center
            leaderboardContainer.addChild(scoreLabel)
        }
    }
    
    private func showNoDataMessage() {
        leaderboardContainer.removeAllChildren()
        
        let messageLabel = SKLabelNode(text: "No scores yet for this map!")
        messageLabel.fontName = "AvenirNext-Regular"
        messageLabel.fontSize = 24
        messageLabel.fontColor = .white
        messageLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        leaderboardContainer.addChild(messageLabel)
        
        let subLabel = SKLabelNode(text: "Be the first to set a high score!")
        subLabel.fontName = "AvenirNext-Regular"
        subLabel.fontSize = 18
        subLabel.fontColor = UIColor(white: 0.8, alpha: 1.0)
        subLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 30)
        leaderboardContainer.addChild(subLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
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
}

// Helper extension for Bool
// Note: Bool.random(percentage:) is defined in GameScene.swift; avoid re-declaration here