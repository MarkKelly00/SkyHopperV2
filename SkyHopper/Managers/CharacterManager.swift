import SpriteKit
import UIKit

class CharacterManager {
    static let shared = CharacterManager()
    
    enum AircraftType: String, CaseIterable {
        case mapDefault // Special case that adapts to current map theme
        case helicopter
        case fighterJet
        case rocketPack
        case mustangPlane
        case biplane
        case eagle
        case duck
        case dragon
        case f22Raptor // New F22 Raptor for Stargate Escape level
    }
    
    struct Aircraft {
        let type: AircraftType
        let name: String
        let description: String
        let speed: CGFloat
        let size: CGSize
        let unlockCost: Int
        var isUnlocked: Bool
        let specialAbility: String
    }
    
    var selectedAircraft: AircraftType = .mapDefault
    var unlockedAircraft: [AircraftType] = [.mapDefault, .helicopter]
    
    var allAircraft: [Aircraft] = []
    
    private init() {
        setupAircraft()
    }
    
    private func setupAircraft() {
        allAircraft = [
            Aircraft(
                type: .mapDefault,
                name: "Map Default",
                description: "Aircraft automatically changes based on the current map theme",
                speed: 1.0, // Standard speed, actual speed will depend on the map's aircraft
                size: CGSize(width: 50, height: 30),
                unlockCost: 0, // Always free and unlocked
                isUnlocked: true,
                specialAbility: "Chameleon - Adapts to the current environment"
            ),
            Aircraft(
                type: .helicopter,
                name: "Sky Chopper",
                description: "The classic helicopter with balanced stats",
                speed: 1.0,
                size: CGSize(width: 50, height: 30),
                unlockCost: 500, // Now costs coins since it's not the default
                isUnlocked: true,
                specialAbility: "None - Balanced starter craft"
            ),
            Aircraft(
                type: .fighterJet,
                name: "Sonic Jet",
                description: "Fast jet with sleek handling",
                speed: 1.5,
                size: CGSize(width: 60, height: 20), // Longer but thinner
                unlockCost: 5000,
                isUnlocked: false,
                specialAbility: "Afterburner - Temporary speed boost cooldown reduced by 50%"
            ),
            Aircraft(
                type: .rocketPack,
                name: "Rocket Man",
                description: "Personal jetpack with unique controls",
                speed: 1.2,
                size: CGSize(width: 30, height: 40), // Small but tall
                unlockCost: 3000,
                isUnlocked: false,
                specialAbility: "Hover - Briefly pause mid-air once per run"
            ),
            Aircraft(
                type: .mustangPlane,
                name: "Vintage Mustang",
                description: "Classic WWII fighter with style",
                speed: 1.1,
                size: CGSize(width: 55, height: 25),
                unlockCost: 4000,
                isUnlocked: false,
                specialAbility: "Barrel Roll - Invincibility during roll animation"
            ),
            Aircraft(
                type: .biplane,
                name: "Barnstormer",
                description: "Old-school biplane with charm",
                speed: 0.9, // Slower
                size: CGSize(width: 50, height: 35),
                unlockCost: 2000,
                isUnlocked: false,
                specialAbility: "Lucky Clover - Higher chance of power-up spawns"
            ),
            Aircraft(
                type: .eagle,
                name: "Mighty Eagle",
                description: "Majestic bird with natural flying ability",
                speed: 1.2,
                size: CGSize(width: 45, height: 30),
                unlockCost: 10000,
                isUnlocked: false,
                specialAbility: "Wind Rider - Less affected by obstacle patterns"
            ),
            Aircraft(
                type: .duck,
                name: "Lucky Duck",
                description: "Quirky duck with surprising skills",
                speed: 0.8, // Slowest
                size: CGSize(width: 40, height: 35), // Small size helps compensate
                unlockCost: 7500,
                isUnlocked: false,
                specialAbility: "Water Landing - Survive one water crash per run"
            ),
            Aircraft(
                type: .dragon,
                name: "Fire Dragon",
                description: "Legendary creature with fiery breath",
                speed: 1.3,
                size: CGSize(width: 60, height: 40), // Largest
                unlockCost: 25000, // Most expensive
                isUnlocked: false,
                specialAbility: "Fire Breath - Burn through one obstacle per run"
            ),
            Aircraft(
                type: .f22Raptor,
                name: "F-22 Raptor",
                description: "Advanced stealth tactical fighter with superior maneuverability",
                speed: 1.6, // Fastest aircraft
                size: CGSize(width: 60, height: 20), // Long and sleek
                unlockCost: 15000,
                isUnlocked: false,
                specialAbility: "Stealth Mode - Temporarily invisible to obstacles"
            )
        ]
    }
    
