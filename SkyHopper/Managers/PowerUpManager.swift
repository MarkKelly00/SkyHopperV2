import SpriteKit

class PowerUpManager {
    static let shared = PowerUpManager()
    
    enum PowerUpType: String, CaseIterable {
        case speedBoost
        case shield    // Standard shield - 3 seconds
        case shopShield // Premium shield - 3 hits
        case extraLife
        case shrink
        case ghost
        case multiplier
        case doubleTime // Doubles time for timed power-ups
        case missile
        case sidewinderMissile
        
        var symbol: String {
            switch self {
            case .speedBoost: return "⚡️"
            case .shield: return "🛡️"
            case .shopShield: return "🛡️"
            case .extraLife: return "❤️"
            case .shrink: return "🔍"
            case .ghost: return "👻"
            case .multiplier: return "✖️"
            case .doubleTime: return "⏱️"
            case .missile: return "🚀"
            case .sidewinderMissile: return "🎯"
            }
        }
        
        var color: UIColor {
            switch self {
            case .speedBoost: return UIColor.yellow
            case .shield: return UIColor.cyan
            case .shopShield: return UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) // Brighter cyan
            case .extraLife: return UIColor.red
            case .shrink: return UIColor.green
            case .ghost: return UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.7)
            case .multiplier: return UIColor.orange
            case .doubleTime: return UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0) // Teal
            case .missile: return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
            case .sidewinderMissile: return UIColor(red: 0.9, green: 0.4, blue: 0.0, alpha: 1.0)
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .speedBoost: return 5.0 // Increased from 3.0
            case .shield: return 5.0 // Increased from 3.0
            case .shopShield: return -1 // Special handling - uses hit count
            case .extraLife: return -1 // Permanent until used
            case .shrink: return 5.0 // Increased from 3.0
            case .ghost: return 5.0 // Increased from 3.0
            case .multiplier: return 5.0 // Increased from 3.0
            case .doubleTime: return -1 // Modifies other power-ups
            case .missile: return -1 // Uses count system
            case .sidewinderMissile: return -1 // Uses count system
            }
        }
        
        var message: String {
            switch self {
            case .speedBoost: return "Speed Boost!"
            case .shield: return "Force Field!"
            case .shopShield: return "Force Field (3 Hits)!"
            case .extraLife: return "Extra Life!"
            case .shrink: return "Shrink Obstacles!"
            case .ghost: return "Ghost Mode!"
            case .multiplier: return "2x Score!"
            case .doubleTime: return "Double Time!"
            case .missile: return "Missiles Ready!"
            case .sidewinderMissile: return "Sidewinders Ready!"
            }
        }
        
        var rarity: Int {
            switch self {
            case .speedBoost: return 20
            case .shield: return 15
            case .shopShield: return 0 // Shop only
            case .extraLife: return 5 // Very rare
            case .shrink: return 15
            case .ghost: return 15
            case .multiplier: return 15
            case .doubleTime: return 0 // Shop only
            case .missile: return 0 // Shop only
            case .sidewinderMissile: return 0 // Shop only
            }
        }
    }
    
    // Weights for power-up spawning probability
    private var availablePowerUps: [PowerUpType] = [
        .speedBoost, .shield, .extraLife, .shrink, .ghost, .multiplier
    ]
    
    // Track active power-ups
    private var activePowerUps: [PowerUpType: Timer] = [:]
    
    // Current power-up state
    var isSpeedBoostActive = false
    var isShieldActive = false
    var hasExtraLife = false
    var isShrinkActive = false
    var isGhostActive = false
    var isMultiplierActive = false
    var isDoubleTimeActive = false
    var scoreMultiplier: Int = 1
    
    // Missile counts
    var missileCount: Int = 0
    var sidewinderCount: Int = 0
    
    // Shop shield hit count
    var shopShieldHitCount = 0
    
    // Shield hits count
    var shieldHitCount = 0
    
    private init() {
        // Load saved power-up status
        hasExtraLife = UserDefaults.standard.bool(forKey: "hasExtraLife")
        missileCount = UserDefaults.standard.integer(forKey: "missileCount")
        sidewinderCount = UserDefaults.standard.integer(forKey: "sidewinderCount")
    }
    
    // Creates a power-up sprite
    func createPowerUpSprite(ofType type: PowerUpType, at position: CGPoint) -> SKNode {
        let powerUpNode = SKNode()
        powerUpNode.position = position
        powerUpNode.name = "powerup"
        
        // Create the shape node background
        let circle = SKShapeNode(circleOfRadius: 15)
        circle.fillColor = type.color
        circle.strokeColor = UIColor.white
        circle.lineWidth = 2
        circle.name = "powerupCircle"
        
        // Add type as user data
        powerUpNode.userData = NSMutableDictionary()
        powerUpNode.userData?.setValue(type.rawValue, forKey: "type")
        
        // Create the symbol label
        let symbol = SKLabelNode(text: type.symbol)
        symbol.fontName = "ArialRoundedMTBold"
        symbol.fontSize = 20
        symbol.verticalAlignmentMode = .center
        symbol.horizontalAlignmentMode = .center
        symbol.name = "powerupSymbol"
        
        // Add glow effect
        let glow = SKShapeNode(circleOfRadius: 20)
        glow.fillColor = UIColor.clear
        glow.strokeColor = type.color
        glow.alpha = 0.5
        glow.name = "powerupGlow"
        
        // Animate glow
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let pulsate = SKAction.repeatForever(sequence)
        glow.run(pulsate)
        
        // Create rotation animation
        let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 3)
        let rotateForever = SKAction.repeatForever(rotate)
        circle.run(rotateForever)
        
        // Add physics body
        let physicsBody = SKPhysicsBody(circleOfRadius: 15)
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = 16 // Power-up category (matching powerUpCategory in GameScene)
        physicsBody.contactTestBitMask = 1 // Player category
        physicsBody.collisionBitMask = 0 // Don't collide with anything
        
        powerUpNode.physicsBody = physicsBody
        
        // Add all nodes to the parent
        powerUpNode.addChild(glow)
        powerUpNode.addChild(circle)
        powerUpNode.addChild(symbol)
        
        return powerUpNode
    }
    
    // Select a random power-up type based on rarity
    func getRandomPowerUpType() -> PowerUpType {
        let totalRarity = PowerUpType.allCases.reduce(0) { $0 + $1.rarity }
        var randomValue = Int.random(in: 1...totalRarity)
        
        for type in PowerUpType.allCases {
            randomValue -= type.rarity
            if randomValue <= 0 {
                return type
            }
        }
        
        // Default fallback
        return .speedBoost
    }
    
    // Apply power-up effect
    func applyPowerUp(type: PowerUpType, to player: SKNode, in scene: SKScene) -> Bool {
        switch type {
        case .speedBoost:
            return applySpeedBoost(to: scene)
            
        case .shield:
            return applyShield(to: player)
            
        case .shopShield:
            return applyShopShield(to: player)
            
        case .extraLife:
            return applyExtraLife()
            
        case .shrink:
            return applyShrink(to: player)
            
        case .ghost:
            return applyGhost(to: player)
            
        case .multiplier:
            return applyMultiplier()
            
        case .doubleTime:
            return applyDoubleTime()
            
        case .missile:
            return addMissiles(2) // Add 2 missiles
            
        case .sidewinderMissile:
            return addSidewinderMissiles(4) // Add 4 sidewinders
        }
    }
    
    // Speed Boost implementation - "Star Power" inspired effect
    private func applySpeedBoost(to scene: SKScene) -> Bool {
        guard !isSpeedBoostActive else { return false }
        
        isSpeedBoostActive = true
        
        // Speed up the game physics
        scene.physicsWorld.speed = 2.0 // Faster speed boost
        
        // Apply rainbow visual effects
        applySpeedBoostVisuals(in: scene)
        
        // Make player temporarily invincible
        guard let player = scene.childNode(withName: "player"),
              let playerPhysics = player.physicsBody else { return false }
        
        // Store original collision and contact masks
        player.userData = player.userData ?? NSMutableDictionary()
        player.userData?.setValue(playerPhysics.collisionBitMask, forKey: "speedBoostOrigCollision")
        player.userData?.setValue(playerPhysics.contactTestBitMask, forKey: "speedBoostOrigContact")
        
        // Change physics to allow passing through obstacles but still collect items
        playerPhysics.collisionBitMask = 0 // Don't collide with anything
        playerPhysics.contactTestBitMask = 8 | 16 // Score (8) and powerup (16) categories
        
        // Speed up the background music
        NotificationCenter.default.post(name: NSNotification.Name("SpeedBoostActivated"), object: nil)
        
        // Get actual duration based on double time status
        // Double Time makes duration 10 seconds instead of 5
        let actualDuration = isDoubleTimeActive ? 10.0 : PowerUpType.speedBoost.duration
        
        // Set timer to deactivate
        DispatchQueue.main.asyncAfter(deadline: .now() + actualDuration) { [weak self] in
            self?.deactivateSpeedBoost(in: scene)
        }
        
        return true
    }
    
    private func applySpeedBoostVisuals(in scene: SKScene) {
        // Find player node
        guard let player = scene.childNode(withName: "player") else { return }
        
        // Apply rainbow effect to player - simplified version
        player.enumerateChildNodes(withName: "*") { node, _ in
            if let shape = node as? SKShapeNode {
                let colorize1 = SKAction.colorize(with: .red, colorBlendFactor: 0.7, duration: 0.5)
                let colorize2 = SKAction.colorize(with: .orange, colorBlendFactor: 0.7, duration: 0.5)
                let colorize3 = SKAction.colorize(with: .yellow, colorBlendFactor: 0.7, duration: 0.5)
                let colorize4 = SKAction.colorize(with: .green, colorBlendFactor: 0.7, duration: 0.5)
                let colorize5 = SKAction.colorize(with: .blue, colorBlendFactor: 0.7, duration: 0.5)
                let colorize6 = SKAction.colorize(with: .purple, colorBlendFactor: 0.7, duration: 0.5)
                
                let sequence = SKAction.sequence([colorize1, colorize2, colorize3, colorize4, colorize5, colorize6])
                shape.run(SKAction.repeatForever(sequence), withKey: "rainbowEffect")
            }
        }
        
        // Add trailing effect
        let trailEmitter = SKNode()
        trailEmitter.name = "speedTrail"
        player.addChild(trailEmitter)
        
        // Schedule trail particles
        let spawnTrail = SKAction.run { [weak self] in
            self?.addTrailParticle(to: trailEmitter)
        }
        let wait = SKAction.wait(forDuration: 0.05)
        let sequence = SKAction.sequence([spawnTrail, wait])
        trailEmitter.run(SKAction.repeatForever(sequence), withKey: "trailSpawner")
    }
    
    private func addTrailParticle(to node: SKNode) {
        let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple]
        let randomColor = colors.randomElement()!
        
        let particle = SKShapeNode(circleOfRadius: 3)
        particle.fillColor = randomColor
        particle.strokeColor = randomColor
        particle.alpha = 0.7
        particle.position = CGPoint(x: -5, y: 0) // Behind the player
        
        // Add fade out and scale down
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.5)
        let wait = SKAction.wait(forDuration: 0.1)
        let group = SKAction.group([fadeOut, scaleDown])
        let sequence = SKAction.sequence([wait, group, SKAction.removeFromParent()])
        
        particle.run(sequence)
        node.addChild(particle)
    }
    
    private func deactivateSpeedBoost(in scene: SKScene) {
        guard isSpeedBoostActive else { return }
        
        isSpeedBoostActive = false
        
        // Reset physics speed
        scene.physicsWorld.speed = 1.0
        
        // Restore player collision properties
        if let player = scene.childNode(withName: "player"),
           let playerPhysics = player.physicsBody,
           let origCollision = player.userData?.value(forKey: "speedBoostOrigCollision") as? UInt32,
           let origContact = player.userData?.value(forKey: "speedBoostOrigContact") as? UInt32 {
            playerPhysics.collisionBitMask = origCollision
            playerPhysics.contactTestBitMask = origContact
        }
        
        // Notify that speed boost is deactivated
        NotificationCenter.default.post(name: NSNotification.Name("SpeedBoostDeactivated"), object: nil)
        
        // Remove visual effects
        guard let player = scene.childNode(withName: "player") else { return }
        
        player.enumerateChildNodes(withName: "*") { node, _ in
            if let shape = node as? SKShapeNode {
                shape.removeAction(forKey: "rainbowEffect")
                // Remove color effect
                // Note: SKShapeNode doesn't have colorBlendFactor, only SKSpriteNode does
            }
        }
        
        // Remove trail
        player.childNode(withName: "speedTrail")?.removeFromParent()
        
        // Return music to normal
        NotificationCenter.default.post(name: NSNotification.Name("SpeedBoostDeactivated"), object: nil)
    }
    
    // Standard shield - lasts for 5 seconds with continuous protection
    private func applyShield(to player: SKNode) -> Bool {
        guard !isShieldActive else { return false }
        
        isShieldActive = true
        shieldHitCount = 1 // Regular shield blocks exactly one hit
        
        // Create shield container
        let shieldContainer = SKNode()
        shieldContainer.name = "shield"
        
        // Make sure shield doesn't interfere with score nodes
        shieldContainer.physicsBody = nil
        player.addChild(shieldContainer)
        
        // Create main shield bubble with cyan color
        let shield = SKShapeNode(circleOfRadius: 30)
        shield.strokeColor = UIColor.cyan
        shield.lineWidth = 2
        shield.fillColor = UIColor(red: 0, green: 0.8, blue: 1.0, alpha: 0.15) // Light cyan with transparency
        shield.alpha = 0.7
        shield.name = "shieldBubble"
        shieldContainer.addChild(shield)
        
        // Add inner shield ring
        let innerShield = SKShapeNode(circleOfRadius: 25)
        innerShield.strokeColor = UIColor.cyan.withAlphaComponent(0.6)
        innerShield.lineWidth = 1
        innerShield.fillColor = UIColor.clear
        shieldContainer.addChild(innerShield)
        
        // Add energy particles to the shield
        for _ in 0..<8 {
            createShieldParticle(in: shieldContainer)
        }
        
        // Add shield ripple effect
        let spawnRipple = SKAction.run { [weak self] in
            self?.createShieldRipple(in: shieldContainer)
        }
        let wait = SKAction.wait(forDuration: 0.8)
        let sequence = SKAction.sequence([spawnRipple, wait])
        shieldContainer.run(SKAction.repeatForever(sequence), withKey: "rippleEffect")
        
        // Animate main shield
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.7),
            SKAction.fadeAlpha(to: 0.9, duration: 0.7)
        ])
        shield.run(SKAction.repeatForever(pulse))
        
        // Get actual duration based on double time status
        // Double Time makes duration 10 seconds instead of 5
        let actualDuration = isDoubleTimeActive ? 10.0 : PowerUpType.shield.duration
        
        // Timer for shield duration - shield lasts for its full duration regardless of hits
        DispatchQueue.main.asyncAfter(deadline: .now() + actualDuration) { [weak self] in
            self?.deactivateShield(for: player)
        }
        
        return true
    }
    
    // Premium shop shield - blocks 3 hits
    private func applyShopShield(to player: SKNode) -> Bool {
        guard !isShieldActive else { return false }
        
        isShieldActive = true
        shopShieldHitCount = 3 // Premium shield can take 3 hits
        
        // Create shield container
        let shieldContainer = SKNode()
        shieldContainer.name = "shield"
        player.addChild(shieldContainer)
        
        // Create main shield bubble with brighter cyan color
        let shield = SKShapeNode(circleOfRadius: 35) // Slightly larger
        shield.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) 
        shield.lineWidth = 3 // Thicker border
        shield.fillColor = UIColor(red: 0, green: 0.8, blue: 1.0, alpha: 0.2)
        shield.alpha = 0.8
        shield.name = "shieldBubble"
        shieldContainer.addChild(shield)
        
        // Add inner shield ring
        let innerShield = SKShapeNode(circleOfRadius: 28)
        innerShield.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
        innerShield.lineWidth = 2
        innerShield.fillColor = UIColor.clear
        shieldContainer.addChild(innerShield)
        
        // Add counter label (shows remaining hits)
        let counterLabel = SKLabelNode(text: "3")
        counterLabel.fontName = "AvenirNext-Bold"
        counterLabel.fontSize = 18
        counterLabel.fontColor = .white
        counterLabel.name = "shieldCounter"
        counterLabel.position = CGPoint(x: 0, y: 0)
        shieldContainer.addChild(counterLabel)
        
        // Add energy particles to the shield (more than regular shield)
        for _ in 0..<12 {
            createShieldParticle(in: shieldContainer)
        }
        
        // Add shield ripple effect
        let spawnRipple = SKAction.run { [weak self] in
            self?.createShieldRipple(in: shieldContainer)
        }
        let wait = SKAction.wait(forDuration: 0.6) // Faster ripples
        let sequence = SKAction.sequence([spawnRipple, wait])
        shieldContainer.run(SKAction.repeatForever(sequence), withKey: "rippleEffect")
        
        // Animate main shield
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        shield.run(SKAction.repeatForever(pulse))
        
        return true
    }
    
    private func createShieldParticle(in shieldNode: SKNode) {
        let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        let radius: CGFloat = 28
        
        let particle = SKShapeNode(circleOfRadius: 2)
        particle.fillColor = UIColor.cyan
        particle.strokeColor = UIColor.white
        particle.alpha = 0.7
        
        // Position on the shield circumference
        particle.position = CGPoint(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
        
        // Create movement pattern
        let moveAround = SKAction.customAction(withDuration: 3.0) { node, elapsedTime in
            let period = 3.0
            let speed = CGFloat.pi * 2 / period
            let newAngle = angle + speed * CGFloat(elapsedTime)
            node.position = CGPoint(
                x: cos(newAngle) * radius,
                y: sin(newAngle) * radius
            )
        }
        
        particle.run(SKAction.repeatForever(moveAround))
        shieldNode.addChild(particle)
    }
    
    private func createShieldRipple(in shieldNode: SKNode) {
        let ripple = SKShapeNode(circleOfRadius: 20)
        ripple.strokeColor = UIColor.cyan
        ripple.fillColor = UIColor.clear
        ripple.alpha = 0.7
        ripple.lineWidth = 1.5
        ripple.zPosition = -1
        shieldNode.addChild(ripple)
        
        // Animate ripple outward
        let expand = SKAction.scale(to: 1.8, duration: 0.7)
        let fade = SKAction.fadeOut(withDuration: 0.7)
        let group = SKAction.group([expand, fade])
        let remove = SKAction.removeFromParent()
        ripple.run(SKAction.sequence([group, remove]))
    }
    
    func shieldHit() -> Bool {
        guard isShieldActive else { return false }
        
        // Check if it's a shop shield (3 hits) or regular shield (1 hit)
        if shopShieldHitCount > 0 {
            // Premium shop shield logic
            shopShieldHitCount -= 1
            
            // Update the counter label if it exists
            if let playerNode = findPlayerNode(),
               let shield = playerNode.childNode(withName: "shield"),
               let counter = shield.childNode(withName: "shieldCounter") as? SKLabelNode {
                counter.text = "\(shopShieldHitCount)"
                
                // Visual feedback for hit
                let flash = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.2, duration: 0.1),
                    SKAction.fadeAlpha(to: 0.8, duration: 0.1)
                ])
                shield.run(flash)
                
                // Add impact particle effect
                createShieldImpact(in: shield)
            }
            
            if shopShieldHitCount <= 0 {
                // If no hits left, deactivate shield
                if let playerNode = findPlayerNode() {
                    deactivateShield(for: playerNode)
                } else {
            deactivateShield()
                }
            return false
        }
            return true
            
        } else {
            // Regular shield logic - should absorb hits for its entire duration
            // Show visual effect but don't deactivate the shield
            if let playerNode = findPlayerNode(),
               let shield = playerNode.childNode(withName: "shield") {
                // Visual feedback for hit
                let flash = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.9, duration: 0.1),
                    SKAction.fadeAlpha(to: 0.1, duration: 0.1),
                    SKAction.fadeAlpha(to: 0.7, duration: 0.1)
                ])
                shield.run(flash)
                
                // Add shield impact effect for visual feedback
                createShieldImpact(in: shield)
                
                // Create a stronger flash effect to show shield absorbing hit
                let outerFlash = SKShapeNode(circleOfRadius: 40)
                outerFlash.strokeColor = UIColor.cyan
                outerFlash.lineWidth = 3
                outerFlash.fillColor = UIColor.cyan.withAlphaComponent(0.3)
                outerFlash.alpha = 0.7
                outerFlash.position = CGPoint.zero
                outerFlash.zPosition = 2
                shield.addChild(outerFlash)
                
                // Animate and remove the flash
                let expand = SKAction.scale(to: 1.5, duration: 0.3)
                let fade = SKAction.fadeOut(withDuration: 0.3)
                let group = SKAction.group([expand, fade])
                let remove = SKAction.removeFromParent()
                outerFlash.run(SKAction.sequence([group, remove]))
            }
            
            // Return true since we successfully absorbed the hit without deactivating
        return true
        }
    }
    
    // Basic shield deactivation without visual effects
    func deactivateShield() {
        isShieldActive = false
        shieldHitCount = 0
        shopShieldHitCount = 0
    }
    
    // Shield deactivation with visual effects
    private func deactivateShield(for player: SKNode) {
        isShieldActive = false
        shieldHitCount = 0
        shopShieldHitCount = 0
        
        // Remove shield with visual effect
        if let shield = player.childNode(withName: "shield") {
            let expand = SKAction.scale(to: 1.3, duration: 0.2)
            let fade = SKAction.fadeOut(withDuration: 0.2)
            let group = SKAction.group([expand, fade])
            let remove = SKAction.removeFromParent()
            shield.run(SKAction.sequence([group, remove]))
        }
    }
    
    // Create shield impact particles when hit
    private func createShieldImpact(in node: SKNode) {
        // Create a burst of particles at impact point
        let impact = SKNode()
        let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        let distance: CGFloat = 25
        
        impact.position = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
        node.addChild(impact)
        
        // Add impact particles
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = UIColor.cyan
            particle.strokeColor = UIColor.white
            particle.alpha = 0.8
            
            // Random direction
            let particleAngle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let particleDistance = CGFloat.random(in: 5...15)
            particle.position = CGPoint(x: cos(particleAngle) * particleDistance, 
                                        y: sin(particleAngle) * particleDistance)
            
            // Animate and remove
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let moveOut = SKAction.move(by: CGVector(dx: cos(particleAngle) * 20, 
                                                     dy: sin(particleAngle) * 20), 
                                         duration: 0.3)
            let group = SKAction.group([fadeOut, moveOut])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            particle.run(sequence)
            
            impact.addChild(particle)
        }
        
        // Remove impact node after particles finish
        let wait = SKAction.wait(forDuration: 0.5)
        impact.run(SKAction.sequence([wait, SKAction.removeFromParent()]))
    }
    
    // Create larger effect when shield breaks completely
    private func createShieldBreakEffect(in node: SKNode) {
        // Create expanding ring
        let ring = SKShapeNode(circleOfRadius: 30)
        ring.strokeColor = UIColor.cyan
        ring.lineWidth = 3
        ring.fillColor = UIColor.clear
        ring.alpha = 0.7
        ring.zPosition = 30
        node.addChild(ring)
        
        // Expand and fade ring
        let expand = SKAction.scale(to: 2.0, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([expand, fade])
        let remove = SKAction.removeFromParent()
        ring.run(SKAction.sequence([group, remove]))
        
        // Add particles
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = UIColor.cyan
            particle.strokeColor = UIColor.white
            particle.alpha = 0.8
            
            // Random direction from center
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let startDistance: CGFloat = 25
            particle.position = CGPoint(x: cos(angle) * startDistance, y: sin(angle) * startDistance)
            
            // Animate and remove
            let moveDistance: CGFloat = CGFloat.random(in: 40...80)
            let moveDuration = TimeInterval.random(in: 0.3...0.7)
            
            let moveOut = SKAction.move(by: CGVector(dx: cos(angle) * moveDistance, 
                                                    dy: sin(angle) * moveDistance), 
                                        duration: moveDuration)
            let fadeOut = SKAction.fadeOut(withDuration: moveDuration)
            let group = SKAction.group([moveOut, fadeOut])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            particle.run(sequence)
            
            node.addChild(particle)
        }
    }
    
    // Extra Life implementation - adds a red shield/bubble
    private func applyExtraLife() -> Bool {
        guard !hasExtraLife else { return false }
        
        hasExtraLife = true
        UserDefaults.standard.set(true, forKey: "hasExtraLife")
        
        // Find the player node in the scene (to visualize the extra life)
        if let player = findPlayerNode() {
            // Remove any previous indicators
            player.childNode(withName: "extraLifeIndicator")?.removeFromParent()
            player.childNode(withName: "revivalShield")?.removeFromParent()

            // Create a red shield to visualize the extra life (heart + red bubble)
            let extraLifeNode = SKNode()
            extraLifeNode.name = "extraLifeIndicator"
            extraLifeNode.zPosition = 20
            player.addChild(extraLifeNode)
            
            // Create heart shape
            let heart = SKShapeNode(circleOfRadius: 12)
            heart.fillColor = UIColor.red.withAlphaComponent(0.3)
            heart.strokeColor = UIColor.red
            heart.lineWidth = 1.5
            heart.alpha = 0.9
            extraLifeNode.addChild(heart)
            
            // Create heart symbol
            let heartSymbol = SKLabelNode(text: "❤️")
            heartSymbol.fontSize = 12
            heartSymbol.verticalAlignmentMode = .center
            heartSymbol.horizontalAlignmentMode = .center
            heartSymbol.position = CGPoint(x: 0, y: 0)
            extraLifeNode.addChild(heartSymbol)
            
            // Position the extra life indicator above the player
            extraLifeNode.position = CGPoint(x: 0, y: 30)
            
            // Add pulsating animation to the heart
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
            let scaleDown = SKAction.scale(to: 0.8, duration: 0.5)
            let pulse = SKAction.sequence([scaleUp, scaleDown])
            extraLifeNode.run(SKAction.repeatForever(pulse))

            // Per request, don't add a red bubble; the heart indicator alone conveys extra life
        }
        
        return true
    }
    
    func useExtraLife() -> Bool {
        guard hasExtraLife else { return false }
        
        hasExtraLife = false
        UserDefaults.standard.set(false, forKey: "hasExtraLife")
        
        return true
    }
    
    // Double Time implementation - doubles the duration of timed power-ups
    private func applyDoubleTime() -> Bool {
        guard !isDoubleTimeActive else { return false }
        
        isDoubleTimeActive = true
        UserDefaults.standard.set(true, forKey: "isDoubleTimeActive")
        
        // Show a timer visual near the player if we can find them
        if let player = findPlayerNode() {
            
            // Create timer indicator
            let timerNode = SKNode()
            timerNode.name = "doubleTimeIndicator"
            timerNode.zPosition = 20
            player.addChild(timerNode)
            
            // Create timer icon
            let timerIcon = SKLabelNode(text: "⏱️")
            timerIcon.fontSize = 16
            timerIcon.verticalAlignmentMode = .center
            timerIcon.horizontalAlignmentMode = .center
            timerNode.addChild(timerIcon)
            
            // Create glow effect
            let glow = SKShapeNode(circleOfRadius: 12)
            glow.fillColor = UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 0.3)
            glow.strokeColor = UIColor(red: 0.0, green: 0.7, blue: 0.7, alpha: 0.7)
            glow.lineWidth = 2
            glow.zPosition = -1
            timerNode.addChild(glow)
            
            // Position at bottom right of player
            timerNode.position = CGPoint(x: 20, y: 20)
            
            // Add floating animation
            let moveUp = SKAction.moveBy(x: 0, y: 5, duration: 1.0)
            let moveDown = SKAction.moveBy(x: 0, y: -5, duration: 1.0)
            let sequence = SKAction.sequence([moveUp, moveDown])
            timerNode.run(SKAction.repeatForever(sequence))
        }
        
        return true
    }
    
    private func deactivateDoubleTime() {
        guard isDoubleTimeActive else { return }
        
        isDoubleTimeActive = false
        UserDefaults.standard.set(false, forKey: "isDoubleTimeActive")
        
        // Remove any visual indicators
        if let gameScene = getCurrentScene() {
            gameScene.enumerateChildNodes(withName: "//doubleTimeIndicator") { node, _ in
            node.removeFromParent()
            }
        }
    }
    
    // Shrink implementation - now shrinks OBSTACLES instead of player
    private func applyShrink(to player: SKNode) -> Bool {
        guard !isShrinkActive else { return false }
        
        isShrinkActive = true
        
        // Find the scene
        guard let scene = player.scene else { return false }
        
        // Add magnifying glass visual effect
        let magnifyingGlass = SKNode()
        magnifyingGlass.name = "magnifyingGlass"
        magnifyingGlass.zPosition = 100
        
        // Create glass circle
        let glass = SKShapeNode(circleOfRadius: 40)
        glass.fillColor = UIColor.clear
        glass.strokeColor = UIColor.gray
        glass.lineWidth = 3
        glass.alpha = 0.7
        
        // Create handle
        let handle = SKShapeNode(rectOf: CGSize(width: 5, height: 30), cornerRadius: 2)
        handle.fillColor = UIColor.gray
        handle.strokeColor = UIColor.gray
        handle.position = CGPoint(x: 30, y: -30) // Bottom right
        handle.zRotation = CGFloat.pi / 4 // 45 degrees
        
        magnifyingGlass.addChild(glass)
        magnifyingGlass.addChild(handle)
        player.addChild(magnifyingGlass)
        
        // Find upcoming obstacles (all obstacles ahead of the player)
        var obstaclesToShrink: [SKNode] = []
        scene.enumerateChildNodes(withName: "obstacle") { obstacle, _ in
            // Only consider obstacles ahead of the player (to the right)
            if obstacle.position.x > (player.position.x - 20) {
                // Make sure the obstacle has a physics body and isn't already shrunk
                if obstacle.physicsBody != nil && obstacle.userData?.value(forKey: "isShrunk") == nil {
                    obstaclesToShrink.append(obstacle)
                }
            }
        }
        
        // Sort by x position (nearest to player first)
        obstaclesToShrink.sort { $0.position.x < $1.position.x }
        
        // Get the next 3 obstacles (or fewer if there aren't 3)
        let targetObstacles = Array(obstaclesToShrink.prefix(3))
        
        // Add a node to keep track of affected obstacles
        let shrinkTracker = SKNode()
        shrinkTracker.name = "shrinkTracker"
        scene.addChild(shrinkTracker)
        
        // Shrink the selected obstacles
        for obstacle in targetObstacles {
        // Store original scale
            let originalWidth = obstacle.frame.width
            let originalHeight = obstacle.frame.height
            
            obstacle.userData = obstacle.userData ?? NSMutableDictionary()
            obstacle.userData?.setValue(originalWidth, forKey: "originalWidth")
            obstacle.userData?.setValue(originalHeight, forKey: "originalHeight")
            obstacle.userData?.setValue(true, forKey: "isShrunk")
            
            // Add to tracker
            shrinkTracker.userData = shrinkTracker.userData ?? NSMutableDictionary()
            let obstaclesList = shrinkTracker.userData?.value(forKey: "shrunkObstacles") as? [SKNode] ?? []
            shrinkTracker.userData?.setValue(obstaclesList + [obstacle], forKey: "shrunkObstacles")
            
            // Shrink obstacle
            let shrinkAction = SKAction.scale(to: 0.7, duration: 0.3) // Shrink to 70% size
            obstacle.run(shrinkAction)
            
            // Add visual indicator
            let indicator = SKSpriteNode(color: .green, size: CGSize(width: 10, height: 10))
            indicator.alpha = 0.5
            indicator.name = "shrinkIndicator"
            obstacle.addChild(indicator)
        
            // Update physics body to match new size
            if let physics = obstacle.physicsBody {
                let newWidth = originalWidth * 0.7
                let newHeight = originalHeight * 0.7
                
                let newPhysics = SKPhysicsBody(rectangleOf: CGSize(width: newWidth, height: newHeight))
                newPhysics.isDynamic = physics.isDynamic
                newPhysics.categoryBitMask = physics.categoryBitMask
                newPhysics.contactTestBitMask = physics.contactTestBitMask
                newPhysics.collisionBitMask = physics.collisionBitMask
                
                obstacle.physicsBody = newPhysics
            }
        }
        
        // Get actual duration based on double time status
        // Double Time makes duration 10 seconds instead of 5
        let actualDuration = isDoubleTimeActive ? 10.0 : PowerUpType.shrink.duration
        
        // Set timer to deactivate
        DispatchQueue.main.asyncAfter(deadline: .now() + actualDuration) {
            [weak self] in
            self?.deactivateShrink(in: scene)
        }
        
        return true
    }
    
    private func deactivateShrink(in scene: SKScene) {
        guard isShrinkActive else { return }
        
        isShrinkActive = false
        
        // Remove magnifying glass from player
        scene.enumerateChildNodes(withName: "//magnifyingGlass") { node, _ in
            node.removeFromParent()
        }
        
        // Restore all obstacles to original size
        scene.enumerateChildNodes(withName: "obstacle") { obstacle, _ in
            // Restore original size
            if let originalWidth = obstacle.userData?.value(forKey: "originalWidth") as? CGFloat,
               let originalHeight = obstacle.userData?.value(forKey: "originalHeight") as? CGFloat {
                
                let growAction = SKAction.scale(to: 1.0, duration: 0.3) // Return to original scale
                
                // Temporarily disable collisions during resize to prevent invisible wall crashes
                let disableCollisionAction = SKAction.run {
                    obstacle.physicsBody?.collisionBitMask = 0
                    obstacle.physicsBody?.contactTestBitMask = 0
                }
                
                // Create physics body restoration action that runs AFTER the visual scaling completes
                let restorePhysicsAction = SKAction.run {
                    // Check if obstacle still exists before restoring physics
                    guard let physics = obstacle.physicsBody else { return }
                    
                    // Determine physics body shape based on obstacle type
                    let newPhysics: SKPhysicsBody
                    
                    // Check if this is a triangular obstacle (pyramid)
                    if let isTriangular = obstacle.userData?.value(forKey: "isTriangular") as? Bool, isTriangular {
                        // Create triangular physics body for pyramids
                        let trianglePath = CGMutablePath()
                        trianglePath.move(to: CGPoint(x: -originalWidth/2, y: -originalHeight/2))
                        trianglePath.addLine(to: CGPoint(x: originalWidth/2, y: -originalHeight/2))
                        trianglePath.addLine(to: CGPoint(x: 0, y: originalHeight/2))
                        trianglePath.closeSubpath()
                        newPhysics = SKPhysicsBody(polygonFrom: trianglePath)
                    } else {
                        // Create rectangular physics body for other obstacles
                        newPhysics = SKPhysicsBody(rectangleOf: CGSize(width: originalWidth, height: originalHeight))
                    }
                    
                    // Copy physics properties
                    newPhysics.isDynamic = physics.isDynamic
                    newPhysics.categoryBitMask = physics.categoryBitMask
                    newPhysics.contactTestBitMask = physics.contactTestBitMask
                    newPhysics.collisionBitMask = 0 // Keep collisions disabled initially
                    
                    obstacle.physicsBody = newPhysics
                }
                
                // Re-enable collisions after a brief delay to ensure smooth transition
                let enableCollisionAction = SKAction.run {
                    obstacle.physicsBody?.collisionBitMask = 0 // Obstacles don't cause physics collisions, only contact detection
                    obstacle.physicsBody?.contactTestBitMask = 1 // playerCategory value
                }
                
                // Run the complete sequence: disable collisions, scale visual, restore physics, then re-enable detection
                let waitAction = SKAction.wait(forDuration: 0.1) // Brief delay before re-enabling contact detection
                let sequence = SKAction.sequence([
                    disableCollisionAction,  // First disable collisions
                    growAction,              // Then scale visually 
                    restorePhysicsAction,    // Then restore physics body
                    waitAction,              // Wait briefly
                    enableCollisionAction    // Finally re-enable contact detection
                ])
                obstacle.run(sequence)
            }
        }
    }
    
    // Ghost implementation - enhanced transparency and pass-through ability
    private func applyGhost(to player: SKNode) -> Bool {
        guard !isGhostActive else { return false }
        
        isGhostActive = true
        
        // Make player more transparent for ghost effect
        player.alpha = 0.4
        
        // Add ghost trail effect
        let ghostTrail = SKNode()
        ghostTrail.name = "ghostTrail"
        player.addChild(ghostTrail)
        
        // Schedule ghost trail particles
        let spawnGhost = SKAction.run { [weak self] in
            self?.addGhostTrail(to: player, trailNode: ghostTrail)
        }
        let wait = SKAction.wait(forDuration: 0.1)
        let sequence = SKAction.sequence([spawnGhost, wait])
        ghostTrail.run(SKAction.repeatForever(sequence), withKey: "ghostTrailEffect")
        
        // Add blinking effect for more ghostly appearance
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.3),
            SKAction.fadeAlpha(to: 0.5, duration: 0.3)
        ])
        player.run(SKAction.repeatForever(blink), withKey: "ghostBlink")
        
        // Change collision masks to pass through obstacles
        if let physics = player.physicsBody {
            player.userData = player.userData ?? NSMutableDictionary()
            player.userData?.setValue(physics.collisionBitMask, forKey: "originalCollisionMask")
            player.userData?.setValue(physics.contactTestBitMask, forKey: "originalContactMask")
            
            // Don't collide with anything when in ghost mode
            physics.collisionBitMask = 0
            
            // Keep contact test with score nodes and power-ups
            physics.contactTestBitMask = 8 | 16 // Score and power-up categories
        }
        
        // Get actual duration based on double time status
        // Double Time makes duration 10 seconds instead of 5
        let actualDuration = isDoubleTimeActive ? 10.0 : PowerUpType.ghost.duration
        
        // Set timer to deactivate
        DispatchQueue.main.asyncAfter(deadline: .now() + actualDuration) { [weak self] in
            self?.deactivateGhost(for: player)
        }
        
        return true
    }
    
    private func addGhostTrail(to player: SKNode, trailNode: SKNode) {
        // Create ghost trail effect with fading copies of player
        let ghostCopy = SKShapeNode(circleOfRadius: 15)
        ghostCopy.fillColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.2) // Ghostly blue color
        ghostCopy.strokeColor = UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 0.3)
        ghostCopy.lineWidth = 1
        ghostCopy.position = .zero // Local coordinates
        ghostCopy.zPosition = -1 // Behind the player
        
        // Add fade out and drift
        let fadeOut = SKAction.fadeOut(withDuration: 0.7)
        let drift = SKAction.moveBy(x: -15, y: 0, duration: 0.7)
        let group = SKAction.group([fadeOut, drift])
        let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
        
        ghostCopy.run(sequence)
        trailNode.addChild(ghostCopy)
    }
    
    private func deactivateGhost(for player: SKNode) {
        guard isGhostActive else { return }
        
        isGhostActive = false
        
        // Remove ghost blinking
        player.removeAction(forKey: "ghostBlink")
        
        // Restore opacity with animation
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        player.run(fadeIn)
        
        // Remove ghost trail effect
        if let ghostTrail = player.childNode(withName: "ghostTrail") {
            ghostTrail.removeAction(forKey: "ghostTrailEffect")
            ghostTrail.removeFromParent()
        }
        
        // Restore collision and contact masks
        if let physics = player.physicsBody,
           let originalCollisionMask = player.userData?.value(forKey: "originalCollisionMask") as? UInt32,
           let originalContactMask = player.userData?.value(forKey: "originalContactMask") as? UInt32 {
            physics.collisionBitMask = originalCollisionMask
            physics.contactTestBitMask = originalContactMask
        }
    }
    
    // Multiplier implementation - 2x points scored
    private func applyMultiplier() -> Bool {
        guard !isMultiplierActive else { return false }
        
        isMultiplierActive = true
        scoreMultiplier = 2
        
        // Create a visual indicator if we can find the scene
        if let gameScene = getCurrentScene() {
            
            // Create a multiplier indicator at top of screen
            let indicatorNode = SKNode()
            indicatorNode.name = "multiplierIndicator"
            indicatorNode.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height - 50)
            indicatorNode.zPosition = 100
            gameScene.addChild(indicatorNode)
            
            // Create "2x" text
            let multiplierText = SKLabelNode(text: "2x")
            multiplierText.fontName = "AvenirNext-Bold"
            multiplierText.fontSize = 24
            multiplierText.fontColor = UIColor.orange
            multiplierText.verticalAlignmentMode = .center
            multiplierText.horizontalAlignmentMode = .center
            indicatorNode.addChild(multiplierText)
            
            // Add glow effect
            let glow = SKShapeNode(circleOfRadius: 16)
            glow.fillColor = UIColor.orange.withAlphaComponent(0.2)
            glow.strokeColor = UIColor.orange.withAlphaComponent(0.4)
            glow.lineWidth = 2
            glow.zPosition = -1
            indicatorNode.addChild(glow)
            
            // Add pulsating animation
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.5)
            let pulse = SKAction.sequence([scaleUp, scaleDown])
            indicatorNode.run(SKAction.repeatForever(pulse))
        }
        
        // Get actual duration based on double time status
        // Double Time makes duration 10 seconds instead of 5
        let actualDuration = isDoubleTimeActive ? 10.0 : PowerUpType.multiplier.duration
        
        // Set timer to deactivate
        DispatchQueue.main.asyncAfter(deadline: .now() + actualDuration) { [weak self] in
            self?.deactivateMultiplier()
        }
        
        return true
    }
    
    private func deactivateMultiplier() {
        guard isMultiplierActive else { return }
        
        isMultiplierActive = false
        scoreMultiplier = 1
        
        // Remove the visual indicator
        if let gameScene = getCurrentScene() {
            gameScene.enumerateChildNodes(withName: "multiplierIndicator") { node, _ in
                // Fade out and remove
                let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                let remove = SKAction.removeFromParent()
                node.run(SKAction.sequence([fadeOut, remove]))
            }
        }
    }
    
    // Mystery power-up - gives a random other power-up
    // This now gives a random power-up instead of mystery (which no longer exists)
    private func applyMystery(to player: SKNode, in scene: SKScene) -> Bool {
        // Exclude some rarer powers
        let availableTypes = PowerUpType.allCases.filter { $0 != .doubleTime && $0 != .extraLife && $0 != .shopShield }
        
        if let randomType = availableTypes.randomElement() {
            return applyPowerUp(type: randomType, to: player, in: scene)
        }
        
        return false
    }
    
    // Reset all power-ups (e.g., when game ends)
    func resetAllPowerUps(in scene: SKScene) {
        if let player = scene.childNode(withName: "player") {
            if isSpeedBoostActive {
                deactivateSpeedBoost(in: scene)
            }
            
            if isShieldActive {
                deactivateShield(for: player)
            }
            
            if isShrinkActive {
                deactivateShrink(in: scene)
            }
            
            if isGhostActive {
                deactivateGhost(for: player)
            }
            
            if isMultiplierActive {
                deactivateMultiplier()
            }
            
            if isDoubleTimeActive {
                deactivateDoubleTime()
            }
        }
        
        // Extra life and missile counts persist until used
    }
    
    // MARK: - Missile Implementation
    
    // Add regular missiles
    func addMissiles(_ count: Int) -> Bool {
        missileCount += count
        UserDefaults.standard.set(missileCount, forKey: "missileCount")
        return true
    }
    
    // Add sidewinder missiles
    func addSidewinderMissiles(_ count: Int) -> Bool {
        sidewinderCount += count
        UserDefaults.standard.set(sidewinderCount, forKey: "sidewinderCount")
        return true
    }
    
    // Fire a regular missile
    func fireMissile(from player: SKNode, in scene: SKScene) -> Bool {
        guard missileCount > 0 else { return false }
        
        missileCount -= 1
        UserDefaults.standard.set(missileCount, forKey: "missileCount")
        
        // Create missile node
        let missile = createMissileNode()
        missile.position = CGPoint(x: player.position.x + 30, y: player.position.y)
        missile.zPosition = 30
        scene.addChild(missile)
        
        // Fire missile forward
        let moveAction = SKAction.moveBy(x: scene.size.width, y: 0, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])
        missile.run(sequence)
        
        // Check for collisions with obstacles
        let wait = SKAction.wait(forDuration: 0.1)
        let check = SKAction.run {
            scene.enumerateChildNodes(withName: "obstacle") { obstacle, stop in
                if obstacle.frame.intersects(missile.frame) {
                    self.createExplosion(at: obstacle.position, in: scene)
                    obstacle.removeFromParent()
                    missile.removeFromParent()
                    stop.pointee = true
                }
            }
        }
        let checkSequence = SKAction.sequence([wait, check])
        missile.run(SKAction.repeatForever(checkSequence))
        
        return true
    }
    
    // Fire a sidewinder missile
    func fireSidewinderMissile(from player: SKNode, in scene: SKScene) -> Bool {
        guard sidewinderCount > 0 else { return false }
        
        sidewinderCount -= 1
        UserDefaults.standard.set(sidewinderCount, forKey: "sidewinderCount")
        
        // Create missile node
        let missile = createSidewinderMissileNode()
        missile.position = CGPoint(x: player.position.x + 30, y: player.position.y)
        missile.zPosition = 30
        scene.addChild(missile)
        
        // Find the closest obstacle
        var closestObstacle: SKNode?
        var closestDistance = CGFloat.greatestFiniteMagnitude
        
        scene.enumerateChildNodes(withName: "obstacle") { obstacle, _ in
            // Only consider obstacles ahead of the player
            if obstacle.position.x > player.position.x {
                let distance = hypot(obstacle.position.x - player.position.x, obstacle.position.y - player.position.y)
                if distance < closestDistance {
                    closestDistance = distance
                    closestObstacle = obstacle
                }
            }
        }
        
        if let target = closestObstacle {
            // Calculate path to target
            let targetPoint = target.position
            
            // Create a path with a slight curve for homing effect
            let path = UIBezierPath()
            path.move(to: CGPoint.zero) // Local coordinates
            
            // Control point for curved path
            let controlPoint = CGPoint(x: (targetPoint.x - missile.position.x) / 2, 
                                      y: (targetPoint.y - missile.position.y) / 2 - 40)
            
            path.addQuadCurve(to: CGPoint(x: targetPoint.x - missile.position.x, 
                                         y: targetPoint.y - missile.position.y), 
                             controlPoint: controlPoint)
            
            // Follow path action
            let followPath = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, duration: 0.8)
            let explode = SKAction.run {
                self.createExplosion(at: target.position, in: scene)
                target.removeFromParent()
                missile.removeFromParent()
            }
            let sequence = SKAction.sequence([followPath, explode])
            missile.run(sequence)
        } else {
            // No target found, just fly forward
            let moveAction = SKAction.moveBy(x: scene.size.width, y: 0, duration: 1.0)
            let removeAction = SKAction.removeFromParent()
            missile.run(SKAction.sequence([moveAction, removeAction]))
        }
        
        return true
    }
    
    private func createMissileNode() -> SKNode {
        let missileNode = SKNode()
        
        // Missile body
        let body = SKShapeNode(rectOf: CGSize(width: 20, height: 8), cornerRadius: 3)
        body.fillColor = UIColor.red
        body.strokeColor = UIColor.darkGray
        body.lineWidth = 1
        missileNode.addChild(body)
        
        // Missile nose cone
        let noseCone = SKShapeNode(rectOf: CGSize(width: 6, height: 6), cornerRadius: 3)
        noseCone.fillColor = UIColor.gray
        noseCone.strokeColor = UIColor.darkGray
        noseCone.lineWidth = 1
        noseCone.position = CGPoint(x: 13, y: 0)
        missileNode.addChild(noseCone)
        
        // Missile fins
        let topFin = SKShapeNode(rectOf: CGSize(width: 6, height: 4), cornerRadius: 1)
        topFin.fillColor = UIColor.darkGray
        topFin.strokeColor = UIColor.black
        topFin.lineWidth = 0.5
        topFin.position = CGPoint(x: -8, y: 6)
        missileNode.addChild(topFin)
        
        let bottomFin = SKShapeNode(rectOf: CGSize(width: 6, height: 4), cornerRadius: 1)
        bottomFin.fillColor = UIColor.darkGray
        bottomFin.strokeColor = UIColor.black
        bottomFin.lineWidth = 0.5
        bottomFin.position = CGPoint(x: -8, y: -6)
        missileNode.addChild(bottomFin)
        
        // Exhaust flame
        let flame = SKShapeNode(rectOf: CGSize(width: 8, height: 4), cornerRadius: 2)
        flame.fillColor = UIColor.orange
        flame.strokeColor = UIColor.yellow
        flame.lineWidth = 1
        flame.position = CGPoint(x: -14, y: 0)
        missileNode.addChild(flame)
        
        // Animate flame
        let scaleUp = SKAction.scaleX(to: 1.5, y: 1.2, duration: 0.1)
        let scaleDown = SKAction.scaleX(to: 0.8, y: 0.8, duration: 0.1)
        flame.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
        
        // Add physics body for collision detection
        missileNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 10))
        missileNode.physicsBody?.isDynamic = true
        missileNode.physicsBody?.affectedByGravity = false
        missileNode.physicsBody?.collisionBitMask = 0 // Don't collide with anything
        
        return missileNode
    }
    
    private func createSidewinderMissileNode() -> SKNode {
        let missileNode = SKNode()
        
        // Missile body (slightly more advanced than regular missile)
        let body = SKShapeNode(rectOf: CGSize(width: 25, height: 8), cornerRadius: 4)
        body.fillColor = UIColor.orange
        body.strokeColor = UIColor.darkGray
        body.lineWidth = 1
        missileNode.addChild(body)
        
        // Missile nose cone
        let noseCone = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 4)
        noseCone.fillColor = UIColor(red: 0.9, green: 0.4, blue: 0.0, alpha: 1.0)
        noseCone.strokeColor = UIColor.darkGray
        noseCone.lineWidth = 1
        noseCone.position = CGPoint(x: 16, y: 0)
        missileNode.addChild(noseCone)
        
        // Target sensor (blinking light)
        let sensor = SKShapeNode(circleOfRadius: 3)
        sensor.fillColor = UIColor.red
        sensor.strokeColor = UIColor.clear
        sensor.position = CGPoint(x: 18, y: 0)
        missileNode.addChild(sensor)
        
        // Make sensor blink
        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.2)
        ])
        sensor.run(SKAction.repeatForever(blink))
        
        // Missile fins (X configuration for better turning)
        let fins = SKNode()
        fins.position = CGPoint(x: -10, y: 0)
        missileNode.addChild(fins)
        
        for i in 0..<4 {
            let angle = CGFloat(i) * .pi / 2.0
            let fin = SKShapeNode(rectOf: CGSize(width: 8, height: 3), cornerRadius: 1)
            fin.fillColor = UIColor.darkGray
            fin.strokeColor = UIColor.black
            fin.lineWidth = 0.5
            
            // Position fin at the right angle
            fin.zRotation = angle
            fin.position = CGPoint(x: -cos(angle) * 5, y: sin(angle) * 5)
            fins.addChild(fin)
        }
        
        // Exhaust flame
        let flame = SKShapeNode(rectOf: CGSize(width: 10, height: 5), cornerRadius: 2)
        flame.fillColor = UIColor.orange
        flame.strokeColor = UIColor.yellow
        flame.lineWidth = 1
        flame.position = CGPoint(x: -18, y: 0)
        missileNode.addChild(flame)
        
        // Animate flame
        let scaleUp = SKAction.scaleX(to: 1.5, y: 1.2, duration: 0.1)
        let scaleDown = SKAction.scaleX(to: 0.8, y: 0.8, duration: 0.1)
        flame.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
        
        // Add physics body for collision detection
        missileNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 35, height: 10))
        missileNode.physicsBody?.isDynamic = true
        missileNode.physicsBody?.affectedByGravity = false
        missileNode.physicsBody?.collisionBitMask = 0 // Don't collide with anything
        
        return missileNode
    }
    
    private func createExplosion(at position: CGPoint, in scene: SKScene) {
        // Main explosion
        let explosion = SKNode()
        explosion.position = position
        explosion.zPosition = 40
        scene.addChild(explosion)
        
        // Create explosion circles
        for i in 0..<3 {
            let size = 20.0 + Double(i) * 15.0
            let delay = Double(i) * 0.05
            
            let circle = SKShapeNode(circleOfRadius: CGFloat(size / 2))
            circle.fillColor = i == 0 ? .white : (i == 1 ? .yellow : .orange)
            circle.strokeColor = .clear
            circle.alpha = 0
            circle.setScale(0.1)
            explosion.addChild(circle)
            
            // Animate the explosion circle
            let wait = SKAction.wait(forDuration: delay)
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let scale = SKAction.scale(to: 1.0, duration: 0.3)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let group = SKAction.group([scale, SKAction.sequence([fadeIn, SKAction.wait(forDuration: 0.1), fadeOut])])
            let sequence = SKAction.sequence([wait, group])
            circle.run(sequence)
        }
        
        // Add debris particles
        for _ in 0..<12 {
            let debris = SKShapeNode(circleOfRadius: 2)
            debris.fillColor = UIColor.orange
            debris.strokeColor = UIColor.clear
            debris.position = .zero
            explosion.addChild(debris)
            
            // Random direction for debris
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 30...60)
            let destination = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            
            // Animate debris
            let move = SKAction.move(to: destination, duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let group = SKAction.group([move, fade])
            debris.run(group)
        }
        
        // Remove explosion after animation completes
        let wait = SKAction.wait(forDuration: 0.7)
        let remove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([wait, remove]))
    }
    
    // Purchase missiles for the player
    func purchaseMissiles(_ count: Int) -> Bool {
        _ = addMissiles(count)
        return true
    }
    
    // Purchase sidewinder missiles for the player
    func purchaseSidewinderMissiles(_ count: Int) -> Bool {
        _ = addSidewinderMissiles(count)
        return true
    }
    
    // MARK: - Helper Methods
    
    // Helper to get the current game scene without using deprecated keyWindow
    private func getCurrentScene() -> SKScene? {
        // Get all connected scenes in iOS 13+
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        
        // Find the first window with an SKView as its root view
        if let window = windowScene?.windows.first(where: { $0.isKeyWindow }) {
            if let skView = window.rootViewController?.view as? SKView {
                return skView.scene
            }
        }
        
        return nil
    }
    
    // Helper to find the player node in the current scene
    private func findPlayerNode() -> SKNode? {
        return getCurrentScene()?.childNode(withName: "player")
    }
}