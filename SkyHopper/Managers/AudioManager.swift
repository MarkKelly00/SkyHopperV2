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
    private var isInitialized = false
    
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
        case gameOver = "Game_Over"  // Updated to match the actual file name
        case powerUp = "power_up"
        case coinCollect = "coin_collect"
        case gemCollect = "gem_collect"
        case unlock = "unlock"
        // Power-up specific sounds
        case starPower = "starpower_FX"
        case multiplier = "multiplier_FX"
        case magnify = "magnify_FX"
        case ghost = "ghost_FX"
        case forcefield = "forcefield_FX"
        case destroyObject = "destroy_object_FX"
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
        
        // Mark initialization as complete - this prevents fallback sounds from playing during initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isInitialized = true
            print("AudioManager initialization complete")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupAudio() {
        do {
            // First deactivate any existing session
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            
            // Use .playback category with minimal options to avoid Code=-50 error
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            print("DEBUG: Audio session configured for playback")
            
            // Try to override to speaker (this may fail on some devices, which is OK)
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                print("DEBUG: Successfully overrode audio output to speaker")
            } catch {
                print("DEBUG: Could not override to speaker (this is normal on some devices): \(error)")
            }
            
        } catch {
            print("Failed to set up audio session: \(error)")
            // Fallback to ambient if playback fails
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
                print("DEBUG: Fallback to ambient audio session")
            } catch {
                print("Fallback audio session also failed: \(error)")
            }
        }
        
        // Register for audio route change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
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
        // Print debug info about bundle paths
        if effect == .crash || effect == .starPower || effect == .multiplier || effect == .magnify || 
           effect == .ghost || effect == .forcefield || effect == .destroyObject {
            // Print bundle information for debugging
            print("DEBUG: Bundle path = \(Bundle.main.bundlePath)")
            print("DEBUG: Loading sound effect: \(effect.rawValue)")
            
            // List all resources in the bundle
            if let resourcePath = Bundle.main.resourcePath {
                print("DEBUG: Checking for audio files in bundle...")
                let fileManager = FileManager.default
                do {
                    let audioFiles = try fileManager.contentsOfDirectory(atPath: resourcePath)
                        .filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") }
                    print("DEBUG: Found audio files in bundle: \(audioFiles)")
                    
                    // Check for Audio directory
                    if fileManager.fileExists(atPath: "\(resourcePath)/Audio") {
                        print("DEBUG: Audio directory exists in bundle")
                        
                        // Check for Audio/SFX directory
                        if fileManager.fileExists(atPath: "\(resourcePath)/Audio/SFX") {
                            print("DEBUG: Audio/SFX directory exists in bundle")
                            
                            // List files in Audio/SFX
                            let sfxFiles = try fileManager.contentsOfDirectory(atPath: "\(resourcePath)/Audio/SFX")
                            print("DEBUG: Files in Audio/SFX: \(sfxFiles)")
                            
                            // Check if our specific effect file exists
                            let hasWav = sfxFiles.contains("\(effect.rawValue).wav")
                            let hasMp3 = sfxFiles.contains("\(effect.rawValue).mp3")
                            print("DEBUG: \(effect.rawValue).wav exists in Audio/SFX: \(hasWav)")
                            print("DEBUG: \(effect.rawValue).mp3 exists in Audio/SFX: \(hasMp3)")
                        } else {
                            print("DEBUG: Audio/SFX directory NOT found in bundle")
                        }
                        
                        // Check for Audio/Music directory
                        if fileManager.fileExists(atPath: "\(resourcePath)/Audio/Music") {
                            print("DEBUG: Audio/Music directory exists in bundle")
                            
                            // List files in Audio/Music
                            let musicFiles = try fileManager.contentsOfDirectory(atPath: "\(resourcePath)/Audio/Music")
                            print("DEBUG: Files in Audio/Music: \(musicFiles)")
                        } else {
                            print("DEBUG: Audio/Music directory NOT found in bundle")
                        }
                    } else {
                        print("DEBUG: Audio directory NOT found in bundle")
                    }
                } catch {
                    print("DEBUG: Error listing files: \(error)")
                }
            }
        }
        
        // Try the Audio/SFX directory first (preferred location)
        if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Audio/SFX") ??
                   Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3", subdirectory: "Audio/SFX") {
            print("DEBUG: Found \(effect.rawValue) in Audio/SFX subdirectory")
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = effectsVolume
                effectsPlayers[effect.rawValue] = player
                print("Loaded sound effect from Audio/SFX: \(effect.rawValue)")
                return
            } catch {
                print("Could not load sound effect from Audio/SFX '\(effect.rawValue)': \(error)")
            }
        }
        
        // Try to load from the root directory as fallback
        if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") ??
                   Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") {
            print("DEBUG: Found \(effect.rawValue) in root bundle")
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = effectsVolume
                effectsPlayers[effect.rawValue] = player
                print("DEBUG: Successfully loaded \(effect.rawValue) from root bundle")
                return
            } catch {
                print("DEBUG: Error loading \(effect.rawValue) from root bundle: \(error)")
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
            // Try with Audio/SFX subdirectory first
            if let url = Bundle.main.url(forResource: "crash_FX", withExtension: "mp3", subdirectory: "Audio/SFX") {
                print("DEBUG: Found crash_FX.mp3 in Audio/SFX subdirectory")
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
            
            // Try with root directory as fallback
            if let url = Bundle.main.url(forResource: "crash_FX", withExtension: "mp3") {
                print("DEBUG: Found crash_FX.mp3 in root bundle")
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = effectsVolume
                    effectsPlayers[effect.rawValue] = player
                    print("DEBUG: Successfully loaded crash_FX.mp3 from root bundle")
                    return
                } catch {
                    print("DEBUG: Error loading crash_FX.mp3 from root bundle: \(error)")
                }
            }
        } else if effect == .duckCrash {
            // Try with Audio/SFX subdirectory first
            if let url = Bundle.main.url(forResource: "quack_FX", withExtension: "mp3", subdirectory: "Audio/SFX") {
                print("DEBUG: Found quack_FX.mp3 in Audio/SFX subdirectory")
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
            
            // Try with root directory as fallback
            if let url = Bundle.main.url(forResource: "quack_FX", withExtension: "mp3") {
                print("DEBUG: Found quack_FX.mp3 in root bundle")
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = effectsVolume
                    effectsPlayers[effect.rawValue] = player
                    print("DEBUG: Successfully loaded quack_FX.mp3 from root bundle")
                    return
                } catch {
                    print("DEBUG: Error loading quack_FX.mp3 from root bundle: \(error)")
                }
            }
        }
        
        // If file not found, create a procedural sound
        print("Using fallback sound for: \(effect.rawValue)")
        createFallbackSoundEffect(for: effect)
    }
    
    private func preloadMusic() {
        // Print debug info for music loading
        print("DEBUG: Trying to load music files...")
        
        // Try to load the main theme from Audio/Music first (preferred location)
        if let url = Bundle.main.url(forResource: "menu_soundtrack", withExtension: "wav", subdirectory: "Audio/Music") {
            print("DEBUG: Found menu_soundtrack.wav in Audio/Music subdirectory")
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1 // Loop indefinitely
                musicPlayer?.volume = musicVolume
                musicPlayer?.prepareToPlay()
                print("Loaded main menu music from menu_soundtrack.wav in Audio/Music")
                return
            } catch {
                print("Could not load menu_soundtrack.wav from Audio/Music: \(error)")
            }
        }
        
        // Try to load the main theme from root directory as fallback
        if let url = Bundle.main.url(forResource: "menu_soundtrack", withExtension: "wav") {
            print("DEBUG: Found menu_soundtrack.wav in root bundle")
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1 // Loop indefinitely
                musicPlayer?.volume = musicVolume
                musicPlayer?.prepareToPlay()
                print("DEBUG: Successfully loaded menu_soundtrack.wav from root bundle")
                return
            } catch {
                print("DEBUG: Error loading menu_soundtrack.wav from root bundle: \(error)")
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
        // Don't play fallback sounds during initialization
        guard isInitialized else {
            print("Skipping fallback sound during initialization for: \(effect.rawValue)")
            return
        }
        
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
            
        // Power-up specific sounds
        case .starPower:
            playSequence([.uiSuccess, .uiSuccess])
        case .multiplier:
            playSequence([.uiKeyPressed, .uiSuccess])
        case .magnify:
            SystemSoundID.play(.uiTock)
        case .ghost:
            playSequence([.uiTock, .uiTock, .uiTock])
        case .forcefield:
            playSequence([.uiSuccess, .uiKeyPressed])
        case .destroyObject:
            playSequence([.uiError, .uiError])
            
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
    
    /// Plays the menu soundtrack specifically
    func playMenuMusic() {
        guard isMusicEnabled else { return }
        
        // Stop any current music
        stopBackgroundMusic()
        
        // Try to load the menu soundtrack from root directory
        if let url = Bundle.main.url(forResource: "menu_soundtrack", withExtension: "wav") {
            print("Playing menu soundtrack")
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1 // Loop indefinitely
                musicPlayer?.volume = musicVolume
                musicPlayer?.prepareToPlay()
                musicPlayer?.play()
                isMusicPlaying = true
                return
            } catch {
                print("Error playing menu soundtrack: \(error)")
                // Fall through to default music
            }
        } else {
            print("Menu soundtrack not found, falling back to default music")
            // Fall through to default music
        }
        
        // If menu soundtrack wasn't found, use default music
        playBackgroundMusic()
    }
    
    func playBackgroundMusic(for mapTheme: MapManager.MapTheme? = nil) {
        guard isMusicEnabled else { return }
        
        print("DEBUG: playBackgroundMusic called with mapTheme: \(String(describing: mapTheme))")
        
        // FORCE CHECK FOR DESERT LEVEL/STARGATE ESCAPE
        // This is a direct check for the stargate level regardless of the mapTheme parameter
        let isStargateLevel = checkIfStargateLevel()
        print("DEBUG: isStargateLevel check result: \(isStargateLevel)")
        
        if isStargateLevel {
            print("DEBUG: DETECTED STARGATE LEVEL - Attempting to play stargate soundtrack")
            // Try to load the stargate soundtrack directly (try both wav and mp3 formats)
            if let url = Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "wav", subdirectory: "Audio/Music") ??
                       Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "mp3", subdirectory: "Audio/Music") {
                print("DEBUG: Found stargate soundtrack in Audio/Music: \(url.lastPathComponent)")
                do {
                    // Stop any existing music first
                    musicPlayer?.stop()
                    
                    musicPlayer = try AVAudioPlayer(contentsOf: url)
                    musicPlayer?.numberOfLoops = -1 // Loop indefinitely
                    musicPlayer?.volume = musicVolume
                    musicPlayer?.prepareToPlay()
                    musicPlayer?.play()
                    print("DEBUG: Successfully playing stargate soundtrack")
                    isMusicPlaying = true
                    return
                } catch {
                    print("DEBUG: Error playing stargate soundtrack: \(error)")
                }
            } else {
                print("DEBUG: Stargate soundtrack not found in Audio/Music, checking root directory")
                
                // Try in the root directory
                if let url = Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "wav") ??
                           Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "mp3") {
                    print("DEBUG: Found stargate soundtrack in root directory")
                    do {
                        // Stop any existing music first
                        musicPlayer?.stop()
                        
                        musicPlayer = try AVAudioPlayer(contentsOf: url)
                        musicPlayer?.numberOfLoops = -1
                        musicPlayer?.volume = musicVolume
                        musicPlayer?.prepareToPlay()
                        musicPlayer?.play()
                        print("DEBUG: Successfully playing stargate soundtrack from root directory")
                        isMusicPlaying = true
                        return
                    } catch {
                        print("DEBUG: Error playing stargate soundtrack from root directory: \(error)")
                    }
                } else {
                    print("DEBUG: Stargate soundtrack not found anywhere, will use fallback music")
                }
            }
        }
        
        // If a specific map theme is provided, try to play that theme's music
        if let mapTheme = mapTheme {
            let themeTrack: MusicTrack
            let levelId = getLevelId()
            
            // Special case for Stargate Escape level - use Dune/Stargate inspired theme
            if levelId == "desert_escape" || levelId?.contains("stargate") == true || mapTheme == .desert {
                print("DEBUG: Using stargate theme track as fallback")
                themeTrack = .stargate
                
                // Try to load the stargate soundtrack directly first
                if let url = Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "wav") ??
                           Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "mp3") ??
                           Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "wav", subdirectory: "Audio/Music") ??
                           Bundle.main.url(forResource: "stargate_soundtrack", withExtension: "mp3", subdirectory: "Audio/Music") {
                    print("DEBUG: Found stargate soundtrack file: \(url.lastPathComponent)")
                    do {
                        musicPlayer?.stop()
                        musicPlayer = try AVAudioPlayer(contentsOf: url)
                        musicPlayer?.numberOfLoops = -1
                        musicPlayer?.volume = musicVolume
                        musicPlayer?.prepareToPlay()
                        musicPlayer?.play()
                        print("DEBUG: Playing stargate soundtrack directly")
                        isMusicPlaying = true
                        return
                    } catch {
                        print("DEBUG: Error playing stargate soundtrack: \(error)")
                    }
                }
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
            
            // Try to load from root directory first
            if let url = Bundle.main.url(forResource: soundtrackName, withExtension: "wav") {
                print("DEBUG: Found \(soundtrackName).wav in root bundle")
                do {
                    // Stop current music if playing
                    musicPlayer?.stop()
                    
                    // Load and play the new theme
                    musicPlayer = try AVAudioPlayer(contentsOf: url)
                    musicPlayer?.numberOfLoops = -1
                    musicPlayer?.volume = musicVolume
                    musicPlayer?.prepareToPlay()
                    musicPlayer?.play()
                    
                    print("DEBUG: Playing music theme from root bundle: \(soundtrackName)")
                    isMusicPlaying = true
                    return
                } catch {
                    print("DEBUG: Could not load theme music from root bundle for \(mapTheme): \(error)")
                    // Fall through to Audio/Music directory
                }
            }
            
            // Try to load from Audio/Music as fallback
            if let url = Bundle.main.url(forResource: soundtrackName, withExtension: "wav", subdirectory: "Audio/Music") {
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
    
    /// Helper method to check if we're in the Stargate Escape level
    private func checkIfStargateLevel() -> Bool {
        // Check all possible ways to identify the Stargate Escape level
        print("DEBUG: Checking if we're in a Stargate level...")
        
        // 1. First check if the current map theme is desert
        if MapManager.shared.currentMap == .desert {
            print("DEBUG: Current map theme is desert - likely Stargate level")
            return true
        }
        
        // 2. Check ResourcePath for stargate soundtrack file (both in Audio/Music and root)
        if let resourcePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            
            // Check for stargate soundtrack in Audio/Music
            let audioMusicPath = "\(resourcePath)/Audio/Music/stargate_soundtrack.wav"
            let rootPathWav = "\(resourcePath)/stargate_soundtrack.wav"
            let rootPathMp3 = "\(resourcePath)/stargate_soundtrack.mp3"
            
            if fileManager.fileExists(atPath: audioMusicPath) || 
               fileManager.fileExists(atPath: rootPathWav) || 
               fileManager.fileExists(atPath: rootPathMp3) {
                print("DEBUG: Found stargate_soundtrack file")
                
                // 3. Check UserDefaults for level ID
                let userDefaults = UserDefaults.standard
                let stargateKeys = ["desert_escape", "stargate_escape", "dune_escape", "stargate", "Stargate Escape"]
                
                // Check for direct level ID matches
                for key in ["currentLevel", "lastPlayedLevel", "selectedLevel"] {
                    if let value = userDefaults.string(forKey: key) {
                        print("DEBUG: Found \(key) = \(value)")
                        if stargateKeys.contains(value) || value.lowercased().contains("stargate") || 
                           value.lowercased().contains("desert") || value.lowercased().contains("dune") {
                            print("DEBUG: Stargate level detected via \(key)")
                            return true
                        }
                    }
                }
                
                // 4. Check for any UserDefaults key/value containing stargate-related terms
                for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
                    if key.lowercased().contains("stargate") || 
                       key.lowercased().contains("desert") ||
                       key.lowercased().contains("dune") {
                        print("DEBUG: Found stargate-related key in UserDefaults: \(key)")
                        return true
                    }
                    
                    if let stringValue = value as? String,
                       (stringValue.lowercased().contains("stargate") ||
                        stringValue.lowercased().contains("desert") ||
                        stringValue.lowercased().contains("dune")) {
                        print("DEBUG: Found stargate-related value in UserDefaults: \(key) = \(stringValue)")
                        return true
                    }
                }
            }
        }
        
        // 5. Direct check for desert map theme
        if MapManager.shared.currentMap == .desert {
            print("DEBUG: Detected desert map theme - likely Stargate level")
            return true
        }
        
        // 6. Check if the level is desert_escape in UserDefaults
        if let level = UserDefaults.standard.string(forKey: "currentLevel"), 
           level.contains("desert") || level.contains("stargate") || level.contains("dune") {
            print("DEBUG: Detected desert/stargate level from UserDefaults")
            return true
        }
        
        // 7. Check for notifications
        NotificationCenter.default.post(name: Notification.Name("RequestCurrentLevelInfo"), object: nil)
        print("DEBUG: Posted level info request notification")
        
        return false
    }
    
    /// Helper method to get the current level ID from the game scene
    private func getLevelId() -> String? {
        // This is a simple method to check if we're in the "Stargate Escape" level
        // In a real implementation, you would get this from the game state
        let userDefaults = UserDefaults.standard
        
        // Print all UserDefaults keys for debugging
        print("DEBUG: Current UserDefaults keys:")
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.contains("level") || key.contains("Level") {
                print("DEBUG: \(key) = \(value)")
            }
        }
        
        // Check for currentLevel key
        if let currentLevel = userDefaults.string(forKey: "currentLevel") {
            print("DEBUG: Found currentLevel in UserDefaults: \(currentLevel)")
            return currentLevel
        }
        
        // Check for lastPlayedLevel key
        if let lastPlayedLevel = userDefaults.string(forKey: "lastPlayedLevel") {
            print("DEBUG: Found lastPlayedLevel in UserDefaults: \(lastPlayedLevel)")
            return lastPlayedLevel
        }
        
        // Check if any level key contains "stargate"
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if let stringValue = value as? String, 
               (stringValue.lowercased().contains("stargate") || key.lowercased().contains("stargate")) {
                print("DEBUG: Found stargate reference in UserDefaults: \(key) = \(value)")
                return "stargate_escape"
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
        
        // For debugging power-up sound effects
        if effect == .starPower || effect == .multiplier || effect == .magnify || 
           effect == .ghost || effect == .forcefield || effect == .destroyObject {
            print("DEBUG: Attempting to play power-up sound effect: \(effect.rawValue)")
            
            // Try to load the sound effect directly if it wasn't loaded before
            if effectsPlayers[effect.rawValue] == nil {
                print("DEBUG: Effect not found in effectsPlayers, trying to load it now")
                loadSoundEffect(effect)
            }
        }
        
        if let player = effectsPlayers[effect.rawValue] {
            // Try to reuse the player URL to create a new player for overlapping sounds
            if let url = player.url {
                do {
                    print("DEBUG: Playing \(effect.rawValue) from URL: \(url)")
                    let newPlayer = try AVAudioPlayer(contentsOf: url)
                    newPlayer.volume = effectsVolume
                    newPlayer.prepareToPlay()
                    newPlayer.play()
                    
                    // For important sound effects, ensure they play to completion
                    if effect == .starPower || effect == .multiplier || effect == .magnify || 
                       effect == .ghost || effect == .forcefield || effect == .destroyObject || 
                       effect == .gameOver || effect == .crash {
                        // Add to a temporary dictionary to prevent deallocation
                        let uuid = UUID().uuidString
                        effectsPlayers[uuid] = newPlayer
                        
                        // Remove the temporary player after it finishes playing
                        DispatchQueue.main.asyncAfter(deadline: .now() + newPlayer.duration + 0.5) { [weak self] in
                            self?.effectsPlayers.removeValue(forKey: uuid)
                        }
                    }
                    
                    return
                } catch {
                    print("Error creating new player for effect \(effect.rawValue): \(error)")
                    // Fall through to original player as fallback
                }
            }
            
            // If we couldn't create a new player, use the original one
            print("DEBUG: Playing \(effect.rawValue) using original player")
            player.currentTime = 0
            player.volume = effectsVolume
            player.play()
        } else {
            // If we still don't have a player, try one more attempt to load the sound
            print("DEBUG: No player found for sound effect: \(effect.rawValue), attempting to load")
            
            // Check for Audio/SFX directory with file extension suffixes
            var url: URL? = nil
            if effect == .crash {
                url = Bundle.main.url(forResource: "crash_FX", withExtension: "mp3", subdirectory: "Audio/SFX")
            } else if effect == .duckCrash {
                url = Bundle.main.url(forResource: "quack_FX", withExtension: "mp3", subdirectory: "Audio/SFX") 
            } else if effect == .starPower {
                url = Bundle.main.url(forResource: "starpower_FX", withExtension: "mp3", subdirectory: "Audio/SFX")
            } else if effect == .multiplier {
                url = Bundle.main.url(forResource: "multiplier_FX", withExtension: "wav", subdirectory: "Audio/SFX")
            } else if effect == .magnify {
                url = Bundle.main.url(forResource: "magnify_FX", withExtension: "wav", subdirectory: "Audio/SFX")
            } else if effect == .ghost {
                url = Bundle.main.url(forResource: "ghost_FX", withExtension: "mp3", subdirectory: "Audio/SFX")
            } else if effect == .forcefield {
                url = Bundle.main.url(forResource: "forcefield_FX", withExtension: "wav", subdirectory: "Audio/SFX")
            } else if effect == .destroyObject {
                url = Bundle.main.url(forResource: "destroy_object_FX", withExtension: "wav", subdirectory: "Audio/SFX")
            } else if effect == .gameOver {
                url = Bundle.main.url(forResource: "Game_Over", withExtension: "mp3", subdirectory: "Audio/SFX")
            }
            
            if let url = url {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = effectsVolume
                    
                    // Store for future use
                    effectsPlayers[effect.rawValue] = player
                    
                    // Play immediately
                    player.play()
                    print("DEBUG: Successfully loaded and played \(effect.rawValue) from \(url.lastPathComponent)")
                    return
                } catch {
                    print("DEBUG: Error loading \(effect.rawValue) from explicit path: \(error)")
                }
            }
            
            // If all else fails, use fallback
            createFallbackSoundEffect(for: effect)
        }
    }
    
    func playThemeSpecificEffect(for mapTheme: MapManager.MapTheme, event: String) {
        // Play theme-appropriate sound effects for common events
        switch (mapTheme, event) {
        case (.underwater, "obstacle"):
            playEffect(.splash)
        case (.space, "obstacle"):
            playEffect(.crash)
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
    
    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("DEBUG: Audio route changed - Reason: \(reason)")
        
        switch reason {
        case .newDeviceAvailable:
            print("DEBUG: New audio device available")
        case .oldDeviceUnavailable:
            print("DEBUG: Audio device disconnected")
            // Ensure audio continues playing on the built-in speakers
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                print("DEBUG: Overriding to speaker output")
            } catch {
                print("DEBUG: Failed to override to speaker: \(error)")
            }
        case .categoryChange:
            print("DEBUG: Audio category changed")
        default:
            print("DEBUG: Other route change: \(reason)")
        }
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