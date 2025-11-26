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
        case ufo
        case duck
        case dragon
        case f22Raptor // New F22 Raptor for Stargate Escape level
        case santaSleigh // Santa's sleigh with reindeer for Christmas level
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
                unlockCost: 1750, // Increased from 500
                isUnlocked: true,
                specialAbility: "None - Balanced starter craft"
            ),
            Aircraft(
                type: .fighterJet,
                name: "Sonic Jet",
                description: "Fast jet with sleek handling",
                speed: 1.5,
                size: CGSize(width: 60, height: 20), // Longer but thinner
                unlockCost: 8000, // Increased from 5000
                isUnlocked: false,
                specialAbility: "Afterburner - Temporary speed boost cooldown reduced by 50%"
            ),
            Aircraft(
                type: .rocketPack,
                name: "Rocket Man",
                description: "Personal jetpack with unique controls",
                speed: 1.2,
                size: CGSize(width: 30, height: 40), // Small but tall
                unlockCost: 5000, // Increased from 3000
                isUnlocked: false,
                specialAbility: "Hover - Briefly pause mid-air once per run"
            ),
            Aircraft(
                type: .mustangPlane,
                name: "Vintage Mustang",
                description: "Classic WWII fighter with style",
                speed: 1.1,
                size: CGSize(width: 55, height: 25),
                unlockCost: 8500, // Increased from 4000
                isUnlocked: false,
                specialAbility: "Barrel Roll - Invincibility during roll animation"
            ),
            Aircraft(
                type: .biplane,
                name: "Barnstormer",
                description: "Old-school biplane with charm",
                speed: 1.0,
                size: CGSize(width: 56, height: 34),
                unlockCost: 7500, // Increased from 2000
                isUnlocked: false,
                specialAbility: "Lucky Clover - Higher chance of power-up spawns"
            ),
            Aircraft(
                type: .eagle,
                name: "Mighty Eagle",
                description: "Majestic bird with natural flying ability",
                speed: 1.2,
                size: CGSize(width: 52, height: 32),
                unlockCost: 16000, // Increased from 10000
                isUnlocked: false,
                specialAbility: "Wind Rider - Less affected by obstacle patterns"
            ),
            Aircraft(
                type: .ufo,
                name: "Cosmo Disc",
                description: "Smooth hovering craft with perfect balance",
                speed: 1.1,
                size: CGSize(width: 56, height: 26),
                unlockCost: 20000, // Increased from 6000
                isUnlocked: false,
                specialAbility: "Tractor Beam - Attract nearby coins briefly"
            ),
            Aircraft(
                type: .duck,
                name: "Lucky Duck",
                description: "Quirky duck with surprising skills",
                speed: 0.8, // Slowest
                size: CGSize(width: 40, height: 35), // Small size helps compensate
                unlockCost: 16000, // Increased from 7500
                isUnlocked: false,
                specialAbility: "Water Landing - Survive one water crash per run"
            ),
            Aircraft(
                type: .dragon,
                name: "Fire Dragon",
                description: "Legendary creature with fiery breath",
                speed: 1.3,
                size: CGSize(width: 60, height: 40), // Largest
                unlockCost: 40000, // Increased from 25000, premium flagship character
                isUnlocked: false,
                specialAbility: "Fire Breath - Burn through one obstacle per run"
            ),
            Aircraft(
                type: .f22Raptor,
                name: "F-22 Raptor",
                description: "Advanced stealth tactical fighter with superior maneuverability",
                speed: 1.6, // Fastest aircraft
                size: CGSize(width: 60, height: 20), // Long and sleek
                unlockCost: 55000,
                isUnlocked: false,
                specialAbility: "Stealth Mode - Temporarily invisible to obstacles"
            ),
            Aircraft(
                type: .santaSleigh,
                name: "Santa's Sleigh",
                description: "Magical sleigh pulled by reindeer - perfect for delivering presents!",
                speed: 1.3, // Good speed for Santa
                size: CGSize(width: 80, height: 40), // Wider for sleigh + reindeer
                unlockCost: 45000, // Seasonal special
                isUnlocked: false,
                specialAbility: "Gift Drop - Collect presents for bonus points"
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
        case .ufo:
            sprite = createUfoSprite()
        case .f22Raptor:
            sprite = createF22RaptorSprite()
        case .dragon:
            sprite = createDragonSprite()
        case .mustangPlane:
            sprite = createMustangSprite()
        case .santaSleigh:
            sprite = createSantaSleighSprite()
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
    
    // MARK: - Santa's Sleigh Sprite (Christmas Special)
    private func createSantaSleighSprite() -> SKSpriteNode {
        // Create a detailed pixel-art style Santa sleigh with reindeer
        let sleighContainer = SKSpriteNode(color: .clear, size: CGSize(width: 90, height: 45))
        sleighContainer.name = "player"
        
        // ===== REINDEER (Front) =====
        let reindeerContainer = SKNode()
        reindeerContainer.position = CGPoint(x: 30, y: 5)
        
        // Lead Reindeer Body
        let reindeerBodyPath = UIBezierPath()
        reindeerBodyPath.move(to: CGPoint(x: 0, y: -4))
        reindeerBodyPath.addLine(to: CGPoint(x: 12, y: -3))
        reindeerBodyPath.addLine(to: CGPoint(x: 14, y: 0))
        reindeerBodyPath.addLine(to: CGPoint(x: 12, y: 3))
        reindeerBodyPath.addLine(to: CGPoint(x: 0, y: 4))
        reindeerBodyPath.addLine(to: CGPoint(x: -4, y: 2))
        reindeerBodyPath.addLine(to: CGPoint(x: -4, y: -2))
        reindeerBodyPath.close()
        
        let reindeerBody = SKShapeNode(path: reindeerBodyPath.cgPath)
        reindeerBody.fillColor = UIColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0) // Brown
        reindeerBody.strokeColor = UIColor(red: 0.35, green: 0.2, blue: 0.1, alpha: 1.0)
        reindeerBody.lineWidth = 1
        reindeerContainer.addChild(reindeerBody)
        
        // Reindeer Head
        let headPath = UIBezierPath(ovalIn: CGRect(x: 12, y: -3, width: 8, height: 6))
        let head = SKShapeNode(path: headPath.cgPath)
        head.fillColor = UIColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0)
        head.strokeColor = UIColor(red: 0.35, green: 0.2, blue: 0.1, alpha: 1.0)
        head.lineWidth = 1
        reindeerContainer.addChild(head)
        
        // Rudolph's Red Nose (glowing!)
        let nose = SKShapeNode(circleOfRadius: 2.5)
        nose.fillColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        nose.strokeColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        nose.lineWidth = 0.5
        nose.position = CGPoint(x: 22, y: 0)
        nose.name = "rudolphNose"
        reindeerContainer.addChild(nose)
        
        // Nose glow effect
        let noseGlow = SKShapeNode(circleOfRadius: 5)
        noseGlow.fillColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.4)
        noseGlow.strokeColor = .clear
        noseGlow.position = CGPoint(x: 22, y: 0)
        noseGlow.zPosition = -1
        reindeerContainer.addChild(noseGlow)
        
        // Animate nose glow
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.4),
            SKAction.fadeAlpha(to: 0.3, duration: 0.4)
        ])
        noseGlow.run(SKAction.repeatForever(glowPulse))
        
        // Antlers
        let antlerPath = UIBezierPath()
        // Left antler
        antlerPath.move(to: CGPoint(x: 16, y: 3))
        antlerPath.addLine(to: CGPoint(x: 14, y: 8))
        antlerPath.addLine(to: CGPoint(x: 12, y: 6))
        antlerPath.addLine(to: CGPoint(x: 14, y: 10))
        antlerPath.addLine(to: CGPoint(x: 16, y: 8))
        // Right antler
        antlerPath.move(to: CGPoint(x: 16, y: -3))
        antlerPath.addLine(to: CGPoint(x: 14, y: -8))
        antlerPath.addLine(to: CGPoint(x: 12, y: -6))
        antlerPath.addLine(to: CGPoint(x: 14, y: -10))
        antlerPath.addLine(to: CGPoint(x: 16, y: -8))
        
        let antlers = SKShapeNode(path: antlerPath.cgPath)
        antlers.strokeColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        antlers.lineWidth = 2
        antlers.lineCap = .round
        reindeerContainer.addChild(antlers)
        
        // Reindeer Legs (animated running)
        let legsContainer = SKNode()
        legsContainer.position = CGPoint(x: 4, y: -6)
        
        let frontLeg = SKShapeNode(rectOf: CGSize(width: 2, height: 6))
        frontLeg.fillColor = UIColor(red: 0.45, green: 0.28, blue: 0.15, alpha: 1.0)
        frontLeg.strokeColor = .clear
        frontLeg.position = CGPoint(x: 4, y: 0)
        frontLeg.name = "frontLeg"
        legsContainer.addChild(frontLeg)
        
        let backLeg = SKShapeNode(rectOf: CGSize(width: 2, height: 6))
        backLeg.fillColor = UIColor(red: 0.45, green: 0.28, blue: 0.15, alpha: 1.0)
        backLeg.strokeColor = .clear
        backLeg.position = CGPoint(x: -4, y: 0)
        backLeg.name = "backLeg"
        legsContainer.addChild(backLeg)
        
        reindeerContainer.addChild(legsContainer)
        
        // Animate reindeer legs (running motion)
        let legForward = SKAction.rotate(byAngle: 0.3, duration: 0.15)
        let legBack = SKAction.rotate(byAngle: -0.3, duration: 0.15)
        let legSequence = SKAction.sequence([legForward, legBack])
        frontLeg.run(SKAction.repeatForever(legSequence))
        
        let legBackSequence = SKAction.sequence([legBack, legForward])
        backLeg.run(SKAction.repeatForever(legBackSequence))
        
        // Second Reindeer (slightly behind)
        let reindeer2 = reindeerContainer.copy() as! SKNode
        reindeer2.position = CGPoint(x: 15, y: -2)
        reindeer2.setScale(0.85)
        reindeer2.alpha = 0.9
        sleighContainer.addChild(reindeer2)
        
        sleighContainer.addChild(reindeerContainer)
        
        // ===== REINS =====
        let reinsPath = UIBezierPath()
        reinsPath.move(to: CGPoint(x: -8, y: 2))
        reinsPath.addQuadCurve(to: CGPoint(x: 25, y: 5), controlPoint: CGPoint(x: 10, y: 10))
        reinsPath.move(to: CGPoint(x: -8, y: -2))
        reinsPath.addQuadCurve(to: CGPoint(x: 25, y: -5), controlPoint: CGPoint(x: 10, y: -8))
        
        let reins = SKShapeNode(path: reinsPath.cgPath)
        reins.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0)
        reins.lineWidth = 1.5
        sleighContainer.addChild(reins)
        
        // ===== SLEIGH =====
        let sleighPath = UIBezierPath()
        // Sleigh body - curved bottom
        sleighPath.move(to: CGPoint(x: -35, y: -10))
        sleighPath.addQuadCurve(to: CGPoint(x: -10, y: -15), controlPoint: CGPoint(x: -25, y: -18))
        sleighPath.addLine(to: CGPoint(x: 5, y: -15))
        sleighPath.addQuadCurve(to: CGPoint(x: 10, y: -8), controlPoint: CGPoint(x: 10, y: -15))
        sleighPath.addLine(to: CGPoint(x: 10, y: 5))
        sleighPath.addLine(to: CGPoint(x: -35, y: 5))
        sleighPath.close()
        
        let sleigh = SKShapeNode(path: sleighPath.cgPath)
        sleigh.fillColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0) // Christmas red
        sleigh.strokeColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        sleigh.lineWidth = 2
        sleighContainer.addChild(sleigh)
        
        // Sleigh gold trim
        let trimPath = UIBezierPath()
        trimPath.move(to: CGPoint(x: -35, y: 5))
        trimPath.addLine(to: CGPoint(x: 10, y: 5))
        trimPath.move(to: CGPoint(x: -35, y: -2))
        trimPath.addLine(to: CGPoint(x: 10, y: -2))
        
        let trim = SKShapeNode(path: trimPath.cgPath)
        trim.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        trim.lineWidth = 2
        sleighContainer.addChild(trim)
        
        // Sleigh runner (curved ski)
        let runnerPath = UIBezierPath()
        runnerPath.move(to: CGPoint(x: -40, y: -12))
        runnerPath.addQuadCurve(to: CGPoint(x: 5, y: -18), controlPoint: CGPoint(x: -20, y: -20))
        runnerPath.addQuadCurve(to: CGPoint(x: 12, y: -14), controlPoint: CGPoint(x: 10, y: -18))
        
        let runner = SKShapeNode(path: runnerPath.cgPath)
        runner.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        runner.lineWidth = 3
        runner.lineCap = .round
        sleighContainer.addChild(runner)
        
        // ===== SANTA =====
        let santaContainer = SKNode()
        santaContainer.position = CGPoint(x: -15, y: 5)
        
        // Santa's body (red coat)
        let bodyPath = UIBezierPath(roundedRect: CGRect(x: -8, y: -5, width: 16, height: 14), cornerRadius: 3)
        let santaBody = SKShapeNode(path: bodyPath.cgPath)
        santaBody.fillColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        santaBody.strokeColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        santaBody.lineWidth = 1
        santaContainer.addChild(santaBody)
        
        // White fur trim on coat
        let furTrimPath = UIBezierPath(rect: CGRect(x: -8, y: 7, width: 16, height: 3))
        let furTrim = SKShapeNode(path: furTrimPath.cgPath)
        furTrim.fillColor = .white
        furTrim.strokeColor = UIColor(white: 0.9, alpha: 1.0)
        furTrim.lineWidth = 0.5
        santaContainer.addChild(furTrim)
        
        // Belt
        let belt = SKShapeNode(rectOf: CGSize(width: 16, height: 3))
        belt.fillColor = .black
        belt.strokeColor = .clear
        belt.position = CGPoint(x: 0, y: 0)
        santaContainer.addChild(belt)
        
        // Belt buckle
        let buckle = SKShapeNode(rectOf: CGSize(width: 4, height: 3))
        buckle.fillColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        buckle.strokeColor = .clear
        buckle.position = CGPoint(x: 0, y: 0)
        santaContainer.addChild(buckle)
        
        // Santa's head
        let santaHead = SKShapeNode(circleOfRadius: 6)
        santaHead.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.75, alpha: 1.0) // Skin tone
        santaHead.strokeColor = UIColor(red: 0.9, green: 0.75, blue: 0.65, alpha: 1.0)
        santaHead.lineWidth = 1
        santaHead.position = CGPoint(x: 0, y: 16)
        santaContainer.addChild(santaHead)
        
        // Santa's hat
        let hatPath = UIBezierPath()
        hatPath.move(to: CGPoint(x: -6, y: 20))
        hatPath.addLine(to: CGPoint(x: 0, y: 30))
        hatPath.addLine(to: CGPoint(x: 6, y: 20))
        hatPath.close()
        
        let hat = SKShapeNode(path: hatPath.cgPath)
        hat.fillColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        hat.strokeColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        hat.lineWidth = 1
        santaContainer.addChild(hat)
        
        // Hat pom-pom
        let pomPom = SKShapeNode(circleOfRadius: 3)
        pomPom.fillColor = .white
        pomPom.strokeColor = UIColor(white: 0.9, alpha: 1.0)
        pomPom.position = CGPoint(x: 0, y: 30)
        santaContainer.addChild(pomPom)
        
        // Hat fur trim
        let hatFur = SKShapeNode(rectOf: CGSize(width: 14, height: 3))
        hatFur.fillColor = .white
        hatFur.strokeColor = UIColor(white: 0.9, alpha: 1.0)
        hatFur.position = CGPoint(x: 0, y: 20)
        santaContainer.addChild(hatFur)
        
        // Beard
        let beardPath = UIBezierPath()
        beardPath.move(to: CGPoint(x: -5, y: 12))
        beardPath.addQuadCurve(to: CGPoint(x: 0, y: 6), controlPoint: CGPoint(x: -6, y: 8))
        beardPath.addQuadCurve(to: CGPoint(x: 5, y: 12), controlPoint: CGPoint(x: 6, y: 8))
        beardPath.close()
        
        let beard = SKShapeNode(path: beardPath.cgPath)
        beard.fillColor = .white
        beard.strokeColor = UIColor(white: 0.9, alpha: 1.0)
        beard.lineWidth = 0.5
        santaContainer.addChild(beard)
        
        // Santa's arm (holding reins)
        let arm = SKShapeNode(rectOf: CGSize(width: 12, height: 4), cornerRadius: 2)
        arm.fillColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        arm.strokeColor = .clear
        arm.position = CGPoint(x: 10, y: 4)
        arm.zRotation = -0.3
        santaContainer.addChild(arm)
        
        sleighContainer.addChild(santaContainer)
        
        // ===== GIFT SACK =====
        let sackPath = UIBezierPath(ovalIn: CGRect(x: -32, y: -8, width: 14, height: 18))
        let sack = SKShapeNode(path: sackPath.cgPath)
        sack.fillColor = UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0) // Brown sack
        sack.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0)
        sack.lineWidth = 1
        sleighContainer.addChild(sack)
        
        // Gifts peeking out
        let gift1 = SKShapeNode(rectOf: CGSize(width: 5, height: 5))
        gift1.fillColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0) // Green gift
        gift1.strokeColor = .red
        gift1.lineWidth = 1
        gift1.position = CGPoint(x: -28, y: 8)
        sleighContainer.addChild(gift1)
        
        let gift2 = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
        gift2.fillColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0) // Blue gift
        gift2.strokeColor = .yellow
        gift2.lineWidth = 1
        gift2.position = CGPoint(x: -22, y: 6)
        sleighContainer.addChild(gift2)
        
        // ===== SPARKLE TRAIL EFFECT =====
        let sparkleEmitter = SKNode()
        sparkleEmitter.position = CGPoint(x: -40, y: -5)
        sparkleEmitter.name = "sparkleTrail"
        
        // Create sparkle particles
        for i in 0..<5 {
            let sparkle = SKShapeNode(circleOfRadius: 2)
            sparkle.fillColor = UIColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 0.8)
            sparkle.strokeColor = .clear
            sparkle.position = CGPoint(x: CGFloat(-i * 8), y: CGFloat.random(in: -5...5))
            sparkle.alpha = CGFloat(1.0 - Double(i) * 0.2)
            
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.2),
                SKAction.fadeAlpha(to: 1.0, duration: 0.2)
            ])
            sparkle.run(SKAction.repeatForever(twinkle))
            
            sparkleEmitter.addChild(sparkle)
        }
        sleighContainer.addChild(sparkleEmitter)
        
        // ===== PHYSICS BODY =====
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 70, height: 35))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.density = 0.3 // Lower density so it moves more like lighter aircraft
        physicsBody.categoryBitMask = 1
        physicsBody.contactTestBitMask = 2 | 4 | 8
        physicsBody.collisionBitMask = 2
        sleighContainer.physicsBody = physicsBody
        
        return sleighContainer
    }
    
    // Implementation for the biplane aircraft
    private func createBiplaneSprite() -> SKSpriteNode {
        let plane = SKSpriteNode(color: .clear, size: CGSize(width: 56, height: 34))
        plane.name = "player"
        
        // Fuselage
        let fuselage = SKShapeNode(rectOf: CGSize(width: 44, height: 12), cornerRadius: 4)
        fuselage.fillColor = UIColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1.0)
        fuselage.strokeColor = UIColor(red: 0.6, green: 0.1, blue: 0.08, alpha: 1.0)
        fuselage.position = CGPoint(x: 2, y: 0)
        plane.addChild(fuselage)
        
        // Engine cowl
        let cowl = SKShapeNode(circleOfRadius: 8)
        cowl.fillColor = UIColor(white: 0.85, alpha: 1.0)
        cowl.strokeColor = UIColor(white: 0.6, alpha: 1.0)
        cowl.position = CGPoint(x: 20, y: 0)
        plane.addChild(cowl)
        
        // Upper wing
        let upperWing = SKShapeNode(rectOf: CGSize(width: 40, height: 6), cornerRadius: 3)
        upperWing.fillColor = UIColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1.0)
        upperWing.strokeColor = fuselage.strokeColor
        upperWing.position = CGPoint(x: 0, y: 8)
        plane.addChild(upperWing)
        
        // Lower wing
        let lowerWing = SKShapeNode(rectOf: CGSize(width: 42, height: 6), cornerRadius: 3)
        lowerWing.fillColor = upperWing.fillColor
        lowerWing.strokeColor = fuselage.strokeColor
        lowerWing.position = CGPoint(x: -2, y: -8)
        plane.addChild(lowerWing)
        
        // Struts
        for x in [-10, 10] {
            let strut = SKShapeNode(rectOf: CGSize(width: 3, height: 14), cornerRadius: 1)
            strut.fillColor = UIColor(white: 0.3, alpha: 1.0)
            strut.strokeColor = .clear
            strut.position = CGPoint(x: x, y: 0)
            plane.addChild(strut)
        }
        
        // Tail and fin
        let tail = SKShapeNode(rectOf: CGSize(width: 12, height: 6), cornerRadius: 2)
        tail.fillColor = fuselage.fillColor
        tail.strokeColor = fuselage.strokeColor
        tail.position = CGPoint(x: -22, y: 3)
        plane.addChild(tail)
        
        // Propeller
        let prop = SKShapeNode(rectOf: CGSize(width: 2, height: 18), cornerRadius: 1)
        prop.fillColor = UIColor(white: 0.2, alpha: 1.0)
        prop.strokeColor = .clear
        prop.position = CGPoint(x: 28, y: 0)
        plane.addChild(prop)
        let spin = SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 0.06))
        prop.run(spin)
        
        // Physics
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 44, height: 14))
        body.isDynamic = true
        body.allowsRotation = false
        plane.physicsBody = body
        
        return plane
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
        let eagle = SKSpriteNode(color: .clear, size: CGSize(width: 52, height: 32))
        eagle.name = "player"
        
        // Body (brown)
        let body = SKShapeNode(ellipseOf: CGSize(width: 36, height: 20))
        body.fillColor = UIColor(red: 0.72, green: 0.55, blue: 0.35, alpha: 1.0)
        body.strokeColor = UIColor(red: 0.45, green: 0.35, blue: 0.2, alpha: 1.0)
        eagle.addChild(body)
        
        // Head (white)
        let head = SKShapeNode(ellipseOf: CGSize(width: 16, height: 14))
        head.fillColor = .white
        head.strokeColor = UIColor(white: 0.85, alpha: 1.0)
        head.position = CGPoint(x: 18, y: 2)
        eagle.addChild(head)
        
        // Beak (yellow)
        let beakPath = UIBezierPath()
        beakPath.move(to: CGPoint(x: 0, y: 0))
        beakPath.addLine(to: CGPoint(x: 10, y: 3))
        beakPath.addLine(to: CGPoint(x: 10, y: -3))
        beakPath.close()
        let beak = SKShapeNode(path: beakPath.cgPath)
        beak.fillColor = UIColor(red: 0.98, green: 0.8, blue: 0.2, alpha: 1.0)
        beak.strokeColor = UIColor(red: 0.8, green: 0.65, blue: 0.1, alpha: 1.0)
        beak.position = CGPoint(x: 24, y: 2)
        eagle.addChild(beak)
        
        // Eye
        let eye = SKShapeNode(circleOfRadius: 2.2)
        eye.fillColor = .black
        eye.strokeColor = .white
        eye.position = CGPoint(x: 20, y: 4)
        eagle.addChild(eye)
        
        // Wing (flapping)
        let wingPath = UIBezierPath(roundedRect: CGRect(x: -18, y: -6, width: 22, height: 12), cornerRadius: 6)
        let wing = SKShapeNode(path: wingPath.cgPath)
        wing.fillColor = body.fillColor
        wing.strokeColor = body.strokeColor
        wing.position = CGPoint(x: -4, y: 2)
        eagle.addChild(wing)
        let flap = SKAction.sequence([
            SKAction.rotate(byAngle: 0.18, duration: 0.18),
            SKAction.rotate(byAngle: -0.36, duration: 0.36),
            SKAction.rotate(byAngle: 0.18, duration: 0.18)
        ])
        wing.run(SKAction.repeatForever(flap))
        
        // Tail
        let tail = SKShapeNode()
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -20, y: 0))
        tailPath.addLine(to: CGPoint(x: -28, y: 5))
        tailPath.addLine(to: CGPoint(x: -28, y: -5))
        tailPath.close()
        tail.path = tailPath.cgPath
        tail.fillColor = body.fillColor
        tail.strokeColor = body.strokeColor
        eagle.addChild(tail)
        
        // Physics
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: 38, height: 18))
        pb.isDynamic = true
        pb.allowsRotation = false
        eagle.physicsBody = pb
        
        return eagle
    }

    private func createUfoSprite() -> SKSpriteNode {
        let ufo = SKSpriteNode(color: .clear, size: CGSize(width: 56, height: 26))
        ufo.name = "player"
        
        // Saucer base
        let base = SKShapeNode(ellipseOf: CGSize(width: 56, height: 18))
        base.fillColor = UIColor(white: 0.8, alpha: 1.0)
        base.strokeColor = UIColor(white: 0.5, alpha: 1.0)
        ufo.addChild(base)
        
        // Dome
        let dome = SKShapeNode(ellipseOf: CGSize(width: 28, height: 14))
        dome.fillColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.9)
        dome.strokeColor = UIColor(white: 0.85, alpha: 1.0)
        dome.position = CGPoint(x: 0, y: 6)
        ufo.addChild(dome)
        
        // Lights
        for x in stride(from: -20, through: 20, by: 10) {
            let light = SKShapeNode(circleOfRadius: 2.2)
            light.fillColor = UIColor.yellow
            light.strokeColor = .clear
            light.position = CGPoint(x: CGFloat(x), y: -2)
            base.addChild(light)
            let pulse = SKAction.sequence([SKAction.fadeAlpha(to: 0.4, duration: 0.4), SKAction.fadeAlpha(to: 1.0, duration: 0.4)])
            light.run(SKAction.repeatForever(pulse))
        }
        
        // Hover animation
        let hover = SKAction.sequence([SKAction.moveBy(x: 0, y: 4, duration: 0.6), SKAction.moveBy(x: 0, y: -4, duration: 0.6)])
        ufo.run(SKAction.repeatForever(hover))
        
        // Physics (approximate as rectangle for compatibility)
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 16))
        pb.isDynamic = true
        pb.allowsRotation = false
        ufo.physicsBody = pb
        
        return ufo
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