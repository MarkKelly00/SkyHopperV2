import SpriteKit
import UIKit

class CharacterManager {
    static let shared = CharacterManager()
    
    enum AircraftType: String, CaseIterable {
        case helicopter
        case fighterJet
        case rocketPack
        case mustangPlane
        case biplane
        case eagle
        case duck
        case dragon
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
    
    var selectedAircraft: AircraftType = .helicopter
    var unlockedAircraft: [AircraftType] = [.helicopter]
    
    var allAircraft: [Aircraft] = []
    
    private init() {
        setupAircraft()
    }
    
    private func setupAircraft() {
        allAircraft = [
            Aircraft(
                type: .helicopter,
                name: "Sky Chopper",
                description: "The classic helicopter with balanced stats",
                speed: 1.0,
                size: CGSize(width: 50, height: 30),
                unlockCost: 0, // Free starter
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
    func createAircraftSprite(for type: AircraftType) -> SKSpriteNode {
        switch type {
        case .helicopter:
            return createHelicopterSprite()
        case .fighterJet:
            return createJetSprite()
        case .rocketPack:
            return createRocketPackSprite()
        default:
            // Fallback to helicopter for now, extend later
            return createHelicopterSprite()
        }
    }
    
    // These methods would be expanded to create proper sprites
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
}