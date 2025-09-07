import SpriteKit
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    // Audio players
    private var musicPlayer: AVAudioPlayer?
    private var speedBoostMusicPlayer: AVAudioPlayer?
    private var effectsPlayers: [String: AVAudioPlayer] = [:]
    
    // Audio state
    private var isMusicPlaying = false
    private var isSpeedBoostActive = false
    private var musicVolume: Float = 0.5
    private var effectsVolume: Float = 0.7
    private var isMusicEnabled = true
    private var areEffectsEnabled = true
    
    // Audio assets
    enum MusicTrack: String {
        case main = "main_theme"
        case speedBoost = "speed_boost_theme"
        // Map-specific themes with 8-bit style
        case city = "city_theme"
        case forest = "forest_theme"
        case mountain = "mountain_theme"
        case space = "space_theme"
        case underwater = "underwater_theme"
        case desert = "desert_theme"
        // Special themed music
        case stargate = "stargate_theme" // Dune/Stargate inspired theme for desert maps
        case arcade = "arcade_theme"     // Classic arcade style for city maps
        case retro = "retro_theme"       // General retro theme
        // Seasonal themes
        case halloween = "halloween_theme"
        case christmas = "christmas_theme"
    }
    
    enum SoundEffect: String {
        case jump = "jump"
        case crash = "crash"
        // Character-specific crash sounds
        case duckCrash = "duck_crash"
        case birdCrash = "bird_crash"
        case dragonCrash = "dragon_crash"
        case biplaneCrash = "biplane_crash"
        case jetCrash = "jet_crash"
        case helicopterCrash = "helicopter_crash"
        case ufoCrash = "ufo_crash"
        case rocketCrash = "rocket_crash"
        // Collection sounds
        case collect = "collect"
        case menuTap = "menu_tap"
        case achievement = "achievement"
        case gameOver = "game_over"
        case powerUp = "power_up"
        case coinCollect = "coin_collect"
        case gemCollect = "gem_collect"
        case unlock = "unlock"
        // Theme-specific sounds
        case explosion = "explosion"
        case splash = "splash"
        case wind = "wind"
        case stargate = "stargate"
        case yeti = "yeti"
        // Music themes
        case duneTheme = "dune_theme"
        case stargateTheme = "stargate_theme"
        case arcadeTheme = "arcade_theme"
        case underwaterTheme = "underwater_theme"
    }
    
    private init() {
        setupAudio()
        loadSettings()
        
        // Listen for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSpeedBoostActivated),
            name: NSNotification.Name("SpeedBoostActivated"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSpeedBoostDeactivated),
            name: NSNotification.Name("SpeedBoostDeactivated"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Load sound effects and music
        preloadSoundEffects()
        preloadMusic()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        musicVolume = Float(defaults.double(forKey: "musicVolume"))
        effectsVolume = Float(defaults.double(forKey: "effectsVolume"))
        isMusicEnabled = defaults.bool(forKey: "isMusicEnabled")
        areEffectsEnabled = defaults.bool(forKey: "areEffectsEnabled")
        
        // Set default values if not set
        if musicVolume == 0 { musicVolume = 0.5 }
        if effectsVolume == 0 { effectsVolume = 0.7 }
        if defaults.object(forKey: "isMusicEnabled") == nil { 
            isMusicEnabled = true 
            defaults.set(true, forKey: "isMusicEnabled")
        }
        if defaults.object(forKey: "areEffectsEnabled") == nil { 
            areEffectsEnabled = true 
            defaults.set(true, forKey: "areEffectsEnabled")
        }
    }
    
    // MARK: - Loading Audio Files
    
    private func preloadSoundEffects() {
        // Load all sound effects
        for effect in SoundEffect.allCases {
            loadSoundEffect(effect)
        }
    }
    
    private func loadSoundEffect(_ effect: SoundEffect) {
        // Try to load the sound effect from the bundle
        // First check in Resources/Audio/SFX (direct path)
        if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Resources/Audio/SFX") ??
                   Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3", subdirectory: "Resources/Audio/SFX") ??
                   Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Audio/SFX") ??
                   Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3", subdirectory: "Audio/SFX") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = effectsVolume
                effectsPlayers[effect.rawValue] = player
                print("Loaded sound effect from Resources/Audio/SFX: \(effect.rawValue)")
                return
            } catch {
                print("Could not load sound effect from Resources/Audio/SFX '\(effect.rawValue)': \(error)")
            }
        }
        
        // Then check in Sounds directory (legacy location)
        if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Sounds") ??
                   Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3", subdirectory: "Sounds") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = effectsVolume
                effectsPlayers[effect.rawValue] = player
                print("Loaded sound effect from Sounds: \(effect.rawValue)")
                return
            } catch {
                print("Could not load sound effect from Sounds '\(effect.rawValue)': \(error)")
            }
        }
        
        // Special case for crash and duck_crash from our new files
        if effect == .crash {
            if let url = Bundle.main.url(forResource: "crash_FX", withExtension: "mp3", subdirectory: "Resources/Audio/SFX") ??
                      Bundle.main.url(forResource: "crash_FX", withExtension: "mp3", subdirectory: "Audio/SFX") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = effectsVolume
                    effectsPlayers[effect.rawValue] = player
                    print("Loaded crash sound from crash_FX.mp3")
                    return
                } catch {
                    print("Could not load crash_FX.mp3: \(error)")
                }
            }
        } else if effect == .duckCrash {
            if let url = Bundle.main.url(forResource: "quack_FX", withExtension: "mp3", subdirectory: "Resources/Audio/SFX") ??
                      Bundle.main.url(forResource: "quack_FX", withExtension: "mp3", subdirectory: "Audio/SFX") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = effectsVolume
                    effectsPlayers[effect.rawValue] = player
                    print("Loaded duck crash sound from quack_FX.mp3")
                    return
                } catch {
                    print("Could not load quack_FX.mp3: \(error)")
                }
            }
        }
        
        // If file not found, create a procedural sound
        print("Using fallback sound for: \(effect.rawValue)")
        createFallbackSoundEffect(for: effect)
    }
    
    private func preloadMusic() {
        // Try to load the main theme from Resources/Audio/Music
        if let url = Bundle.main.url(forResource: "menu_soundtrack", withExtension: "wav", subdirectory: "Resources/Audio/Music") ??
                   Bundle.main.url(forResource: "menu_soundtrack", withExtension: "wav", subdirectory: "Audio/Music") {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1 // Loop indefinitely
                musicPlayer?.volume = musicVolume
                musicPlayer?.prepareToPlay()
                print("Loaded main menu music from menu_soundtrack.wav")
            } catch {
                print("Could not load menu_soundtrack.wav: \(error)")
                tryLegacyMusicLoading()
            }
        } else {
            // Try legacy location
            tryLegacyMusicLoading()
        }
        
        // Try to load the speed boost theme
        if let url = Bundle.main.url(forResource: MusicTrack.speedBoost.rawValue, withExtension: "mp3", subdirectory: "Sounds") {
            do {
                speedBoostMusicPlayer = try AVAudioPlayer(contentsOf: url)
                speedBoostMusicPlayer?.numberOfLoops = -1
                speedBoostMusicPlayer?.volume = musicVolume
                speedBoostMusicPlayer?.prepareToPlay()
            } catch {
                print("Could not load speed boost music: \(error)")
            }
        }
    }
    
    private func tryLegacyMusicLoading() {
        // Try to load the main theme from Sounds directory
        if let url = Bundle.main.url(forResource: MusicTrack.main.rawValue, withExtension: "mp3", subdirectory: "Sounds") {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1 // Loop indefinitely
                musicPlayer?.volume = musicVolume
                musicPlayer?.prepareToPlay()
                print("Loaded main theme music from Sounds directory")
            } catch {
                print("Could not load main theme music: \(error)")
                createFallbackMusic()
            }
        } else {
            createFallbackMusic()
        }
    }
    
    private func createFallbackSoundEffect(for effect: SoundEffect) {
        // Create a system sound as fallback
        switch effect {
        case .jump:
            SystemSoundID.play(.uiSwitch)
            
        // Basic crash sounds
        case .crash:
            SystemSoundID.play(.uiError)
            
        // Character-specific crash sounds
        case .duckCrash:
            // Duck quack sound
            playSequence([.uiTock, .uiTock])
        case .birdCrash:
            // Bird squawk sound
            playSequence([.uiError, .uiSwitch])
        case .dragonCrash:
            // Dragon roar sound
            playSequence([.uiError, .uiError])
        case .biplaneCrash:
            // Biplane engine sputter
            playSequence([.uiKeyPressed, .uiError])
        case .jetCrash:
            // Jet engine failure
            playSequence([.uiSwitch, .uiError])
        case .helicopterCrash:
            // Helicopter blade failure
            playSequence([.uiTock, .uiTock, .uiError])
        case .ufoCrash:
            // UFO electronic failure
            playSequence([.uiSwitch, .uiSwitch, .uiError])
        case .rocketCrash:
            // Rocket explosion
            playSequence([.uiError, .uiSuccess])
            
        // Collection sounds
        case .collect, .coinCollect, .gemCollect:
            SystemSoundID.play(.uiKeyPressed)
        case .menuTap:
            SystemSoundID.play(.uiTock)
        case .achievement, .unlock:
            SystemSoundID.play(.uiSuccess)
        case .gameOver:
            SystemSoundID.play(.uiError)
        case .powerUp:
            SystemSoundID.play(.uiKeyPressed)
            
        // Theme-specific sounds
        case .explosion:
            SystemSoundID.play(.uiError)
        case .splash:
            SystemSoundID.play(.uiKeyPressed)
        case .wind:
            SystemSoundID.play(.uiKeyPressed)
        case .stargate:
            SystemSoundID.play(.uiSuccess)
        case .yeti:
            SystemSoundID.play(.uiError)
            
        // Music themes - these would normally be handled differently
        case .duneTheme, .stargateTheme, .arcadeTheme, .underwaterTheme:
            // Music themes don't have simple fallbacks
            break
        }
    }
    
    /// Plays a sequence of system sounds with a small delay between them
    private func playSequence(_ sounds: [SystemSoundID.SystemSound]) {
        guard !sounds.isEmpty else { return }
        
        // Play the first sound immediately
        SystemSoundID.play(sounds[0])
        
        // Play the rest with delays
        for i in 1..<sounds.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 * Double(i)) {
                SystemSoundID.play(sounds[i])
            }
        }
    }
    
    private func createFallbackMusic() {
        print("Using fallback system sounds for background music")
    }
    
    // MARK: - Music Control
    
    func playBackgroundMusic(for mapTheme: MapManager.MapTheme? = nil) {
        guard isMusicEnabled else { return }
        
        // If a specific map theme is provided, try to play that theme's music
        if let mapTheme = mapTheme {
            let themeTrack: MusicTrack
            let levelId = getLevelId()
            
            // Special case for Stargate Escape level - use Dune/Stargate inspired theme
            if levelId == "desert_escape" || levelId?.contains("stargate") == true {
                themeTrack = .stargate
            } else {
                // Map theme based music selection
                switch mapTheme {
                case .city:
                    // City maps get arcade style music
                    themeTrack = .arcade
                case .forest:
                    themeTrack = .forest
                case .mountain:
                    themeTrack = .mountain
                case .space:
                    themeTrack = .space
                case .underwater:
                    themeTrack = .underwater
                case .desert:
                    // Regular desert maps
                    themeTrack = .desert
                case .halloween:
                    themeTrack = .halloween
                case .christmas:
                    themeTrack = .christmas
                case .summer:
                    themeTrack = .retro
                }
            }
            
            // First try to load from our new Resources/Audio/Music directory
            let soundtrackName: String
            switch mapTheme {
            case .city:
                soundtrackName = "city_soundtrack"
            case .forest:
                soundtrackName = "forest_soundtrack"
            case .mountain:
                soundtrackName = "mountain_soundtrack"
            case .space:
                soundtrackName = "space_soundtrack"
            case .underwater:
                soundtrackName = "water_soundtrack"
            case .desert:
                soundtrackName = "menu_soundtrack" // Fallback for desert
            default:
                soundtrackName = "menu_soundtrack"
            }
            
            if let url = Bundle.main.url(forResource: soundtrackName, withExtension: "wav", subdirectory: "Resources/Audio/Music") ??
                       Bundle.main.url(forResource: soundtrackName, withExtension: "wav", subdirectory: "Audio/Music") {
                do {
                    // Stop current music if playing
                    musicPlayer?.stop()
                    
                    // Load and play the new theme
                    musicPlayer = try AVAudioPlayer(contentsOf: url)
                    musicPlayer?.numberOfLoops = -1
                    musicPlayer?.volume = musicVolume
                    musicPlayer?.prepareToPlay()
                    musicPlayer?.play()
                    
                    print("Playing music theme from Resources/Audio/Music: \(soundtrackName)")
                    isMusicPlaying = true
                    return
                } catch {
                    print("Could not load theme music from Resources/Audio/Music for \(mapTheme): \(error)")
                    // Fall through to legacy music
                }
            }
            
            // Try to load and play the theme-specific music from legacy location
            if let url = Bundle.main.url(forResource: themeTrack.rawValue, withExtension: "mp3", subdirectory: "Sounds") {
                do {
                    // Stop current music if playing
                    musicPlayer?.stop()
                    
                    // Load and play the new theme
                    musicPlayer = try AVAudioPlayer(contentsOf: url)
                    musicPlayer?.numberOfLoops = -1
                    musicPlayer?.volume = musicVolume
                    musicPlayer?.prepareToPlay()
                    musicPlayer?.play()
                    
                    print("Playing 8-bit music theme from Sounds: \(themeTrack.rawValue)")
                    isMusicPlaying = true
                    return
                } catch {
                    print("Could not load theme music from Sounds for \(mapTheme): \(error)")
                    // Fall through to default music
                }
            } else {
                // Try to load special effect sounds if music file not found
                if themeTrack == .stargate {
                    playEffect(.stargateTheme)
                } else if themeTrack == .arcade {
                    playEffect(.arcadeTheme)
                }
            }
        }
        
        // Default to main theme if no theme-specific music is available
        if let player = musicPlayer {
            player.volume = musicVolume
            player.play()
            isMusicPlaying = true
        } else {
            print("Playing background music (fallback)")
            isMusicPlaying = true
        }
    }
    
    /// Helper method to get the current level ID from the game scene
    private func getLevelId() -> String? {
        // This is a simple method to check if we're in the "Stargate Escape" level
        // In a real implementation, you would get this from the game state
        let levelKeys = ["desert_escape", "stargate_escape", "dune_escape"]
        let userDefaults = UserDefaults.standard
        
        for key in levelKeys {
            if userDefaults.string(forKey: "currentLevel") == key {
                return key
            }
        }
        
        return nil
    }
    
    func stopBackgroundMusic() {
        musicPlayer?.stop()
        isMusicPlaying = false
    }
    
    func activateSpeedBoostMusic() {
        guard isMusicEnabled else { return }
        
        if let player = speedBoostMusicPlayer {
            // Fade out normal music
            fadeOutPlayer(musicPlayer, duration: 0.5)
            
            // Start speed boost music
            player.volume = 0
            player.play()
            fadeInPlayer(player, duration: 0.5)
            isSpeedBoostActive = true
        } else if let currentMusic = musicPlayer {
            // If no dedicated speed boost track, increase the tempo of current music
            currentMusic.rate = 1.3 // Play 30% faster
            isSpeedBoostActive = true
        }
    }
    
    func deactivateSpeedBoostMusic() {
        guard isSpeedBoostActive else { return }
        
        if let player = speedBoostMusicPlayer {
            // Fade out speed boost music
            fadeOutPlayer(player, duration: 0.5)
            
            // Resume normal music
            if isMusicPlaying {
                musicPlayer?.volume = 0
                musicPlayer?.play()
                fadeInPlayer(musicPlayer, duration: 0.5)
            }
        } else if let currentMusic = musicPlayer {
            // Reset tempo to normal
            currentMusic.rate = 1.0
        }
        
        isSpeedBoostActive = false
    }
    
    private func fadeOutPlayer(_ player: AVAudioPlayer?, duration: TimeInterval) {
        guard let player = player else { return }
        
        let startVolume = player.volume
        let fadeOutSteps = 20
        let volumeDecrement = startVolume / Float(fadeOutSteps)
        let stepTime = duration / TimeInterval(fadeOutSteps)
        
        for i in 0..<fadeOutSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTime * Double(i)) {
                player.volume = startVolume - (volumeDecrement * Float(i))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            player.pause()
            player.volume = startVolume
        }
    }
    
    private func fadeInPlayer(_ player: AVAudioPlayer?, duration: TimeInterval) {
        guard let player = player else { return }
        
        let endVolume = musicVolume
        let fadeInSteps = 20
        let volumeIncrement = endVolume / Float(fadeInSteps)
        let stepTime = duration / TimeInterval(fadeInSteps)
        
        player.volume = 0
        player.play()
        
        for i in 0..<fadeInSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTime * Double(i)) {
                player.volume = volumeIncrement * Float(i)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            player.volume = endVolume
        }
    }
    
    // MARK: - Sound Effects
    
    func playEffect(_ effect: SoundEffect) {
        guard areEffectsEnabled else { return }
        
        if let player = effectsPlayers[effect.rawValue] {
            // Clone the player to allow overlapping sounds
            let clonedPlayer = player.copy() as! AVAudioPlayer
            clonedPlayer.volume = effectsVolume
            clonedPlayer.play()
        } else {
            print("Playing sound effect: \(effect.rawValue)")
            createFallbackSoundEffect(for: effect)
        }
    }
    
    func playThemeSpecificEffect(for mapTheme: MapManager.MapTheme, event: String) {
        // Play theme-appropriate sound effects for common events
        switch (mapTheme, event) {
        case (.underwater, "obstacle"):
            playEffect(.splash)
        case (.space, "obstacle"):
            playEffect(.explosion)
        case (.mountain, "obstacle"):
            playEffect(.wind)
        case (.city, "obstacle"), (.forest, "obstacle"), (.desert, "obstacle"):
            playEffect(.crash)
        case (_, "collect"):
            playEffect(.collect)
        case (_, "coin"):
            playEffect(.coinCollect)
        case (_, "gem"):
            playEffect(.gemCollect)
        case (_, "jump"):
            playEffect(.jump)
        case (_, "powerup"):
            playEffect(.powerUp)
        case (.space, "portal"):
            playEffect(.stargate)
        case (.mountain, "yeti"):
            playEffect(.yeti)
        default:
            // Default to generic sound
            playEffect(.menuTap)
        }
    }
    
    /// Plays a crash sound specific to the aircraft type
    func playCharacterCrashSound(for aircraftType: CharacterManager.AircraftType) {
        switch aircraftType {
        case .duck:
            playEffect(.duckCrash)
        case .eagle:
            playEffect(.birdCrash)
        case .dragon:
            playEffect(.dragonCrash)
        case .biplane:
            playEffect(.biplaneCrash)
        case .fighterJet, .f22Raptor:
            playEffect(.jetCrash)
        case .helicopter:
            playEffect(.helicopterCrash)
        case .ufo:
            playEffect(.ufoCrash)
        case .rocketPack:
            playEffect(.rocketCrash)
        case .mustangPlane:
            playEffect(.biplaneCrash) // Similar to biplane
        case .mapDefault:
            // Use theme-specific crash sound
            playEffect(.crash)
        }
    }
    
    // MARK: - Settings
    
    func setMusicVolume(_ volume: Float) {
        musicVolume = volume
        musicPlayer?.volume = volume
        speedBoostMusicPlayer?.volume = volume
        UserDefaults.standard.set(Double(volume), forKey: "musicVolume")
    }
    
    func setEffectsVolume(_ volume: Float) {
        effectsVolume = volume
        UserDefaults.standard.set(Double(volume), forKey: "effectsVolume")
    }
    
    func toggleMusic(_ enabled: Bool) {
        isMusicEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "isMusicEnabled")
        
        if enabled && !isMusicPlaying {
            playBackgroundMusic()
        } else if !enabled && isMusicPlaying {
            stopBackgroundMusic()
        }
    }
    
    func toggleEffects(_ enabled: Bool) {
        areEffectsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "areEffectsEnabled")
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleSpeedBoostActivated() {
        activateSpeedBoostMusic()
    }
    
    @objc private func handleSpeedBoostDeactivated() {
        deactivateSpeedBoostMusic()
    }
    
    // MARK: - Map Theme Music
    
    func switchMusicForMapTheme(_ mapTheme: MapManager.MapTheme) {
        stopBackgroundMusic()
        playBackgroundMusic(for: mapTheme)
    }
}

// MARK: - System Sound Extensions

extension SystemSoundID {
    enum SystemSound {
        case uiSwitch
        case uiTock
        case uiKeyPressed
        case uiError
        case uiSuccess
        
        var id: SystemSoundID {
            switch self {
            case .uiSwitch:
                return 1104
            case .uiTock:
                return 1105
            case .uiKeyPressed:
                return 1103
            case .uiError:
                return 1073
            case .uiSuccess:
                return 1001
            }
        }
    }
    
    static func play(_ sound: SystemSound) {
        AudioServicesPlaySystemSound(sound.id)
    }
}

// MARK: - SoundEffect Conformance

extension AudioManager.SoundEffect: CaseIterable {}