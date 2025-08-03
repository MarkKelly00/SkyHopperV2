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
        "underwater": "com.skyhopper.highscore.underwater"
    ]
    
    // Delegate for updates
    weak var delegate: GameCenterManagerDelegate?
    
    // Initialize and authenticate the player
    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            if let viewController = viewController {
                // Present the view controller for authentication
                self.delegate?.presentGameCenterViewController(viewController)
            } else if localPlayer.isAuthenticated {
                // Player successfully authenticated
                self.isAuthenticated = true
                self.authError = nil
                
                // Register for notifications
                if #available(iOS 14.0, *) {
                    self.registerForGameCenterNotifications()
                }
                
                // Load achievements and leaderboards
                self.loadLeaderboards()
                AchievementManager.shared.syncWithGameCenter()
                
                // Notify delegate
                self.delegate?.gameCenterAuthenticationChanged(true)
            } else {
                // Authentication failed
                self.isAuthenticated = false
                self.authError = error
                print("Game Center authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                
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
                                             name: NSNotification.Name("GKPlayerAuthenticationDidChangeNotificationName"),
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
        guard isAuthenticated else {
            print("Cannot submit map score - player not authenticated")
            completion?(false, NSError(domain: "GameCenterManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player not authenticated"]))
            return
        }
        
        guard let leaderboardID = mapLeaderboardIDs[mapID] else {
            print("Invalid map ID: \(mapID)")
            completion?(false, NSError(domain: "GameCenterManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid map ID"]))
            return
        }
        
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