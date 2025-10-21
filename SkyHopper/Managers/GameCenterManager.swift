import GameKit

class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    
    // Game Center authentication status
    private(set) var isAuthenticated = false
    private(set) var authError: Error?
    
    // Leaderboard IDs
    private let mainLeaderboardID = "com.skyhopper.highscore"
    private let mapLeaderboardIDs = [
        "city": "com.skyhopper.highscore.city",
        "forest": "com.skyhopper.highscore.forest",
        "mountain": "com.skyhopper.highscore.mountain",
        "space": "com.skyhopper.highscore.space",
        "underwater": "com.skyhopper.highscore.underwater",
        "desert": "com.skyhopper.highscore.desert",
        "halloween": "com.skyhopper.highscore.halloween",
        "christmas": "com.skyhopper.highscore.christmas",
        "summer": "com.skyhopper.highscore.summer"
    ]
    
    // Delegate for updates
    weak var delegate: GameCenterManagerDelegate?
    
    // Initialize and authenticate the player
    func authenticatePlayer() {
        // Check for all possible Game Center entitlement locations
        let entitlementPaths = [
            Bundle.main.path(forResource: "SkyHopper", ofType: "entitlements"),
            Bundle.main.path(forResource: "SkyHopper/SkyHopper", ofType: "entitlements")
        ]
        let hasEntitlement = entitlementPaths.contains { $0 != nil }
        
        // Check for GameKit capability in various Info.plist files
        let gameKitInfoPaths = [
            Bundle.main.path(forResource: "GameKit-Info", ofType: "plist"),
            Bundle.main.path(forResource: "GameKitInfo", ofType: "plist")
        ]
        let hasGameKitCapability = gameKitInfoPaths.contains { $0 != nil }
        
        // Check if gamekit is in the main Info.plist
        var hasGameKitInMainPlist = false
        if let capabilities = Bundle.main.infoDictionary?["UIRequiredDeviceCapabilities"] as? [String] {
            hasGameKitInMainPlist = capabilities.contains("gamekit")
        }
        
        // Log diagnostic information
        print("Game Center authentication diagnostics:")
        print("- Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("- Entitlement file found: \(hasEntitlement)")
        print("- GameKit capability file found: \(hasGameKitCapability)")
        print("- GameKit in main Info.plist: \(hasGameKitInMainPlist)")
        
        if !hasEntitlement && !hasGameKitCapability && !hasGameKitInMainPlist {
            print("WARNING: No Game Center entitlement or GameKit capability found! Authentication will fail.")
            print("To fix this issue, you need to:")
            print("1. Add com.apple.developer.game-center entitlement to your project")
            print("2. Add gamekit to UIRequiredDeviceCapabilities in Info.plist")
            print("3. Enable Game Center capability in Xcode project settings")
        }
        
        // Register for game center authentication notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationChanged),
            name: NSNotification.Name.GKPlayerAuthenticationDidChangeNotificationName,
            object: nil
        )
        
        // Try to manually inject the GameKit capability from our GameKitInfo.plist
        if let gameKitInfoPath = gameKitInfoPaths.compactMap({ $0 }).first,
           let gameKitDict = NSDictionary(contentsOfFile: gameKitInfoPath) as? [String: Any] {
            
            // Log that we're using the custom GameKit info
            print("Using custom GameKit configuration from \(gameKitInfoPath)")
            
            // Try to modify the main bundle's info dictionary (this is a workaround and may not work)
            if let bundleInfoDict = Bundle.main.infoDictionary as? NSMutableDictionary {
                if let requiredCapabilities = gameKitDict["UIRequiredDeviceCapabilities"] as? [String] {
                    bundleInfoDict["UIRequiredDeviceCapabilities"] = requiredCapabilities
                }
                if let compatMode = gameKitDict["GKGameCenterCompatibilityMode"] as? String {
                    bundleInfoDict["GKGameCenterCompatibilityMode"] = compatMode
                }
            }
        }
        
        let localPlayer = GKLocalPlayer.local
        
        // Set authentication handler
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            if let viewController = viewController {
                // Present the view controller for authentication
                print("Game Center authentication requires UI interaction")
                self.delegate?.presentGameCenterViewController(viewController)
            } else if localPlayer.isAuthenticated {
                // Player successfully authenticated
                self.isAuthenticated = true
                self.authError = nil
                print("Game Center authentication successful: \(localPlayer.displayName)")
                
                // Register for notifications
                if #available(iOS 14.0, *) {
                    self.registerForGameCenterNotifications()
                }
                
                // Load achievements and leaderboards with delay to ensure authentication is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.loadLeaderboards()
                    AchievementManager.shared.syncWithGameCenter()
                }
                
                // Notify delegate
                self.delegate?.gameCenterAuthenticationChanged(true)
            } else {
                // Authentication failed
                self.isAuthenticated = false
                self.authError = error
                print("Game Center authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                
                // Check if Game Center is available
                if GKLocalPlayer.local.isUnderage {
                    print("User is underage - Game Center access may be restricted")
                }
                
                // Note: isMultiplayerGamingEnabled was removed in newer iOS versions
                // We'll check authentication status instead
                if !GKLocalPlayer.local.isAuthenticated {
                    print("Player is not authenticated with Game Center")
                }
                
                // Notify delegate
                self.delegate?.gameCenterAuthenticationChanged(false)
            }
        }
    }
    
    @available(iOS 14.0, *)
    private func registerForGameCenterNotifications() {
        // Modern way to register for notifications
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleAuthenticationChanged),
                                             name: NSNotification.Name.GKPlayerAuthenticationDidChangeNotificationName,
                                             object: nil)
    }
    
    @objc private func handleAuthenticationChanged() {
        isAuthenticated = GKLocalPlayer.local.isAuthenticated
        delegate?.gameCenterAuthenticationChanged(isAuthenticated)
    }
    
    // Load leaderboards
    private func loadLeaderboards() {
        GKLeaderboard.loadLeaderboards(IDs: [mainLeaderboardID]) { leaderboards, error in
            if let error = error {
                print("Error loading leaderboards: \(error.localizedDescription)")
            }
        }
    }
    
    // Submit score to the main leaderboard
    func submitScore(_ score: Int, completion: ((Bool, Error?) -> Void)? = nil) {
        guard isAuthenticated else {
            print("Cannot submit score - player not authenticated")
            completion?(false, NSError(domain: "GameCenterManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player not authenticated"]))
            return
        }
        
        if #available(iOS 14.0, *) {
            // Use modern API for iOS 14+
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                      leaderboardIDs: [mainLeaderboardID]) { error in
                if let error = error {
                    print("Failed to submit high score to Game Center: \(error.localizedDescription)")
                    completion?(false, error)
                } else {
                    print("Successfully submitted high score to Game Center")
                    completion?(true, nil)
                }
            }
        } else {
            // Fallback for earlier iOS versions
            #if !targetEnvironment(simulator)
            let scoreReporter = GKScore(leaderboardIdentifier: mainLeaderboardID)
            scoreReporter.value = Int64(score)
            
            GKScore.report([scoreReporter]) { error in
                if let error = error {
                    print("Failed to submit high score to Game Center: \(error.localizedDescription)")
                    completion?(false, error)
                } else {
                    print("Successfully submitted high score to Game Center")
                    completion?(true, nil)
                }
            }
            #else
            print("Score submission in simulator: \(score)")
            completion?(true, nil)
            #endif
        }
    }
    
    // Submit score to a specific map leaderboard
    func submitMapScore(_ score: Int, for mapID: String, completion: ((Bool, Error?) -> Void)? = nil) {
        print("DEBUG: Attempting to submit map score - Score: \(score), MapID: '\(mapID)', Authenticated: \(isAuthenticated)")
        
        guard isAuthenticated else {
            print("Cannot submit map score - player not authenticated")
            completion?(false, NSError(domain: "GameCenterManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player not authenticated"]))
            return
        }
        
        guard let leaderboardID = mapLeaderboardIDs[mapID] else {
            print("Invalid map ID: '\(mapID)' - Available IDs: \(mapLeaderboardIDs.keys.sorted())")
            completion?(false, NSError(domain: "GameCenterManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid map ID"]))
            return
        }
        
        print("DEBUG: Using leaderboard ID: '\(leaderboardID)' for map: '\(mapID)'")
        
        if #available(iOS 14.0, *) {
            // Use modern API for iOS 14+
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                     leaderboardIDs: [leaderboardID]) { error in
                if let error = error {
                    print("Failed to submit map score to Game Center: \(error.localizedDescription)")
                    completion?(false, error)
                } else {
                    print("Successfully submitted map score to Game Center")
                    completion?(true, nil)
                }
            }
        } else {
            // Fallback for earlier iOS versions
            #if !targetEnvironment(simulator)
            let scoreReporter = GKScore(leaderboardIdentifier: leaderboardID)
            scoreReporter.value = Int64(score)
            
            GKScore.report([scoreReporter]) { error in
                if let error = error {
                    print("Failed to submit map score to Game Center: \(error.localizedDescription)")
                    completion?(false, error)
                } else {
                    print("Successfully submitted map score to Game Center")
                    completion?(true, nil)
                }
            }
            #else
            print("Map score submission in simulator: \(score)")
            completion?(true, nil)
            #endif
        }
    }
    
    // Show the Game Center leaderboard
    func showLeaderboard() {
        guard isAuthenticated else {
            print("Cannot show leaderboard - player not authenticated")
            return
        }
        
        let gcViewController = GKGameCenterViewController(leaderboardID: mainLeaderboardID, playerScope: .global, timeScope: .allTime)
        gcViewController.gameCenterDelegate = self
        
        delegate?.presentGameCenterViewController(gcViewController)
    }
    
    // Show a specific map leaderboard
    func showMapLeaderboard(for mapID: String) {
        guard isAuthenticated else {
            print("Cannot show map leaderboard - player not authenticated")
            return
        }
        
        guard let leaderboardID = mapLeaderboardIDs[mapID] else {
            print("Invalid map ID: \(mapID)")
            return
        }
        
        let gcViewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        gcViewController.gameCenterDelegate = self
        
        delegate?.presentGameCenterViewController(gcViewController)
    }
    
    // Show Game Center achievements
    func showAchievements() {
        guard isAuthenticated else {
            print("Cannot show achievements - player not authenticated")
            return
        }
        
        let gcViewController = GKGameCenterViewController(state: .achievements)
        gcViewController.gameCenterDelegate = self
        
        delegate?.presentGameCenterViewController(gcViewController)
    }
    
    // Get player data
    func getPlayerData(completion: @escaping (GKPlayer?, Error?) -> Void) {
        guard isAuthenticated else {
            completion(nil, NSError(domain: "GameCenterManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player not authenticated"]))
            return
        }
        
        completion(GKLocalPlayer.local, nil)
    }
    
    // Get player display name (limited to 8 characters for UI)
    func getPlayerDisplayName() -> String {
        let localPlayer = GKLocalPlayer.local
        print("DEBUG: GameCenter Auth Status - isAuthenticated: \(isAuthenticated), localPlayer.isAuthenticated: \(localPlayer.isAuthenticated)")
        print("DEBUG: GameCenter availability - GKLocalPlayer.local.isUnderage: \(localPlayer.isUnderage)")
        
        guard isAuthenticated && localPlayer.isAuthenticated else {
            print("DEBUG: Player not authenticated - showing Guest")
            return "Guest"
        }
        
        let displayName = localPlayer.displayName
        print("DEBUG: Player display name: '\(displayName)'")
        
        // Limit to 8 characters for UI constraints
        if displayName.count > 8 {
            return String(displayName.prefix(8))
        }
        
        return displayName
    }
    
    // Get player alias (alternative shorter name)
    func getPlayerAlias() -> String {
        guard isAuthenticated else {
            return "Guest"
        }
        
        let localPlayer = GKLocalPlayer.local
        let alias = localPlayer.alias
        
        // Limit to 8 characters for UI constraints
        if alias.count > 8 {
            return String(alias.prefix(8))
        }
        
        return alias.isEmpty ? getPlayerDisplayName() : alias
    }
    
    // Get friends
    func loadFriends(completion: @escaping ([GKPlayer]?, Error?) -> Void) {
        guard isAuthenticated else {
            completion(nil, NSError(domain: "GameCenterManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player not authenticated"]))
            return
        }
        
        GKLocalPlayer.local.loadFriends { (players, error) in
            if let error = error {
                print("Failed to load friends: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            completion(players, nil)
        }
    }
}

// MARK: - Game Center View Controller Delegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        delegate?.dismissGameCenterViewController(gameCenterViewController)
    }
}

// MARK: - Game Center Manager Delegate Protocol
protocol GameCenterManagerDelegate: AnyObject {
    func presentGameCenterViewController(_ viewController: UIViewController)
    func dismissGameCenterViewController(_ viewController: UIViewController)
    func gameCenterAuthenticationChanged(_ isAuthenticated: Bool)
}