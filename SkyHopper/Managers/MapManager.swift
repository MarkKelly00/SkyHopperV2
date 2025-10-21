import SpriteKit
import Foundation

class MapManager {
    static let shared = MapManager()
    
    enum MapTheme: String, CaseIterable {
        case city
        case forest
        case mountain
        case space
        case underwater
        case desert // New desert theme for Stargate Escape
        
        // Seasonal themes
        case halloween
        case christmas
        case summer
        
        var displayName: String {
            switch self {
            case .city: return "City Skyline"
            case .forest: return "Forest Valley"
            case .mountain: return "Mountain Pass"
            case .space: return "Cosmic Voyage"
            case .underwater: return "Ocean Depths"
            case .desert: return "Stargate Desert"
            case .halloween: return "Spooky Halloween"
            case .christmas: return "Winter Wonderland"
            case .summer: return "Summer Beach"
            }
        }
        
        var difficulty: Int {
            switch self {
            case .city: return 1
            case .forest: return 2
            case .desert: return 2 // Level 2 difficulty as requested
            case .mountain: return 3
            case .space: return 5
            case .underwater: return 4
            // Seasonal maps maintain moderate difficulty
            case .halloween, .christmas, .summer: return 3
            }
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .city: return UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0) // Blue sky
            case .forest: return UIColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1.0) // Green tint
            case .mountain: return UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0) // Light blue with clouds
            case .space: return UIColor(red: 0.0, green: 0.0, blue: 0.1, alpha: 1.0) // Near black
            case .underwater: return UIColor(red: 0.0, green: 0.3, blue: 0.6, alpha: 1.0) // Deep blue
            case .desert: return UIColor(red: 0.96, green: 0.83, blue: 0.6, alpha: 1.0) // Desert sky (warm sand color)
            case .halloween: return UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0) // Dark night
            case .christmas: return UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0) // Snow white
            case .summer: return UIColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0) // Sunny yellow
            }
        }
        
        var obstacleColor: UIColor {
            switch self {
            case .city: return UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0) // Gray buildings
            case .forest: return UIColor(red: 0.3, green: 0.2, blue: 0.0, alpha: 1.0) // Brown trees
            case .mountain: return UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // Gray mountains
            case .space: return UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0) // Dark asteroids
            case .underwater: return UIColor(red: 0.0, green: 0.4, blue: 0.3, alpha: 1.0) // Seaweed green
            case .desert: return UIColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1.0) // Sandy pyramids
            case .halloween: return UIColor(red: 0.5, green: 0.1, blue: 0.0, alpha: 1.0) // Blood red
            case .christmas: return UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0) // Christmas red
            case .summer: return UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0) // Orange
            }
        }
        
        var groundColor: UIColor {
            switch self {
            case .city: return UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0) // Gray concrete
            case .forest: return UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0) // Green grass
            case .mountain: return UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0) // Brown earth
            case .space: return UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0) // Gray platform
            case .underwater: return UIColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1.0) // Sandy bottom
            case .desert: return UIColor(red: 0.95, green: 0.85, blue: 0.6, alpha: 1.0) // Desert sand
            case .halloween: return UIColor(red: 0.3, green: 0.2, blue: 0.0, alpha: 1.0) // Dark soil
            case .christmas: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // Snow
            case .summer: return UIColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0) // Sand
            }
        }
        
        var unlockScore: Int {
            switch self {
            case .city: return 0 // Starter map
            case .desert: return 500 // Easier to unlock than forest
            case .forest: return 1000
            case .mountain: return 2500
            case .underwater: return 5000
            case .space: return 10000
            // Seasonal maps have special unlock conditions (date-based)
            case .halloween, .christmas, .summer: return 0
            }
        }
        
        var obstacleFrequency: TimeInterval {
            switch self {
            case .city: return 3.0
            case .desert: return 2.9 // Slightly more obstacles than city, but less than forest
            case .forest: return 2.8
            case .mountain: return 2.5
            case .space: return 2.0
            case .underwater: return 2.2
            // Seasonal maps - standard frequency
            case .halloween, .christmas, .summer: return 2.5
            }
        }
        
        var obstacleSpeed: CGFloat {
            switch self {
            case .city: return 120.0
            case .desert: return 125.0 // Slightly faster than city
            case .forest: return 130.0
            case .mountain: return 140.0
            case .space: return 160.0
            case .underwater: return 100.0 // Slower underwater
            // Seasonal maps
            case .halloween: return 135.0
            case .christmas: return 125.0
            case .summer: return 145.0
            }
        }
        
        var isSeasonalMap: Bool {
            switch self {
            case .halloween, .christmas, .summer: return true
            default: return false
            }
        }
        
        var specialEffects: [String] {
            switch self {
            case .city: return []
            case .desert: return ["dust", "portals"]
            case .forest: return ["leaves", "birds"]
            case .mountain: return ["snow", "fog"]
            case .space: return ["stars", "asteroids"]
            case .underwater: return ["bubbles", "fish"]
            case .halloween: return ["ghosts", "bats"]
            case .christmas: return ["snow", "gifts"]
            case .summer: return ["seagulls", "waves"]
            }
        }
    }
    
    var unlockedMaps: [MapTheme] = [.city] // Start with city map
    var currentMap: MapTheme = .city
    
    private init() {
        // Initialize with saved data
        loadSavedData()
        checkForSeasonalMaps()
        checkMapUnlocksBasedOnScore()
    }
    
    func unlockMap(theme: MapTheme) -> Bool {
        guard !unlockedMaps.contains(theme) else { return false } // Already unlocked
        
        unlockedMaps.append(theme)
        saveUnlockedMaps()
        return true
    }
    
    func selectMap(theme: MapTheme) -> Bool {
        guard unlockedMaps.contains(theme) else { return false }
        
        currentMap = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "currentMap")
        return true
    }
    
    func isMapUnlocked(theme: MapTheme) -> Bool {
        return unlockedMaps.contains(theme)
    }
    
    func getMapUnlockRequirement(theme: MapTheme) -> String {
        if theme.isSeasonalMap {
            switch theme {
            case .halloween:
                return "Available during October"
            case .christmas:
                return "Available during December"
            case .summer:
                return "Available during June-August"
            default:
                return ""
            }
        } else {
            return "Score \(theme.unlockScore) points to unlock"
        }
    }
    
    func checkForSeasonalMaps() {
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        
        // Halloween - October
        if month == 10 && !unlockedMaps.contains(.halloween) {
            _ = unlockMap(theme: .halloween)
        }
        
        // Christmas - December
        if month == 12 && !unlockedMaps.contains(.christmas) {
            _ = unlockMap(theme: .christmas)
        }
        
        // Summer - June, July, August
        if (month >= 6 && month <= 8) && !unlockedMaps.contains(.summer) {
            _ = unlockMap(theme: .summer)
        }
    }
    
    /// Check and unlock maps based on player's high score
    func checkMapUnlocksBasedOnScore() {
        // FOR TESTING: Unlock all maps
        for mapTheme in MapTheme.allCases {
            if !unlockedMaps.contains(mapTheme) {
                _ = unlockMap(theme: mapTheme)
                print("🗺️ Map '\(mapTheme.displayName)' unlocked for testing!")
            }
        }
        
        /* ORIGINAL PROGRESSION LOGIC (commented out for testing):
        let playerHighScore = PlayerData.shared.highScore
        
        // Check each map theme to see if it should be unlocked
        for mapTheme in MapTheme.allCases {
            // Skip if already unlocked
            if unlockedMaps.contains(mapTheme) { continue }
            
            // Skip seasonal maps (they have different unlock logic)
            if mapTheme.isSeasonalMap { continue }
            
            // Check if player's score meets the unlock requirement
            if playerHighScore >= mapTheme.unlockScore {
                _ = unlockMap(theme: mapTheme)
                print("🗺️ Map '\(mapTheme.displayName)' unlocked! (Required: \(mapTheme.unlockScore), Player: \(playerHighScore))")
            }
        }
        */
    }
    
    // Persistence
    func loadSavedData() {
        if let savedRaw = UserDefaults.standard.stringArray(forKey: "unlockedMaps") {
            unlockedMaps = savedRaw.compactMap { MapTheme(rawValue: $0) }
        }
        
        if let savedMapRaw = UserDefaults.standard.string(forKey: "currentMap"),
           let savedMap = MapTheme(rawValue: savedMapRaw) {
            currentMap = savedMap
        }
        
        // Ensure at least the city map is unlocked (fallback)
        if !unlockedMaps.contains(.city) {
            unlockedMaps.append(.city)
        }
    }
    
    func saveUnlockedMaps() {
        let rawValues = unlockedMaps.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: "unlockedMaps")
    }
    
    // Apply map theme to game scene
    func applyTheme(to scene: SKScene) {
        // Clear old background/effects
        scene.enumerateChildNodes(withName: "bg_*") { node, _ in node.removeFromParent() }
        scene.enumerateChildNodes(withName: "effect_*") { node, _ in node.removeFromParent() }
        // Stop any background spawning actions to avoid duplicates across transitions
        scene.removeAction(forKey: "spawnLeaves")
        scene.removeAction(forKey: "spawnSnow")
        scene.removeAction(forKey: "spawnBubbles")
        scene.removeAction(forKey: "spawnDust")

        // Set base background color
        scene.backgroundColor = currentMap.backgroundColor

        // Update ground color
        scene.enumerateChildNodes(withName: "ground") { node, _ in
            if let shapeNode = node as? SKShapeNode {
                shapeNode.fillColor = self.currentMap.groundColor
                shapeNode.strokeColor = self.currentMap.groundColor.darker()
            }
        }

        // Build theme-specific background layers
        switch currentMap {
        case .city: buildCityBackground(in: scene)
        case .forest: buildForestBackground(in: scene)
        case .mountain: buildMountainBackground(in: scene)
        case .desert: buildDesertBackground(in: scene)
        case .underwater: buildUnderwaterBackground(in: scene)
        case .space: buildSpaceBackground(in: scene)
        case .halloween: buildHalloweenBackground(in: scene)
        case .christmas: buildMountainBackground(in: scene)
        case .summer: buildCityBackground(in: scene)
        }

        // Apply special particle/effects for the theme
        addSpecialEffects(to: scene)
    }

    // MARK: - Background builders

    private func buildCityBackground(in scene: SKScene) {
        // Soft blurred clouds parallax
        addSoftClouds(to: scene, layer: -5, density: 6, speed: 20)
        addSoftClouds(to: scene, layer: -6, density: 4, speed: 28)
    }

    private func buildForestBackground(in scene: SKScene) {
        // Tree line silhouettes + soft clouds
        addParallaxHills(to: scene, color: UIColor(red:0.2, green:0.4, blue:0.2, alpha:1), y: 120, z: -6)
        addParallaxHills(to: scene, color: UIColor(red:0.15, green:0.3, blue:0.15, alpha:1), y: 90, z: -7)
        addSoftClouds(to: scene, layer: -5, density: 5, speed: 24)
    }

    private func buildMountainBackground(in scene: SKScene) {
        // Mountain silhouettes + snow
        addParallaxHills(to: scene, color: UIColor(red:0.5, green:0.55, blue:0.6, alpha:1), y: 140, z: -6)
        addParallaxHills(to: scene, color: UIColor(red:0.4, green:0.45, blue:0.5, alpha:1), y: 110, z: -7)
        addSoftClouds(to: scene, layer: -5, density: 4, speed: 22)
    }

    private func buildDesertBackground(in scene: SKScene) {
        // Distant dunes and heat haze are approximated via dust + warm gradient already
        addParallaxHills(to: scene, color: UIColor(red:0.85, green:0.72, blue:0.45, alpha:1), y: 90, z: -6)
    }

    private func buildUnderwaterBackground(in scene: SKScene) {
        // Water gradient shader + rising bubbles
        let water = SKSpriteNode(color: .clear, size: scene.size)
        water.anchorPoint = .zero
        water.position = .zero
        water.zPosition = -50
        water.name = "bg_water"
        water.shader = SKShader(source: """
        void main() {
          vec2 uv = v_tex_coord;
          float t = u_time * 0.25;
          float wave = sin((uv.y + t) * 22.0) * 0.02 + cos((uv.x - t) * 17.0) * 0.02;
          vec3 top = vec3(0.0, 0.5, 0.8);
          vec3 bottom = vec3(0.0, 0.2, 0.45);
          vec3 col = mix(bottom, top, uv.y) + wave;
          gl_FragColor = vec4(col, 1.0);
        }
        """)
        scene.addChild(water)
        // Add only the underwater bubbles effect (no clouds)
        addBubblesEffect(to: scene)
    }

    private func buildSpaceBackground(in scene: SKScene) {
        // Gradient to near-black
        let grad = SKSpriteNode(color: .clear, size: scene.size)
        grad.anchorPoint = .zero
        grad.position = .zero
        grad.zPosition = -50
        grad.name = "bg_space"
        grad.shader = SKShader(source: """
        void main() {
          vec2 uv = v_tex_coord;
          vec3 top = vec3(0.02, 0.02, 0.08);
          vec3 bottom = vec3(0.0, 0.0, 0.0);
          gl_FragColor = vec4(mix(bottom, top, uv.y), 1.0);
        }
        """)
        scene.addChild(grad)
        addStarsEffect(to: scene)
        // Nebula blobs (reduced for performance)
        for _ in 0..<2 {
            let nebula = SKShapeNode(circleOfRadius: CGFloat.random(in: 60...120))
            nebula.fillColor = [
                UIColor(red:0.5, green:0.2, blue:0.7, alpha:0.25),
                UIColor(red:0.2, green:0.7, blue:0.7, alpha:0.25)
            ].randomElement()!
            nebula.strokeColor = .clear
            nebula.position = CGPoint(x: CGFloat.random(in: 0...scene.size.width), y: CGFloat.random(in: scene.size.height*0.4...scene.size.height*0.9))
            nebula.zPosition = -49
            nebula.name = "bg_nebula"
            let glow = SKEffectNode()
            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 8])
            glow.addChild(nebula.copy() as! SKNode)
            glow.position = nebula.position
            glow.zPosition = -49
            scene.addChild(glow)
        }
    }
    
    private func buildHalloweenBackground(in scene: SKScene) {
        // Add dark clouds for atmosphere
        addSoftClouds(to: scene, layer: -5, density: 4, speed: 15, 
                     color: UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 0.6))
        
        // Add a full moon
        let moonContainer = SKNode()
        moonContainer.zPosition = -8
        scene.addChild(moonContainer)
        
        // Create moon
        let moon = SKShapeNode(circleOfRadius: 80)
        moon.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: scene.frame.width * 0.75, y: scene.frame.height * 0.7)
        
        // Add moon glow
        let moonGlow = SKShapeNode(circleOfRadius: 100)
        moonGlow.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 0.3)
        moonGlow.strokeColor = .clear
        moonGlow.position = moon.position
        moonGlow.setScale(1.2)
        
        // Add moon craters for detail
        for _ in 0..<5 {
            let crater = SKShapeNode(circleOfRadius: CGFloat.random(in: 8...20))
            crater.fillColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 0.5)
            crater.strokeColor = .clear
            crater.position = CGPoint(
                x: CGFloat.random(in: -40...40),
                y: CGFloat.random(in: -40...40)
            )
            moon.addChild(crater)
        }
        
        moonContainer.addChild(moonGlow)
        moonContainer.addChild(moon)
        
        // Add flying bats
        for _ in 0..<6 {
            let bat = createBat()
            bat.position = CGPoint(
                x: CGFloat.random(in: 0...scene.frame.width),
                y: CGFloat.random(in: scene.frame.height * 0.5...scene.frame.height * 0.9)
            )
            bat.zPosition = -7
            scene.addChild(bat)
            
            // Animate bat flight
            let flyPath = CGFloat.random(in: 100...200)
            let flyDuration = Double.random(in: 8...12)
            let moveRight = SKAction.moveBy(x: flyPath, y: CGFloat.random(in: -30...30), duration: flyDuration/2)
            let moveLeft = SKAction.moveBy(x: -flyPath, y: CGFloat.random(in: -30...30), duration: flyDuration/2)
            bat.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
        }
        
        // Add spooky fog at the bottom
        let fog = SKShapeNode(rectOf: CGSize(width: scene.frame.width * 2, height: 150))
        fog.fillColor = UIColor(red: 0.5, green: 0.4, blue: 0.6, alpha: 0.3)
        fog.strokeColor = .clear
        fog.position = CGPoint(x: scene.frame.width / 2, y: 75)
        fog.zPosition = -6
        scene.addChild(fog)
        
        // Animate fog
        let fogMove = SKAction.moveBy(x: 50, y: 0, duration: 20)
        let fogReset = SKAction.moveBy(x: -50, y: 0, duration: 0)
        fog.run(SKAction.repeatForever(SKAction.sequence([fogMove, fogReset])))
    }
    
    private func createBat() -> SKNode {
        let bat = SKNode()
        
        // Create simple bat shape
        let body = SKShapeNode(ellipseOf: CGSize(width: 8, height: 12))
        body.fillColor = .black
        body.strokeColor = .clear
        bat.addChild(body)
        
        // Left wing
        let leftWingPath = UIBezierPath()
        leftWingPath.move(to: CGPoint(x: -4, y: 0))
        leftWingPath.addCurve(to: CGPoint(x: -15, y: -3),
                             controlPoint1: CGPoint(x: -8, y: 2),
                             controlPoint2: CGPoint(x: -12, y: 0))
        leftWingPath.addCurve(to: CGPoint(x: -12, y: -8),
                             controlPoint1: CGPoint(x: -15, y: -5),
                             controlPoint2: CGPoint(x: -14, y: -7))
        leftWingPath.addCurve(to: CGPoint(x: -4, y: -5),
                             controlPoint1: CGPoint(x: -10, y: -8),
                             controlPoint2: CGPoint(x: -6, y: -6))
        
        let leftWing = SKShapeNode(path: leftWingPath.cgPath)
        leftWing.fillColor = .black
        leftWing.strokeColor = .clear
        bat.addChild(leftWing)
        
        // Right wing (mirror)
        let rightWing = SKShapeNode(path: leftWingPath.cgPath)
        rightWing.fillColor = .black
        rightWing.strokeColor = .clear
        rightWing.xScale = -1
        bat.addChild(rightWing)
        
        // Animate wing flapping
        let flapUp = SKAction.scaleY(to: 0.7, duration: 0.2)
        let flapDown = SKAction.scaleY(to: 1.0, duration: 0.2)
        bat.run(SKAction.repeatForever(SKAction.sequence([flapUp, flapDown])))
        
        return bat
    }

    // Helpers
    private func addParallaxHills(to scene: SKScene, color: UIColor, y: CGFloat, z: CGFloat) {
        let hill = SKShapeNode()
        let path = UIBezierPath()
        let width = scene.size.width
        path.move(to: CGPoint(x: 0, y: y))
        for i in 0...6 {
            let step = width / 6
            let x = CGFloat(i) * step
            let h = CGFloat.random(in: -20...20)
            path.addLine(to: CGPoint(x: x, y: y + h))
        }
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()
        hill.path = path.cgPath
        hill.fillColor = color
        hill.strokeColor = color.darker()
        hill.alpha = 0.8
        hill.zPosition = z
        hill.name = "bg_hill"
        scene.addChild(hill)
    }

    private func addSoftClouds(to scene: SKScene, layer: CGFloat, density: Int, speed: CGFloat, color: UIColor? = nil) {
        for _ in 0..<density {
            let cloud = createSoftCloudNode(color: color)
            cloud.position = CGPoint(x: CGFloat.random(in: 0...scene.size.width), y: CGFloat.random(in: scene.size.height*0.6...scene.size.height))
            cloud.zPosition = layer
            cloud.name = "bg_cloud"
            scene.addChild(cloud)
            // drift
            let move = SKAction.moveBy(x: -scene.size.width - 200, y: CGFloat.random(in: -20...20), duration: TimeInterval(CGFloat.random(in: 20...30)))
            let reset = SKAction.moveTo(x: scene.size.width + 100, duration: 0)
            let seq = SKAction.sequence([move, reset])
            cloud.run(SKAction.repeatForever(seq))
        }
    }

    private func createSoftCloudNode(color: UIColor? = nil) -> SKNode {
        let container = SKEffectNode()
        container.shouldRasterize = true
        container.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 6])
        for _ in 0..<Int.random(in: 4...7) {
            let r = CGFloat.random(in: 12...28)
            let puff = SKShapeNode(circleOfRadius: r)
            if let color = color {
                puff.fillColor = color
            } else {
                puff.fillColor = UIColor(white: CGFloat.random(in: 0.92...1.0), alpha: 1)
            }
            puff.strokeColor = .clear
            puff.position = CGPoint(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -8...8))
            container.addChild(puff)
        }
        return container
    }
    
    private func addSpecialEffects(to scene: SKScene) {
        // Clear any existing effects first
        scene.enumerateChildNodes(withName: "effect_*") { node, _ in
            node.removeFromParent()
        }
        
        // Add new effects based on the map theme
        for effect in currentMap.specialEffects {
            switch effect {
            case "leaves":
                addLeavesEffect(to: scene)
            case "stars":
                addStarsEffect(to: scene)
            case "snow":
                addSnowEffect(to: scene)
            case "bubbles":
                addBubblesEffect(to: scene)
            case "dust":
                addDustEffect(to: scene)
            case "portals":
                addPortalEffect(to: scene)
            default:
                break
            }
        }
    }
    
    // Effect implementations
    private func addLeavesEffect(to scene: SKScene) {
        // Simple placeholder implementation
        for _ in 0..<10 {
            let leaf = SKShapeNode(rectOf: CGSize(width: 5, height: 5), cornerRadius: 1)
            leaf.fillColor = UIColor(red: 0.5, green: 0.3, blue: 0.0, alpha: 0.8)
            leaf.strokeColor = UIColor.clear
            leaf.name = "effect_leaf"
            
            let randomX = CGFloat.random(in: 0...scene.size.width)
            let startY = scene.size.height + 10
            leaf.position = CGPoint(x: randomX, y: startY)
            
            // Create falling animation
            let fallDuration = TimeInterval.random(in: 5...10)
            let swayX = CGFloat.random(in: -100...100)
            let fallAction = SKAction.moveBy(x: swayX, y: -scene.size.height - 20, duration: fallDuration)
            let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: fallDuration)
            let group = SKAction.group([fallAction, rotateAction])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            
            leaf.run(sequence)
            scene.addChild(leaf)
        }
        
        // Create repeating action to spawn more leaves
        let wait = SKAction.wait(forDuration: 2.0)
        let spawn = SKAction.run { [weak self] in
            self?.addLeavesEffect(to: scene)
        }
        let sequence = SKAction.sequence([wait, spawn])
        scene.run(SKAction.repeatForever(sequence), withKey: "spawnLeaves")
    }
    
    private func addStarsEffect(to scene: SKScene) {
        // Add starfield
        for _ in 0..<100 {
            let starSize = CGFloat.random(in: 1...3)
            let star = SKShapeNode(circleOfRadius: starSize)
            star.fillColor = UIColor.white
            star.strokeColor = UIColor.clear
            star.name = "effect_star"
            star.alpha = CGFloat.random(in: 0.5...1.0)
            
            let randomX = CGFloat.random(in: 0...scene.size.width)
            let randomY = CGFloat.random(in: 0...scene.size.height)
            star.position = CGPoint(x: randomX, y: randomY)
            
            // Twinkling effect
            let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: TimeInterval.random(in: 0.5...2.0))
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: TimeInterval.random(in: 0.5...2.0))
            let twinkle = SKAction.sequence([fadeOut, fadeIn])
            star.run(SKAction.repeatForever(twinkle))
            
            scene.addChild(star)
        }
    }
    
    private func addSnowEffect(to scene: SKScene) {
        for _ in 0..<30 {
            let snowflake = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            snowflake.fillColor = UIColor.white
            snowflake.strokeColor = UIColor.clear
            snowflake.name = "effect_snow"
            
            let randomX = CGFloat.random(in: 0...scene.size.width)
            let startY = scene.size.height + 10
            snowflake.position = CGPoint(x: randomX, y: startY)
            
            // Create falling animation
            let fallDuration = TimeInterval.random(in: 5...10)
            let swayX = CGFloat.random(in: -50...50)
            let fallAction = SKAction.moveBy(x: swayX, y: -scene.size.height - 20, duration: fallDuration)
            let sequence = SKAction.sequence([fallAction, SKAction.removeFromParent()])
            
            snowflake.run(sequence)
            scene.addChild(snowflake)
        }
        
        // Create repeating action to spawn more snow
        let wait = SKAction.wait(forDuration: 0.5)
        let spawn = SKAction.run { [weak self] in
            self?.addSnowEffect(to: scene)
        }
        let sequence = SKAction.sequence([wait, spawn])
        scene.run(SKAction.repeatForever(sequence), withKey: "spawnSnow")
    }
    
    private func addBubblesEffect(to scene: SKScene) {
        for _ in 0..<5 {
            let bubbleSize = CGFloat.random(in: 5...15)
            let bubble = SKShapeNode(circleOfRadius: bubbleSize)
            bubble.fillColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.3)
            bubble.strokeColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.5)
            // Safe initialization for bubble
            bubble.name = "effect_bubble"
            
            let randomX = CGFloat.random(in: 0...scene.size.width)
            let startY: CGFloat = 0.0
            bubble.position = CGPoint(x: randomX, y: startY)
            
            // Create rising animation
            let riseDuration = TimeInterval.random(in: 5...8)
            let swayX = CGFloat.random(in: -30...30)
            let riseAction = SKAction.moveBy(x: swayX, y: scene.size.height + 20, duration: riseDuration)
            let sequence = SKAction.sequence([riseAction, SKAction.removeFromParent()])
            
            bubble.run(sequence)
            scene.addChild(bubble)
        }
        
        // Create repeating action to spawn more bubbles
        let wait = SKAction.wait(forDuration: 1.0)
        let spawn = SKAction.run { [weak self] in
            self?.addBubblesEffect(to: scene)
        }
        let sequence = SKAction.sequence([wait, spawn])
        scene.run(SKAction.repeatForever(sequence), withKey: "spawnBubbles")
    }
    
    private func addDustEffect(to scene: SKScene) {
        for _ in 0..<15 {
            let dustSize = CGFloat.random(in: 1...5)
            let dust = SKShapeNode(circleOfRadius: dustSize)
            dust.fillColor = UIColor(red: 0.9, green: 0.85, blue: 0.6, alpha: 0.7) // Sandy color
            dust.strokeColor = UIColor.clear
            dust.name = "effect_dust"
            
            // Random position, but favor lower part of screen
            let randomX = CGFloat.random(in: 0...scene.size.width)
            let randomY = CGFloat.random(in: 0...(scene.size.height / 2))
            dust.position = CGPoint(x: randomX, y: randomY)
            
            // Create swirling animation
            let duration = TimeInterval.random(in: 2...5)
            let moveX = CGFloat.random(in: -80...80)
            let moveY = CGFloat.random(in: -20...40)
            let moveAction = SKAction.moveBy(x: moveX, y: moveY, duration: duration)
            
            // Fade and rotate
            let fade = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: duration/2),
                SKAction.fadeAlpha(to: 0.7, duration: duration/2)
            ])
            let rotate = SKAction.rotate(byAngle: .pi * CGFloat.random(in: -1...1), duration: duration)
            
            let group = SKAction.group([moveAction, fade, rotate])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            
            dust.run(sequence)
            scene.addChild(dust)
        }
        
        // Create repeating action to spawn more dust
        let wait = SKAction.wait(forDuration: 1.0)
        let spawn = SKAction.run { [weak self] in
            self?.addDustEffect(to: scene)
        }
        let sequence = SKAction.sequence([wait, spawn])
        scene.run(SKAction.repeatForever(sequence), withKey: "spawnDust")
    }
    
    private func addPortalEffect(to scene: SKScene) {
        // Add 1-2 background portals that are just for visual effect
        // These are separate from the actual gameplay portals in the desert level
        let portalCount = Int.random(in: 1...2)
        
        for _ in 0..<portalCount {
            // Create portal in the background
            let portalSize = CGFloat.random(in: 20...40)
            let portal = SKShapeNode(circleOfRadius: portalSize)
            portal.fillColor = UIColor(red: 0.0, green: 0.3, blue: 0.6, alpha: 0.3) // Blue portal color
            portal.strokeColor = UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.5)
            portal.lineWidth = 3
            portal.name = "effect_portal"
            
            // Position in the distance (usually near the top of the screen)
            let randomX = CGFloat.random(in: 0...scene.size.width)
            let randomY = CGFloat.random(in: scene.size.height * 0.6...scene.size.height * 0.9)
            portal.position = CGPoint(x: randomX, y: randomY)
            portal.zPosition = -2 // Behind most elements
            
            // Inner ring
            let innerRing = SKShapeNode(circleOfRadius: portalSize * 0.7)
            innerRing.fillColor = UIColor.clear
            innerRing.strokeColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.4)
            innerRing.lineWidth = 2
            portal.addChild(innerRing)
            
            // Animation for portal
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 1.5),
                SKAction.scale(to: 0.9, duration: 1.5)
            ])
            portal.run(SKAction.repeatForever(pulse))
            
            // Rotation for inner ring
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 5.0)
            innerRing.run(SKAction.repeatForever(rotate))
            
            scene.addChild(portal)
            
            // Add a subtle glow effect
            let glow = SKEffectNode()
            glow.position = CGPoint.zero
            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
            portal.addChild(glow)
        }
        
        // These portals stay visible for the entire scene, no need for respawn
    }
}

// Helper extension for UIColor
extension UIColor {
    func darker(by percentage: CGFloat = 0.2) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return UIColor(
            red: max(red - percentage, 0),
            green: max(green - percentage, 0),
            blue: max(blue - percentage, 0),
            alpha: alpha
        )
    }
    
    func lighter(by percentage: CGFloat = 0.2) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return UIColor(
            red: min(red + percentage, 1),
            green: min(green + percentage, 1),
            blue: min(blue + percentage, 1),
            alpha: alpha
        )
    }
}