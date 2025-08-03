import UIKit
import SpriteKit
import GameplayKit
import GameKit

class GameViewController: UIViewController, GameCenterManagerDelegate {

    private let gameCenterManager = GameCenterManager.shared
    private var leaderboardButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up Game Center delegate
        gameCenterManager.delegate = self
        gameCenterManager.authenticatePlayer()
        
        // Configure the view
        if let view = self.view as! SKView? {
            print("Setting up SKView")
            
            // Debug visualization - set these BEFORE presenting the scene
            view.showsFPS = true
            view.showsNodeCount = true
            view.ignoresSiblingOrder = true
            
            // Create the main menu scene instead of going directly to game
            let scene = MainMenuScene(size: view.frame.size)
            
            // Set the scene's scale mode
            scene.scaleMode = .resizeFill
            
            // Present the scene
            view.presentScene(scene)
            
            print("Scene presented successfully")
        } else {
            print("Failed to get SKView")
        }
        
        // Start audio
        AudioManager.shared.playBackgroundMusic()
    }
    
    // MARK: - Game Center Methods
    
    // Present Game Center view controller
    func presentGameCenterViewController(_ viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
    
    // Dismiss Game Center view controller
    func dismissGameCenterViewController(_ viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // Handle authentication changes
    func gameCenterAuthenticationChanged(_ isAuthenticated: Bool) {
        if isAuthenticated {
            print("Game Center authentication successful")
        } else {
            print("Game Center authentication failed or was declined")
        }
    }
    
    // MARK: - Device Orientation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - System Lifecycle
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the game when the view disappears
        if let view = self.view as? SKView, let scene = view.scene {
            scene.isPaused = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Resume the game when the view appears
        if let view = self.view as? SKView, let scene = view.scene {
            scene.isPaused = false
        }
    }
    
    // Handle memory warnings
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Clear any caches or non-essential resources
        print("Memory warning received")
    }
}