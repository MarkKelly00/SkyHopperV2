import SpriteKit

// MARK: - Audio Integration
extension GameScene {
    
    /// Sets up the audio for the current level
    func setupAudio() {
        // Stop any currently playing music first
        AudioManager.shared.stopBackgroundMusic()
        
        // Get the current map theme from the level data or map manager
        let mapTheme = currentLevel?.mapTheme ?? MapManager.shared.currentMap
        
        // Start the appropriate background music for this theme
        AudioManager.shared.playBackgroundMusic(for: mapTheme)
    }
    
    /// Plays appropriate sound effects for player actions
    func playPlayerSound(action: String) {
        let mapTheme = currentLevel?.mapTheme ?? MapManager.shared.currentMap
        
        switch action {
        case "jump":
            AudioManager.shared.playEffect(.jump)
        case "crash":
            // Get the current aircraft type
            if let playerNode = childNode(withName: "player"),
               let aircraftType = playerNode.userData?.value(forKey: "aircraftType") as? CharacterManager.AircraftType {
                // Play character-specific crash sound
                AudioManager.shared.playCharacterCrashSound(for: aircraftType)
            } else {
                // Fallback to theme-specific crash sound
                AudioManager.shared.playThemeSpecificEffect(for: mapTheme, event: "obstacle")
            }
        case "collect":
            AudioManager.shared.playEffect(.collect)
        case "coin":
            AudioManager.shared.playEffect(.coinCollect)
        case "gem":
            AudioManager.shared.playEffect(.gemCollect)
        case "powerup":
            AudioManager.shared.playEffect(.powerUp)
        case "starpower":
            AudioManager.shared.playEffect(.starPower)
        case "multiplier":
            AudioManager.shared.playEffect(.multiplier)
        case "magnify":
            AudioManager.shared.playEffect(.magnify)
        case "ghost":
            AudioManager.shared.playEffect(.ghost)
        case "forcefield":
            AudioManager.shared.playEffect(.forcefield)
        case "destroyobject":
            AudioManager.shared.playEffect(.destroyObject)
        case "gameOver":
            AudioManager.shared.playEffect(.gameOver)
        case "achievement":
            AudioManager.shared.playEffect(.achievement)
        case "portal":
            if mapTheme == .space || mapTheme == .desert {
                AudioManager.shared.playEffect(.stargate)
            }
        case "yeti":
            if mapTheme == .mountain {
                AudioManager.shared.playEffect(.yeti)
            }
        default:
            break
        }
    }
    
    /// Plays the game over sound and stops background music
    func playGameOverSound() {
        AudioManager.shared.stopBackgroundMusic()
        
        // Play crash sound first, then game over sound
        playPlayerSound(action: "crash")
        
        // Schedule game over sound after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioManager.shared.playEffect(.gameOver)
        }
    }
    
    /// Updates audio based on player state
    func updateAudioForPlayerState() {
        if isInvincible {
            AudioManager.shared.activateSpeedBoostMusic()
        } else {
            AudioManager.shared.deactivateSpeedBoostMusic()
        }
    }
    
    /// Plays menu tap sound for UI interactions
    func playMenuTapSound() {
        AudioManager.shared.playEffect(.menuTap)
    }
}