    func unlockAircraft(type: AircraftType) -> Bool {
        guard let index = allAircraft.firstIndex(where: { $0.type == type }) else { return false }
        guard !allAircraft[index].isUnlocked else { return false } // Already unlocked
        
        // Check if player has enough currency - this would connect to CurrencyManager
        // if CurrencyManager.shared.spend(coins: allAircraft[index].unlockCost) {
        
        // For now, just unlock it
        allAircraft[index].isUnlocked = true
        unlockedAircraft.append(type)
        saveUnlockedAircraft()
        return true
        // }
        // return false
    }
    
    func selectAircraft(type: AircraftType) -> Bool {
        guard unlockedAircraft.contains(type) else { return false }
        selectedAircraft = type
        UserDefaults.standard.set(type.rawValue, forKey: "selectedAircraft")
        return true
    }
    
    func getSelectedAircraft() -> Aircraft? {
        return allAircraft.first(where: { $0.type == selectedAircraft })
    }
    
    func getAircraft(type: AircraftType) -> Aircraft? {
        return allAircraft.first(where: { $0.type == type })
    }
    
    // Persistence
    func loadSavedData() {
        if let savedRaw = UserDefaults.standard.stringArray(forKey: "unlockedAircraft") {
            unlockedAircraft = savedRaw.compactMap { AircraftType(rawValue: $0) }
        }
        
        if let savedSelectedRaw = UserDefaults.standard.string(forKey: "selectedAircraft"),
           let savedSelected = AircraftType(rawValue: savedSelectedRaw) {
            selectedAircraft = savedSelected
        }
        
        // Update the unlocked status in the allAircraft array
        for type in unlockedAircraft {
            if let index = allAircraft.firstIndex(where: { $0.type == type }) {
                allAircraft[index].isUnlocked = true
            }
        }
    }
    
