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
        case halloween = "halloween_theme"
        case christmas = "christmas_theme"
    }
    
    enum SoundEffect: String {
        case jump = "jump"
        case crash = "crash"
        case collect = "collect"
        case menuTap = "menu_tap"
        case achievement = "achievement"
        case gameOver = "game_over"
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
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // In a real app, you'd load audio files from the bundle
        // For the simulator, we'll generate procedural audio or use placeholders
        createDummyAudioFiles()
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
    
    // MARK: - Creating Audio Files
    
    private func createDummyAudioFiles() {
        // In a simulator environment, we'll just print messages instead of playing sounds
        print("Audio Manager initialized - Note: Full audio requires a physical device")
        
        // In a real implementation, you would pre-load audio players here
        // Example for an 8-bit style soundtrack using AVAudioPlayer
        /*
        do {
            let url = Bundle.main.url(forResource: "retro_soundtrack", withExtension: "mp3")!
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1 // Loop indefinitely
            musicPlayer?.prepareToPlay()
        } catch {
            print("Could not load music: \(error)")
        }
        */
    }
    
    // This would generate procedural 8-bit style audio in a real app
    // For now, we'll return nil to avoid complex audio processing in the simulator
    private func generate8BitAudio(duration: TimeInterval, tempo: Double, melody: [Int]) -> URL? {
        // This would use AudioToolbox to generate audio programmatically
        // For the simulator, we'll return nil
        return nil
    }
    
    // MARK: - Music Control
    
    func playBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        if let player = musicPlayer {
            player.volume = musicVolume
            player.play()
        } else {
            print("Playing background music (simulator)")
        }
        
        isMusicPlaying = true
    }
    
    func stopBackgroundMusic() {
        musicPlayer?.stop()
        isMusicPlaying = false
        print("Stopped background music")
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
        } else {
            print("Speed boost music activated (faster tempo)")
        }
        
        isSpeedBoostActive = true
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
        } else {
            print("Speed boost music deactivated (normal tempo)")
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
            player.volume = effectsVolume
            player.play()
        } else {
            print("Playing sound effect: \(effect.rawValue)")
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
    
    // MARK: - 8-Bit Music Generation
    
    // This would create an 8-bit style music track programmatically
    // It's a placeholder that would be implemented with AudioToolbox in a real app
    func create8BitMusic(isSpeedBoost: Bool = false) -> AVAudioPlayer? {
        // In a real implementation, this would generate a procedural 8-bit soundtrack
        // For the simulator version, we'll return nil to avoid complex audio processing
        print("Would create 8-bit \(isSpeedBoost ? "speed boost" : "normal") music here")
        return nil
    }
}