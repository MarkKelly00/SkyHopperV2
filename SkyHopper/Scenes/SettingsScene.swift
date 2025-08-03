import SpriteKit

class SettingsScene: SKScene {
    
    // Audio manager
    private let audioManager = AudioManager.shared
    
    // UI elements
    private var backButton: SKShapeNode!
    private var musicToggle: SKShapeNode!
    private var soundToggle: SKShapeNode!
    private var privacyButton: SKShapeNode!
    private var creditsButton: SKShapeNode!
    private var resetButton: SKShapeNode!
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
    }
    
    private func setupScene() {
        // Set background color
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Add background elements
        addCloudsBackground()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(text: "Settings")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 40
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        // Back button
        createBackButton()
        
        // Create settings options
        createSettingsOptions()
    }
    
    private func createBackButton() {
        backButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        backButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        backButton.strokeColor = .white
        backButton.lineWidth = 2
        backButton.position = CGPoint(x: 80, y: size.height - 40)
        backButton.zPosition = 10
        backButton.name = "backButton"
        
        let backLabel = SKLabelNode(text: "Back")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 20
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backLabel.horizontalAlignmentMode = .center
        backLabel.zPosition = 1
        backButton.addChild(backLabel)
        
        addChild(backButton)
    }
    
    private func createSettingsOptions() {
        // Sound Settings Section
        let soundLabel = SKLabelNode(text: "Sound Settings")
        soundLabel.fontName = "AvenirNext-Bold"
        soundLabel.fontSize = 28
        soundLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        soundLabel.zPosition = 10
        addChild(soundLabel)
        
        // Music toggle
        let musicLabel = SKLabelNode(text: "Music")
        musicLabel.fontName = "AvenirNext-Medium"
        musicLabel.fontSize = 22
        musicLabel.position = CGPoint(x: size.width / 4, y: size.height - 210)
        musicLabel.zPosition = 10
        addChild(musicLabel)
        
        // Pass a default value here since we can't access private property directly
        musicToggle = createToggleSwitch(position: CGPoint(x: size.width * 3 / 4, y: size.height - 210), isOn: true)
        musicToggle.name = "musicToggle"
        addChild(musicToggle)
        
        // Sound effects toggle
        let effectsLabel = SKLabelNode(text: "Sound Effects")
        effectsLabel.fontName = "AvenirNext-Medium"
        effectsLabel.fontSize = 22
        effectsLabel.position = CGPoint(x: size.width / 4, y: size.height - 260)
        effectsLabel.zPosition = 10
        addChild(effectsLabel)
        
        // Pass a default value here since we can't access private property directly
        soundToggle = createToggleSwitch(position: CGPoint(x: size.width * 3 / 4, y: size.height - 260), isOn: true)
        soundToggle.name = "soundToggle"
        addChild(soundToggle)
        
        // Other Options Section
        let otherLabel = SKLabelNode(text: "Other Options")
        otherLabel.fontName = "AvenirNext-Bold"
        otherLabel.fontSize = 28
        otherLabel.position = CGPoint(x: size.width / 2, y: size.height - 340)
        otherLabel.zPosition = 10
        addChild(otherLabel)
        
        // Privacy Policy
        privacyButton = createButton(title: "Privacy Policy", position: CGPoint(x: size.width / 2, y: size.height - 400))
        privacyButton.name = "privacyButton"
        addChild(privacyButton)
        
        // Credits
        creditsButton = createButton(title: "Credits", position: CGPoint(x: size.width / 2, y: size.height - 470))
        creditsButton.name = "creditsButton"
        addChild(creditsButton)
        
        // Reset Game Data
        resetButton = createButton(
            title: "Reset Game Data", 
            position: CGPoint(x: size.width / 2, y: size.height - 570),
            color: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        )
        resetButton.name = "resetButton"
        addChild(resetButton)
    }
    
    private func createToggleSwitch(position: CGPoint, isOn: Bool) -> SKShapeNode {
        let switchWidth: CGFloat = 80
        let switchHeight: CGFloat = 40
        
        let containerNode = SKShapeNode(rectOf: CGSize(width: switchWidth, height: switchHeight), cornerRadius: switchHeight / 2)
        containerNode.fillColor = isOn ? .green : .gray
        containerNode.strokeColor = .white
        containerNode.lineWidth = 2
        containerNode.position = position
        containerNode.zPosition = 10
        
        let knobSize = switchHeight - 8
        let knob = SKShapeNode(circleOfRadius: knobSize / 2)
        knob.fillColor = .white
        knob.strokeColor = .clear
        knob.position = CGPoint(x: isOn ? switchWidth/2 - knobSize/2 - 4 : -switchWidth/2 + knobSize/2 + 4, y: 0)
        knob.zPosition = 1
        knob.name = "toggleKnob"
        containerNode.addChild(knob)
        
        return containerNode
    }
    
    private func createButton(title: String, position: CGPoint, color: UIColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: 250, height: 50), cornerRadius: 10)
        button.fillColor = color
        button.strokeColor = .white
        button.lineWidth = 2
        button.position = position
        button.zPosition = 10
        
        let label = SKLabelNode(text: title)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        button.addChild(label)
        
        return button
    }
    
    // MARK: - Settings Actions
    
    private func toggleMusic() {
        // Use the toggleMusic method instead of accessing private property
        let newState = musicToggle.fillColor == .green ? false : true
        audioManager.toggleMusic(!newState)
        
        // Update toggle appearance
        updateToggleSwitch(musicToggle, isOn: !newState)
        
        // Show feedback
        showMessage(!newState ? "Music Enabled" : "Music Disabled")
    }
    
    private func toggleSound() {
        // Use the toggleEffects method instead of accessing private property
        let newState = soundToggle.fillColor == .green ? false : true
        audioManager.toggleEffects(!newState)
        
        // Update toggle appearance
        updateToggleSwitch(soundToggle, isOn: !newState)
        
        // Show feedback
        showMessage(!newState ? "Sound Effects Enabled" : "Sound Effects Disabled")
    }
    
    private func updateToggleSwitch(_ toggleSwitch: SKShapeNode, isOn: Bool) {
        let switchWidth: CGFloat = 80
        let knobSize: CGFloat = 32
        
        // Update switch color
        toggleSwitch.fillColor = isOn ? .green : .gray
        
        // Move knob
        if let knob = toggleSwitch.childNode(withName: "toggleKnob") {
            let moveAction = SKAction.move(to: CGPoint(
                x: isOn ? switchWidth/2 - knobSize/2 - 4 : -switchWidth/2 + knobSize/2 + 4, y: 0), 
                duration: 0.2
            )
            knob.run(moveAction)
        }
    }
    
    private func showPrivacyPolicy() {
        showMessage("Privacy Policy will open in Safari")
        // In a real app, this would open the privacy policy URL
    }
    
    private func showCredits() {
        // Create a simple credits popup
        let popupNode = SKNode()
        popupNode.zPosition = 100
        popupNode.name = "creditsPopup"
        
        // Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.zPosition = -1
        popupNode.addChild(overlay)
        
        // Credits panel
        let panel = SKShapeNode(rectOf: CGSize(width: size.width - 100, height: 400), cornerRadius: 20)
        panel.fillColor = UIColor(white: 0.2, alpha: 0.9)
        panel.strokeColor = .white
        panel.lineWidth = 2
        popupNode.addChild(panel)
        
        // Title
        let title = SKLabelNode(text: "Credits")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 30
        title.position = CGPoint(x: 0, y: 150)
        panel.addChild(title)
        
        // Credits text
        let credits = [
            "SkyHopper Game",
            "Created by Your Name",
            "",
            "Programming: Your Name",
            "Design: Your Name",
            "Graphics: Your Name",
            "",
            "Made with SpriteKit"
        ]
        
        for (index, line) in credits.enumerated() {
            let textLine = SKLabelNode(text: line)
            textLine.fontName = "AvenirNext-Medium"
            textLine.fontSize = 20
            textLine.position = CGPoint(x: 0, y: 100 - CGFloat(index) * 30)
            panel.addChild(textLine)
        }
        
        // Close button
        let closeButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 10)
        closeButton.fillColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        closeButton.strokeColor = .white
        closeButton.lineWidth = 2
        closeButton.position = CGPoint(x: 0, y: -150)
        closeButton.name = "closeCredits"
        
        let closeLabel = SKLabelNode(text: "Close")
        closeLabel.fontName = "AvenirNext-Bold"
        closeLabel.fontSize = 20
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.horizontalAlignmentMode = .center
        closeButton.addChild(closeLabel)
        
        panel.addChild(closeButton)
        
        addChild(popupNode)
    }
    
    private func confirmResetData() {
        // Create confirmation popup
        let popupNode = SKNode()
        popupNode.zPosition = 100
        popupNode.name = "resetConfirmPopup"
        
        // Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.zPosition = -1
        popupNode.addChild(overlay)
        
        // Confirmation panel
        let panel = SKShapeNode(rectOf: CGSize(width: size.width - 100, height: 250), cornerRadius: 20)
        panel.fillColor = UIColor(white: 0.2, alpha: 0.9)
        panel.strokeColor = .white
        panel.lineWidth = 2
        popupNode.addChild(panel)
        
        // Warning title
        let title = SKLabelNode(text: "Warning!")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 30
        title.fontColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        title.position = CGPoint(x: 0, y: 80)
        panel.addChild(title)
        
        // Message
        let message = SKLabelNode(text: "Are you sure you want to reset all game data?")
        message.fontName = "AvenirNext-Medium"
        message.fontSize = 18
        message.position = CGPoint(x: 0, y: 40)
        panel.addChild(message)
        
        let submessage = SKLabelNode(text: "This cannot be undone!")
        submessage.fontName = "AvenirNext-Medium"
        submessage.fontSize = 18
        submessage.position = CGPoint(x: 0, y: 10)
        panel.addChild(submessage)
        
        // Cancel button
        let cancelButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 10)
        cancelButton.fillColor = UIColor(white: 0.5, alpha: 1.0)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 2
        cancelButton.position = CGPoint(x: -70, y: -50)
        cancelButton.name = "cancelReset"
        
        let cancelLabel = SKLabelNode(text: "Cancel")
        cancelLabel.fontName = "AvenirNext-Bold"
        cancelLabel.fontSize = 20
        cancelLabel.fontColor = .white
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.horizontalAlignmentMode = .center
        cancelButton.addChild(cancelLabel)
        
        panel.addChild(cancelButton)
        
        // Confirm button
        let confirmButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 10)
        confirmButton.fillColor = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        confirmButton.strokeColor = .white
        confirmButton.lineWidth = 2
        confirmButton.position = CGPoint(x: 70, y: -50)
        confirmButton.name = "confirmReset"
        
        let confirmLabel = SKLabelNode(text: "Reset")
        confirmLabel.fontName = "AvenirNext-Bold"
        confirmLabel.fontSize = 20
        confirmLabel.fontColor = .white
        confirmLabel.verticalAlignmentMode = .center
        confirmLabel.horizontalAlignmentMode = .center
        confirmButton.addChild(confirmLabel)
        
        panel.addChild(confirmButton)
        
        addChild(popupNode)
    }
    
    private func resetGameData() {
        // Reset player data
        PlayerData.shared.resetAllData()
        
        // Reset maps - since resetToDefault doesn't exist, manually reset maps
        MapManager.shared.unlockedMaps = [.city] // Reset to just the default map
        MapManager.shared.currentMap = .city
        
        // Reset unlocked characters - since resetToDefault doesn't exist, manually reset
        CharacterManager.shared.unlockedAircraft = [.helicopter] // Reset to just the default character
        CharacterManager.shared.selectedAircraft = .helicopter
        
        // Reset currency
        CurrencyManager.shared.resetCurrency()
        
        // Show confirmation
        showMessage("Game data has been reset")
        
        // Return to main menu after short delay
        let wait = SKAction.wait(forDuration: 1.5)
        let returnToMenu = SKAction.run { [weak self] in
            self?.handleBackButton()
        }
        run(SKAction.sequence([wait, returnToMenu]))
    }
    
    // MARK: - Helpers
    
    private func addCloudsBackground() {
        // Add clouds in the background
        for _ in 0..<10 {
            let cloud = createCloud()
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            cloud.zPosition = -5
            addChild(cloud)
        }
    }
    
    private func createCloud() -> SKShapeNode {
        let cloudWidth = CGFloat.random(in: 60...120)
        let cloudHeight = cloudWidth * 0.6
        
        let cloud = SKShapeNode(ellipseOf: CGSize(width: cloudWidth, height: cloudHeight))
        cloud.fillColor = UIColor.white.withAlphaComponent(0.8)
        cloud.strokeColor = .clear
        
        // Add some randomness to cloud shape
        for _ in 0..<3 {
            let bubbleSize = cloudWidth * CGFloat.random(in: 0.4...0.7)
            let bubble = SKShapeNode(circleOfRadius: bubbleSize / 2)
            bubble.fillColor = UIColor.white.withAlphaComponent(0.8)
            bubble.strokeColor = .clear
            
            let xPos = CGFloat.random(in: -cloudWidth/3...cloudWidth/3)
            let yPos = CGFloat.random(in: -cloudHeight/3...cloudHeight/3)
            bubble.position = CGPoint(x: xPos, y: yPos)
            
            cloud.addChild(bubble)
        }
        
        // Add cloud movement
        let speed = CGFloat.random(in: 10...30)
        let moveLeft = SKAction.moveBy(x: -size.width - cloudWidth, y: 0, duration: TimeInterval(size.width / speed))
        let resetPosition = SKAction.moveTo(x: size.width + cloudWidth / 2, duration: 0)
        let sequence = SKAction.sequence([moveLeft, resetPosition])
        let forever = SKAction.repeatForever(sequence)
        
        cloud.run(forever)
        
        return cloud
    }
    
    private func showMessage(_ text: String) {
        let message = SKLabelNode(text: text)
        message.fontName = "AvenirNext-Bold"
        message.fontSize = 24
        message.position = CGPoint(x: size.width / 2, y: size.height / 2)
        message.zPosition = 100
        message.alpha = 0
        addChild(message)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        message.run(sequence)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            for node in touchedNodes {
                if node.name == "backButton" || node.parent?.name == "backButton" {
                    handleBackButton()
                    return
                }
                
                if node.name == "musicToggle" || node.parent?.name == "musicToggle" {
                    toggleMusic()
                    return
                }
                
                if node.name == "soundToggle" || node.parent?.name == "soundToggle" {
                    toggleSound()
                    return
                }
                
                if node.name == "privacyButton" || node.parent?.name == "privacyButton" {
                    showPrivacyPolicy()
                    return
                }
                
                if node.name == "creditsButton" || node.parent?.name == "creditsButton" {
                    showCredits()
                    return
                }
                
                if node.name == "resetButton" || node.parent?.name == "resetButton" {
                    confirmResetData()
                    return
                }
                
                if node.name == "closeCredits" || node.parent?.name == "closeCredits" {
                    childNode(withName: "creditsPopup")?.removeFromParent()
                    return
                }
                
                if node.name == "cancelReset" || node.parent?.name == "cancelReset" {
                    childNode(withName: "resetConfirmPopup")?.removeFromParent()
                    return
                }
                
                if node.name == "confirmReset" || node.parent?.name == "confirmReset" {
                    childNode(withName: "resetConfirmPopup")?.removeFromParent()
                    resetGameData()
                    return
                }
            }
        }
    }
    
    private func handleBackButton() {
        // Transition back to main menu
        let mainMenu = MainMenuScene(size: size)
        mainMenu.scaleMode = scaleMode
        view?.presentScene(mainMenu, transition: SKTransition.fade(withDuration: 0.5))
    }
}