    func saveUnlockedAircraft() {
        let rawValues = unlockedAircraft.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: "unlockedAircraft")
    }
    
    // Create aircraft sprite methods for GameScene to use
    func createAircraftSprite(for type: AircraftType, enablePhysics: Bool = false) -> SKSpriteNode {
        // For mapDefault, we'll create a special sprite that shows it's a multi-aircraft option
        if type == .mapDefault {
            return createMapDefaultSprite(enablePhysics: enablePhysics)
        }
        
        let sprite: SKSpriteNode
        
        switch type {
        case .helicopter:
            sprite = createHelicopterSprite()
        case .fighterJet:
            sprite = createJetSprite()
        case .rocketPack:
            sprite = createRocketPackSprite()
        case .biplane:
            sprite = createBiplaneSprite()
        case .duck:
            sprite = createDuckSprite()
        case .eagle:
            sprite = createEagleSprite()
        case .f22Raptor:
            sprite = createF22RaptorSprite()
        case .dragon:
            sprite = createDragonSprite()
        case .mustangPlane:
            sprite = createMustangSprite()
        default:
            // Fallback to helicopter as a safe default
            sprite = createHelicopterSprite()
        }
        
        // Disable physics for menu displays if not explicitly enabled
        if !enablePhysics && sprite.physicsBody != nil {
            sprite.physicsBody = nil
        }
        
        return sprite
    }
    
    // These methods would be expanded to create proper sprites
    // Special sprite for the Map Default option
    private func createMapDefaultSprite(enablePhysics: Bool = false) -> SKSpriteNode {
        let container = SKSpriteNode(color: .clear, size: CGSize(width: 50, height: 30))
        container.name = "player"
        
        // Create a visual representation showing multiple aircraft silhouettes
        // Base shape - slightly transparent blue rectangle
        let baseShape = SKShapeNode(rectOf: CGSize(width: 40, height: 20), cornerRadius: 5)
        baseShape.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.5)
        baseShape.strokeColor = UIColor.white
        baseShape.lineWidth = 2
        baseShape.alpha = 0.8
        container.addChild(baseShape)
        
        // Add a map icon
        let mapIcon = SKLabelNode(text: "🗺️")
        mapIcon.fontSize = 15
        mapIcon.verticalAlignmentMode = .center
        mapIcon.horizontalAlignmentMode = .center
        mapIcon.position = CGPoint(x: -10, y: 0)
        container.addChild(mapIcon)
        
        // Add an aircraft icon
        let aircraftIcon = SKLabelNode(text: "✈️")
        aircraftIcon.fontSize = 15
        aircraftIcon.verticalAlignmentMode = .center
        aircraftIcon.horizontalAlignmentMode = .center
        aircraftIcon.position = CGPoint(x: 10, y: 0)
        container.addChild(aircraftIcon)
        
        // Add physics body only if enabled (for gameplay, not menus)
        if enablePhysics {
            let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 40, height: 20))
            physicsBody.isDynamic = true
            physicsBody.allowsRotation = false
            physicsBody.categoryBitMask = 0x1 << 0  // Player category
            physicsBody.contactTestBitMask = 0x1 << 1 | 0x1 << 2  // Obstacle and ground categories
            physicsBody.collisionBitMask = 0x1 << 1 | 0x1 << 2  // Obstacle and ground categories
            container.physicsBody = physicsBody
        }
        
        // Add a subtle animation to emphasize its special nature
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 0.95, duration: 0.5)
        ])
        container.run(SKAction.repeatForever(pulse))
        
        return container
    }
    
    private func createHelicopterSprite() -> SKSpriteNode {
        let helicopter = SKSpriteNode(color: .clear, size: CGSize(width: 50, height: 30))
        helicopter.name = "player"
        
        // Create helicopter body (main part)
        let body = SKShapeNode(rectOf: CGSize(width: 40, height: 15), cornerRadius: 5)
        body.fillColor = UIColor(red: 0.2, green: 0.3, blue: 0.7, alpha: 1.0)
        body.strokeColor = UIColor.black
        body.name = "playerBody"
        helicopter.addChild(body)
        
        // Create cockpit
        let cockpit = SKShapeNode(rectOf: CGSize(width: 15, height: 10), cornerRadius: 5)
        cockpit.fillColor = UIColor(red: 0.1, green: 0.7, blue: 0.9, alpha: 0.8)
        cockpit.strokeColor = UIColor.black
        cockpit.position = CGPoint(x: 5, y: 5)
        cockpit.name = "playerCockpit"
        helicopter.addChild(cockpit)
        
        // Create tail
        let tail = SKShapeNode(rectOf: CGSize(width: 20, height: 5), cornerRadius: 2)
        tail.fillColor = UIColor(red: 0.2, green: 0.3, blue: 0.7, alpha: 1.0)
        tail.strokeColor = UIColor.black
        tail.position = CGPoint(x: -20, y: 0)
        tail.name = "playerTail"
        helicopter.addChild(tail)
        
        // Create tail fin
        let tailFin = SKShapeNode(rectOf: CGSize(width: 5, height: 10), cornerRadius: 0)
        tailFin.fillColor = UIColor(red: 0.2, green: 0.3, blue: 0.7, alpha: 1.0)
        tailFin.strokeColor = UIColor.black
        tailFin.position = CGPoint(x: -25, y: 5)
        tailFin.name = "playerTailFin"
        helicopter.addChild(tailFin)
        
        // Create rotor
        let rotor = SKShapeNode(rectOf: CGSize(width: 50, height: 5), cornerRadius: 0)
        rotor.fillColor = UIColor.darkGray
        rotor.strokeColor = UIColor.black
        rotor.position = CGPoint(x: 0, y: 15)
        rotor.name = "playerRotor"
        helicopter.addChild(rotor)
        
        // Animate rotor
        let rotateAction = SKAction.rotate(byAngle: 2 * .pi, duration: 0.1)
        let repeatAction = SKAction.repeatForever(rotateAction)
        rotor.run(repeatAction)
        
        // Physics body for the helicopter
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 40, height: 15))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = 1 // Will be replaced by GameScene's actual masks
        physicsBody.contactTestBitMask = 2 | 4 | 8 // For obstacles, score, and powerups
        physicsBody.collisionBitMask = 2 // Only collide with obstacles
        helicopter.physicsBody = physicsBody
        
        return helicopter
    }
    
    private func createJetSprite() -> SKSpriteNode {
        let jet = SKSpriteNode(color: .clear, size: CGSize(width: 60, height: 20))
        jet.name = "player"
        
        // Create jet body
        let body = SKShapeNode(rectOf: CGSize(width: 50, height: 10), cornerRadius: 5)
        body.fillColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
        body.strokeColor = UIColor.black
        body.name = "playerBody"
        jet.addChild(body)
        
        // Create cockpit
        let cockpit = SKShapeNode(rectOf: CGSize(width: 12, height: 6), cornerRadius: 3)
        cockpit.fillColor = UIColor(red: 0.1, green: 0.7, blue: 0.9, alpha: 0.8)
        cockpit.strokeColor = UIColor.black
        cockpit.position = CGPoint(x: 10, y: 5)
        cockpit.name = "playerCockpit"
        jet.addChild(cockpit)
        
        // Create wings
        let wings = SKShapeNode(rectOf: CGSize(width: 30, height: 3), cornerRadius: 1)
        wings.fillColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
        wings.strokeColor = UIColor.black
        wings.position = CGPoint(x: 0, y: 0)
        wings.name = "playerWings"
        jet.addChild(wings)
        
        // Create tail fin
        let tailFin = SKShapeNode(rectOf: CGSize(width: 5, height: 10), cornerRadius: 0)
        tailFin.fillColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
        tailFin.strokeColor = UIColor.black
        tailFin.position = CGPoint(x: -20, y: 5)
        tailFin.name = "playerTailFin"
        jet.addChild(tailFin)
        
        // Create afterburner effect
        let afterburner = SKShapeNode(rectOf: CGSize(width: 10, height: 5), cornerRadius: 2.5)
        afterburner.fillColor = UIColor.orange
        afterburner.strokeColor = UIColor.red
        afterburner.position = CGPoint(x: -30, y: 0)
        afterburner.name = "playerAfterburner"
        
        // Animate afterburner
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        afterburner.run(repeatForever)
        
        jet.addChild(afterburner)
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 10))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = 1 // Will be replaced by GameScene's actual masks
        physicsBody.contactTestBitMask = 2 | 4 | 8 // For obstacles, score, and powerups
        physicsBody.collisionBitMask = 2 // Only collide with obstacles
        jet.physicsBody = physicsBody
        
        return jet
    }
    
    private func createRocketPackSprite() -> SKSpriteNode {
        let rocketPack = SKSpriteNode(color: .clear, size: CGSize(width: 30, height: 40))
        rocketPack.name = "player"
        
        // Create person body
        let body = SKShapeNode(rectOf: CGSize(width: 15, height: 30), cornerRadius: 5)
        body.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        body.strokeColor = UIColor.black
        body.name = "playerBody"
        rocketPack.addChild(body)
        
        // Create head
        let head = SKShapeNode(circleOfRadius: 8)
        head.fillColor = UIColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1.0)
        head.strokeColor = UIColor.black
        head.position = CGPoint(x: 0, y: 20)
        head.name = "playerHead"
        rocketPack.addChild(head)
        
        // Create rocket pack
        let pack = SKShapeNode(rectOf: CGSize(width: 20, height: 15), cornerRadius: 3)
        pack.fillColor = UIColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 1.0)
        pack.strokeColor = UIColor.black
        pack.position = CGPoint(x: -5, y: 0)
        pack.name = "playerPack"
        rocketPack.addChild(pack)
        
        // Create flames
        let flames = SKShapeNode(rectOf: CGSize(width: 10, height: 15), cornerRadius: 5)
        flames.fillColor = UIColor.orange
        flames.strokeColor = UIColor.red
        flames.position = CGPoint(x: -5, y: -15)
        flames.name = "playerFlames"
        
        // Animate flames
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
        let scaleDown = SKAction.scale(to: 0.7, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        flames.run(repeatForever)
        
        rocketPack.addChild(flames)
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 15, height: 30))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = 1 // Will be replaced by GameScene's actual masks
        physicsBody.contactTestBitMask = 2 | 4 | 8 // For obstacles, score, and powerups
        physicsBody.collisionBitMask = 2 // Only collide with obstacles
        rocketPack.physicsBody = physicsBody
        
        return rocketPack
    }
    
        private func createF22RaptorSprite() -> SKSpriteNode {
        // Create a more pixelated-looking F-22 Raptor based on the reference image
        let raptor = SKSpriteNode(color: .clear, size: CGSize(width: 60, height: 20))
        raptor.name = "player"

        // Main body - dark gray color
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: -28, y: -2)) // Back left
        bodyPath.addLine(to: CGPoint(x: -24, y: -4)) // Bottom curve
        bodyPath.addLine(to: CGPoint(x: -8, y: -4)) // Bottom straight
        bodyPath.addLine(to: CGPoint(x: 15, y: 0)) // Nose point
        bodyPath.addLine(to: CGPoint(x: -8, y: 4)) // Top straight
        bodyPath.addLine(to: CGPoint(x: -24, y: 4)) // Top curve
        bodyPath.close()

        let body = SKShapeNode(path: bodyPath.cgPath)
        body.fillColor = UIColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0) // Stealth dark gray
        body.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0) // Darker outline
        body.lineWidth = 1.0
        body.name = "playerBody"
        raptor.addChild(body)

        // Wings - angular, pixelated style
        let wingsPath = UIBezierPath()
        // Left wing
        wingsPath.move(to: CGPoint(x: -10, y: 0)) // Wing root
        wingsPath.addLine(to: CGPoint(x: -20, y: 8)) // Wing tip back
        wingsPath.addLine(to: CGPoint(x: -12, y: 8)) // Wing middle
        wingsPath.addLine(to: CGPoint(x: 0, y: 3)) // Wing front
        wingsPath.addLine(to: CGPoint(x: -10, y: 0)) // Back to root
        
        // Right wing - mirrored
        wingsPath.move(to: CGPoint(x: -10, y: 0)) // Wing root
        wingsPath.addLine(to: CGPoint(x: -20, y: -8)) // Wing tip back
        wingsPath.addLine(to: CGPoint(x: -12, y: -8)) // Wing middle
        wingsPath.addLine(to: CGPoint(x: 0, y: -3)) // Wing front
        wingsPath.addLine(to: CGPoint(x: -10, y: 0)) // Back to root

        let wings = SKShapeNode(path: wingsPath.cgPath)
        wings.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0) // Slightly lighter than body
        wings.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0) // Darker outline
        wings.lineWidth = 1.0
        wings.name = "playerWings"
        raptor.addChild(wings)

        // Cockpit - blue tinted canopy
        let cockpitPath = UIBezierPath()
        cockpitPath.move(to: CGPoint(x: 0, y: 0)) // Front of cockpit
        cockpitPath.addLine(to: CGPoint(x: -6, y: 2)) // Top back
        cockpitPath.addLine(to: CGPoint(x: -12, y: 2)) // Back top
        cockpitPath.addLine(to: CGPoint(x: -12, y: -2)) // Back bottom
        cockpitPath.addLine(to: CGPoint(x: -6, y: -2)) // Bottom back
        cockpitPath.addLine(to: CGPoint(x: 0, y: 0)) // Back to front
        cockpitPath.close()

        let cockpit = SKShapeNode(path: cockpitPath.cgPath)
        cockpit.fillColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.8) // Blue tinted glass
        cockpit.strokeColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // Dark outline
        cockpit.lineWidth = 1.0
        cockpit.position = CGPoint(x: 8, y: 0) // Position near front
        cockpit.name = "playerCockpit"
        raptor.addChild(cockpit)

        // Tail fins - angular pixelated style
        let tailPath = UIBezierPath()
        // Left tail
        tailPath.move(to: CGPoint(x: -20, y: 2)) // Tail base
        tailPath.addLine(to: CGPoint(x: -25, y: 8)) // Tail top
        tailPath.addLine(to: CGPoint(x: -28, y: 8)) // Tail back
        tailPath.addLine(to: CGPoint(x: -28, y: 2)) // Back to base
        tailPath.close()
        
        // Right tail
        tailPath.move(to: CGPoint(x: -20, y: -2)) // Tail base
        tailPath.addLine(to: CGPoint(x: -25, y: -8)) // Tail top
        tailPath.addLine(to: CGPoint(x: -28, y: -8)) // Tail back
        tailPath.addLine(to: CGPoint(x: -28, y: -2)) // Back to base
        tailPath.close()

        let tails = SKShapeNode(path: tailPath.cgPath)
        tails.fillColor = UIColor(red: 0.27, green: 0.27, blue: 0.32, alpha: 1.0) // Slightly different than body
        tails.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0) // Darker outline
        tails.lineWidth = 1.0
        tails.name = "playerTails"
        raptor.addChild(tails)

        // Exhaust nozzles
        let nozzlePath = UIBezierPath()
        nozzlePath.move(to: CGPoint(x: -28, y: 2)) // Top left
        nozzlePath.addLine(to: CGPoint(x: -30, y: 2)) // Top right
        nozzlePath.addLine(to: CGPoint(x: -30, y: -2)) // Bottom right
        nozzlePath.addLine(to: CGPoint(x: -28, y: -2)) // Bottom left
        nozzlePath.close()

        let nozzles = SKShapeNode(path: nozzlePath.cgPath)
        nozzles.fillColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Dark exhaust
        nozzles.strokeColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // Almost black
        nozzles.lineWidth = 1.0
        nozzles.name = "playerNozzles"
        raptor.addChild(nozzles)

        // Afterburner effects
        let afterburnerPath = UIBezierPath()
        afterburnerPath.move(to: CGPoint(x: -30, y: 1)) // Top left
        afterburnerPath.addLine(to: CGPoint(x: -38, y: 0)) // Tip
        afterburnerPath.addLine(to: CGPoint(x: -30, y: -1)) // Bottom left
        afterburnerPath.close()

        let afterburner = SKShapeNode(path: afterburnerPath.cgPath)
        afterburner.fillColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.8) // Orange flame
        afterburner.strokeColor = UIColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.6) // Red-orange outline
        afterburner.lineWidth = 0.5
        afterburner.name = "playerAfterburner"

        // Create a shorter inner flame
        let innerFlamePath = UIBezierPath()
        innerFlamePath.move(to: CGPoint(x: -30, y: 0.6)) // Top left
        innerFlamePath.addLine(to: CGPoint(x: -35, y: 0)) // Tip
        innerFlamePath.addLine(to: CGPoint(x: -30, y: -0.6)) // Bottom left
        innerFlamePath.close()

        let innerFlame = SKShapeNode(path: innerFlamePath.cgPath)
        innerFlame.fillColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9) // Yellow core
        innerFlame.strokeColor = UIColor.clear
        innerFlame.name = "innerFlame"
        afterburner.addChild(innerFlame)

        // Animate afterburner
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.05)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.05)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        afterburner.run(repeatForever)
        
        // Slight color pulsing for inner flame
        let colorChange = SKAction.sequence([
            SKAction.colorize(with: .yellow, colorBlendFactor: 0.7, duration: 0.1),
            SKAction.colorize(with: .orange, colorBlendFactor: 0.3, duration: 0.1)
        ])
        let colorRepeat = SKAction.repeatForever(colorChange)
        innerFlame.run(colorRepeat)

        raptor.addChild(afterburner)

        // Add detail lines to show panel sections on the aircraft
        let detailsPath = UIBezierPath()
        // Body panel lines
        detailsPath.move(to: CGPoint(x: -16, y: 1))
        detailsPath.addLine(to: CGPoint(x: -16, y: -1))
        detailsPath.move(to: CGPoint(x: -4, y: 2))
        detailsPath.addLine(to: CGPoint(x: -4, y: -2))
        
        let details = SKShapeNode(path: detailsPath.cgPath)
        details.strokeColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.7)
        details.lineWidth = 0.5
        raptor.addChild(details)

        // Physics body - adjust to match visual shape
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 16))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = 1 // Will be replaced by GameScene's actual masks
        physicsBody.contactTestBitMask = 2 | 4 | 8 // For obstacles, score, and powerups
        physicsBody.collisionBitMask = 2 // Only collide with obstacles
        raptor.physicsBody = physicsBody

        return raptor
    }
    
    // Implementation for the biplane aircraft
    private func createBiplaneSprite() -> SKSpriteNode {
        // For now, create a simple biplane representation
        let biplane = SKSpriteNode(color: .clear, size: CGSize(width: 50, height: 35))
        biplane.name = "player"
        
        // Simple biplane body
        let body = SKShapeNode(rectOf: CGSize(width: 30, height: 10), cornerRadius: 3)
        body.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0) // Brown wood color
        body.strokeColor = UIColor.black
        body.name = "playerBody"
        biplane.addChild(body)
        
        // Simple wings (two sets for biplane)
        let topWing = SKShapeNode(rectOf: CGSize(width: 45, height: 5), cornerRadius: 2)
        topWing.fillColor = UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)
        topWing.strokeColor = UIColor.black
        topWing.position = CGPoint(x: 0, y: 10)
        biplane.addChild(topWing)
        
        let bottomWing = SKShapeNode(rectOf: CGSize(width: 45, height: 5), cornerRadius: 2)
        bottomWing.fillColor = UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)
        bottomWing.strokeColor = UIColor.black
        bottomWing.position = CGPoint(x: 0, y: -5)
        biplane.addChild(bottomWing)
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 20))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.categoryBitMask = 0x1 << 0
        physicsBody.contactTestBitMask = 0x1 << 1 | 0x1 << 2
        physicsBody.collisionBitMask = 0x1 << 1 | 0x1 << 2
        biplane.physicsBody = physicsBody
        
        return biplane
    }
    
    // Implementation for the duck aircraft
    private func createDuckSprite() -> SKSpriteNode {
        // Simple duck sprite
        let duck = SKSpriteNode(color: .clear, size: CGSize(width: 40, height: 35))
        duck.name = "player"
        
        // Duck body
        let body = SKShapeNode(ellipseOf: CGSize(width: 30, height: 20))
        body.fillColor = UIColor.yellow
        body.strokeColor = UIColor.black
        duck.addChild(body)
        
        // Duck head
        let head = SKShapeNode(circleOfRadius: 12)
        head.fillColor = UIColor.yellow
        head.strokeColor = UIColor.black
        head.position = CGPoint(x: 15, y: 5)
        duck.addChild(head)
        
        // Duck bill
        let bill = SKShapeNode(rectOf: CGSize(width: 12, height: 8), cornerRadius: 2)
        bill.fillColor = UIColor.orange
        bill.strokeColor = UIColor.black
        bill.position = CGPoint(x: 25, y: 5)
        duck.addChild(bill)
        
        // Physics body
        let physicsBody = SKPhysicsBody(circleOfRadius: 17)
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.categoryBitMask = 0x1 << 0
        physicsBody.contactTestBitMask = 0x1 << 1 | 0x1 << 2
        physicsBody.collisionBitMask = 0x1 << 1 | 0x1 << 2
        duck.physicsBody = physicsBody
        
        return duck
    }
    
    // Implementation for the eagle aircraft
    private func createEagleSprite() -> SKSpriteNode {
        // Simple eagle sprite
        let eagle = SKSpriteNode(color: .clear, size: CGSize(width: 45, height: 30))
        eagle.name = "player"
        
        // Eagle body
        let body = SKShapeNode(ellipseOf: CGSize(width: 25, height: 15))
        body.fillColor = UIColor.brown
        body.strokeColor = UIColor.black
        eagle.addChild(body)
        
        // Eagle wings
        let wings = SKShapeNode(rectOf: CGSize(width: 45, height: 8), cornerRadius: 2)
        wings.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1.0)
        wings.strokeColor = UIColor.black
        wings.position = CGPoint(x: 0, y: 0)
        eagle.addChild(wings)
        
        // Eagle head
        let head = SKShapeNode(circleOfRadius: 8)
        head.fillColor = UIColor.white
        head.strokeColor = UIColor.black
        head.position = CGPoint(x: 15, y: 5)
        eagle.addChild(head)
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 15))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.categoryBitMask = 0x1 << 0
        physicsBody.contactTestBitMask = 0x1 << 1 | 0x1 << 2
        physicsBody.collisionBitMask = 0x1 << 1 | 0x1 << 2
        eagle.physicsBody = physicsBody
        
        return eagle
    }
    
    // Implementation for the dragon aircraft
    private func createDragonSprite() -> SKSpriteNode {
        // Simple dragon sprite
        let dragon = SKSpriteNode(color: .clear, size: CGSize(width: 50, height: 35))
        dragon.name = "player"
        
        // Dragon body
        let body = SKShapeNode(ellipseOf: CGSize(width: 35, height: 20))
        body.fillColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0) // Green
        body.strokeColor = UIColor.black
        dragon.addChild(body)
        
        // Dragon wings
        let wings = SKShapeNode(rectOf: CGSize(width: 40, height: 15), cornerRadius: 5)
        wings.fillColor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 0.7)
        wings.strokeColor = UIColor.black
        wings.position = CGPoint(x: -5, y: 5)
        dragon.addChild(wings)
        
        // Dragon head
        let head = SKShapeNode(rectOf: CGSize(width: 20, height: 15), cornerRadius: 5)
        head.fillColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        head.strokeColor = UIColor.black
        head.position = CGPoint(x: 15, y: 0)
        dragon.addChild(head)
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 35, height: 20))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.categoryBitMask = 0x1 << 0
        physicsBody.contactTestBitMask = 0x1 << 1 | 0x1 << 2
        physicsBody.collisionBitMask = 0x1 << 1 | 0x1 << 2
        dragon.physicsBody = physicsBody
        
        return dragon
    }
    
    // Implementation for the mustang aircraft
    private func createMustangSprite() -> SKSpriteNode {
        // Simple mustang plane sprite
        let mustang = SKSpriteNode(color: .clear, size: CGSize(width: 55, height: 25))
        mustang.name = "player"
        
        // Mustang body
        let body = SKShapeNode(rectOf: CGSize(width: 40, height: 10), cornerRadius: 5)
        body.fillColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0) // Silver
        body.strokeColor = UIColor.black
        mustang.addChild(body)
        
        // Mustang wings
        let wings = SKShapeNode(rectOf: CGSize(width: 30, height: 15), cornerRadius: 2)
        wings.fillColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        wings.strokeColor = UIColor.black
        wings.position = CGPoint(x: 0, y: 0)
        mustang.addChild(wings)
        
        // Tail
        let tail = SKShapeNode(rectOf: CGSize(width: 10, height: 15), cornerRadius: 2)
        tail.fillColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        tail.strokeColor = UIColor.black
        tail.position = CGPoint(x: -20, y: 0)
        mustang.addChild(tail)
        
        // Physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 40, height: 10))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.categoryBitMask = 0x1 << 0
        physicsBody.contactTestBitMask = 0x1 << 1 | 0x1 << 2
        physicsBody.collisionBitMask = 0x1 << 1 | 0x1 << 2
        mustang.physicsBody = physicsBody
        
        return mustang
    }
}