import SpriteKit

class SettingsScene: SKScene, CurrencyManagerDelegate {
    
    // Currency manager
    private let currencyManager = CurrencyManager.shared
    
    // Audio manager
    private let audioManager = AudioManager.shared
    
    // UI elements
    private var backButton: SKShapeNode!
    private var musicToggle: SKShapeNode!
    private var soundToggle: SKShapeNode!
    private var privacyButton: SKShapeNode!
    private var creditsButton: SKShapeNode!
    private var resetButton: SKShapeNode!
    private var signOutButton: SKShapeNode!
    private var deleteButton: SKShapeNode!
    private var topBar = SKNode()
    
    // Privacy policy scrolling
    private var isScrollingPrivacy = false
    private var lastScrollY: CGFloat = 0
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
        
        // Register as currency delegate to update display
        currencyManager.delegate = self
    }
    
    // MARK: - Currency Manager Delegate
    
    func currencyDidChange() {
        SafeAreaTopBar.updateCurrency(in: topBar)
    }
    
    private func setupScene() {
        // Set background color
        backgroundColor = MapManager.shared.currentMap.backgroundColor
        
        // Add background elements
        addCloudsBackground()
    }
    
    private func setupUI() {
        // Top bar via helper (creates title + back button + currency row)
        topBar = SafeAreaTopBar.build(in: self, title: "Settings") { [weak self] in
            self?.handleBackButton()
        }
        
        // Create settings options
        createSettingsOptions()
    }
    
    private func createSettingsOptions() {
        // Get topBar metrics for layout
        let topBarBottomY = topBar.userData?["topBarBottomY"] as? CGFloat ?? (size.height - 120)
        
        // Sound Settings Section
        let soundLabel = SKLabelNode(text: "Sound Settings")
        soundLabel.fontName = "AvenirNext-Bold"
        soundLabel.fontSize = 28
        soundLabel.position = CGPoint(x: size.width / 2, y: topBarBottomY - 40)
        soundLabel.zPosition = 10
        addChild(soundLabel)
        
        // Music toggle
        let musicLabel = SKLabelNode(text: "Music")
        musicLabel.fontName = "AvenirNext-Medium"
        musicLabel.fontSize = 22
        musicLabel.position = CGPoint(x: size.width / 4, y: topBarBottomY - 90)
        musicLabel.zPosition = 10
        addChild(musicLabel)
        
        // Pass a default value here since we can't access private property directly
        musicToggle = createToggleSwitch(position: CGPoint(x: size.width * 3 / 4, y: topBarBottomY - 90), isOn: true)
        musicToggle.name = "musicToggle"
        addChild(musicToggle)
        
        // Sound effects toggle
        let effectsLabel = SKLabelNode(text: "Sound Effects")
        effectsLabel.fontName = "AvenirNext-Medium"
        effectsLabel.fontSize = 22
        effectsLabel.position = CGPoint(x: size.width / 4, y: topBarBottomY - 140)
        effectsLabel.zPosition = 10
        addChild(effectsLabel)
        
        // Pass a default value here since we can't access private property directly
        soundToggle = createToggleSwitch(position: CGPoint(x: size.width * 3 / 4, y: topBarBottomY - 140), isOn: true)
        soundToggle.name = "soundToggle"
        addChild(soundToggle)
        
        // The Map Default aircraft option has been moved to the Character Selection screen
        
        // Other Options Section
        let otherLabel = SKLabelNode(text: "Other Options")
        otherLabel.fontName = "AvenirNext-Bold"
        otherLabel.fontSize = 28
        otherLabel.position = CGPoint(x: size.width / 2, y: topBarBottomY - 220)
        otherLabel.zPosition = 10
        addChild(otherLabel)
        
        // Privacy Policy
        privacyButton = createButton(title: "Privacy Policy", position: CGPoint(x: size.width / 2, y: topBarBottomY - 280))
        privacyButton.name = "privacyButton"
        addChild(privacyButton)
        
        // Credits
        creditsButton = createButton(title: "Credits", position: CGPoint(x: size.width / 2, y: topBarBottomY - 350))
        creditsButton.name = "creditsButton"
        addChild(creditsButton)
        
        // Reset Game Data
        resetButton = createButton(
            title: "Reset Game Data", 
            position: CGPoint(x: size.width / 2, y: topBarBottomY - 420),
            color: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        )
        resetButton.name = "resetButton"
        addChild(resetButton)
        
        // Sign out
        signOutButton = createButton(
            title: "Sign Out",
            position: CGPoint(x: size.width / 2, y: topBarBottomY - 490),
            color: UIColor(red: 0.35, green: 0.55, blue: 0.95, alpha: 1.0)
        )
        signOutButton.name = "signOutButton"
        addChild(signOutButton)
        
        // Delete account
        deleteButton = createButton(
            title: "Delete Account",
            position: CGPoint(x: size.width / 2, y: topBarBottomY - 560),
            color: UIColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1.0)
        )
        deleteButton.name = "deleteAccountButton"
        addChild(deleteButton)
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
    
    // Map Default aircraft setting has been moved to Character Selection
    
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
        // Create privacy policy dialog
        let dialog = createPrivacyPolicyDialog()
        dialog.name = "privacyDialog"
        addChild(dialog)
    }

    private func createPrivacyPolicyDialog() -> SKNode {
        // Calculate content height first to determine proper dialog size
        let contentHeight = calculatePrivacyPolicyContentHeight()

        // iOS-style dialog sizing (fits content with proper margins)
        let dialogWidth: CGFloat = size.width * 0.85
        let dialogHeight: CGFloat = min(contentHeight + 140, size.height * 0.85) // Content + margins, max 85% screen height

        // Main dialog with iOS 26 styling
        let dialog = SKShapeNode(rectOf: CGSize(width: dialogWidth, height: dialogHeight), cornerRadius: 20)
        dialog.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.95) // Darker, more iOS-like
        dialog.strokeColor = UIColor(white: 0.2, alpha: 0.5)
        dialog.lineWidth = 0.5 // Subtle border
        dialog.position = CGPoint(x: size.width/2, y: size.height/2)
        dialog.zPosition = 200
        dialog.name = "privacyDialog"

        // Blur effect background (iOS-style)
        let blurNode = SKEffectNode()
        blurNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10])
        blurNode.shouldRasterize = true
        let blurShape = SKShapeNode(rectOf: CGSize(width: dialogWidth - 4, height: dialogHeight - 4), cornerRadius: 18)
        blurShape.fillColor = UIColor(white: 0.1, alpha: 0.3)
        blurShape.strokeColor = .clear
        blurNode.addChild(blurShape)
        blurNode.zPosition = -1
        dialog.addChild(blurNode)

        // Title with iOS typography
        let titleLabel = SKLabelNode(text: "Privacy Policy")
        titleLabel.fontName = UIConstants.Text.boldFont
        titleLabel.fontSize = 22 // Slightly smaller for iOS style
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: dialogHeight/2 - 35)
        dialog.addChild(titleLabel)

        // Scroll view container (iOS-style)
        let scrollViewHeight: CGFloat = dialogHeight - 110
        let scrollViewWidth: CGFloat = dialogWidth - 40

        // Create a crop node to mask content outside scroll area
        let cropNode = SKCropNode()
        let maskShape = SKShapeNode(rectOf: CGSize(width: scrollViewWidth, height: scrollViewHeight))
        maskShape.fillColor = .white
        maskShape.strokeColor = .clear
        cropNode.maskNode = maskShape
        cropNode.position = CGPoint(x: 0, y: -20)

        // Scrollable content container
        let scrollContainer = SKNode()
        scrollContainer.name = "scrollContainer"
        cropNode.addChild(scrollContainer)

        dialog.addChild(cropNode)

        // Create formatted text content
        let privacyText = """
        HopVerse - Privacy Policy

        Last Updated: November 30, 2025

        Welcome to HopVerse! This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile game application (the "App").

        1. INFORMATION WE COLLECT

        1.1 Personal Information
        • Email address (if you create an account)
        • Username and display name
        • Apple ID or Google account information (if using social sign-in)
        • Profile picture/avatar (if uploaded)

        1.2 Game Data and Analytics
        • High scores and game statistics
        • Level completion data
        • Achievement progress
        • Daily login streaks
        • In-game purchases and currency
        • Device information (iOS version, device model)

        1.3 Game Center Data
        • Leaderboard scores
        • Achievement unlocks
        • Game Center player ID

        2. HOW WE USE YOUR INFORMATION

        We use the collected information to:
        • Provide and maintain the game service
        • Track and display leaderboards
        • Award achievements
        • Process in-app purchases
        • Improve game performance and features
        • Provide customer support
        • Send game-related notifications

        3. INFORMATION SHARING AND DISCLOSURE

        We do not sell, trade, or otherwise transfer your personal information to third parties except:
        • Game Center (Apple's gaming service) for leaderboards and achievements
        • When required by law
        • With your explicit consent

        4. DATA SECURITY

        We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

        5. CHILDREN'S PRIVACY

        HopVerse is not specifically designed for children under 13. We do not knowingly collect personal information from children under 13. If we learn that we have collected personal information from a child under 13, we will delete it immediately.

        6. YOUR RIGHTS

        You have the right to:
        • Access your personal information
        • Correct inaccurate information
        • Delete your account and data
        • Opt out of data collection (though this may limit game functionality)

        7. CHANGES TO THIS PRIVACY POLICY

        We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App.

        8. CONTACT US

        If you have any questions about this Privacy Policy, please contact us at:
        Email: makllipse@gmail.com

        By using HopVerse, you agree to this Privacy Policy.
        """

        // Layout text with proper iOS typography and spacing
        // Text starts at TOP of scroll area (positive Y) and goes DOWN (decreasing Y)
        let sections = privacyText.components(separatedBy: "\n\n")
        var currentY: CGFloat = scrollViewHeight/2 - 30 // Start near top of visible area

        for section in sections {
            let lines = section.components(separatedBy: "\n")
            var isFirstLineInSection = true

            for (_, line) in lines.enumerated() {
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    continue
                }

                let lineLabel = SKLabelNode(text: line)
                lineLabel.fontName = UIConstants.Text.regularFont
                lineLabel.horizontalAlignmentMode = .left

                // Ensure text fits within scroll view width with proper margins
                let maxTextWidth = scrollViewWidth - 30 // 15px margin on each side
                lineLabel.position = CGPoint(x: -maxTextWidth/2, y: currentY)

                // iOS-style typography hierarchy
                if line.contains("HopVerse") || line.contains("Last Updated") {
                    lineLabel.fontSize = 16
                    lineLabel.fontName = UIConstants.Text.boldFont
                    lineLabel.fontColor = UIColor(white: 0.9, alpha: 1.0)
                } else if line.hasPrefix("1.") || line.hasPrefix("2.") || line.hasPrefix("3.") ||
                          line.hasPrefix("4.") || line.hasPrefix("5.") || line.hasPrefix("6.") ||
                          line.hasPrefix("7.") || line.hasPrefix("8.") {
                    lineLabel.fontSize = 15
                    lineLabel.fontName = UIConstants.Text.boldFont
                    lineLabel.fontColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0) // iOS blue
                } else if line.contains("•") {
                    lineLabel.fontSize = 13
                    lineLabel.fontColor = UIColor(white: 0.8, alpha: 1.0)
                } else {
                    lineLabel.fontSize = 14
                    lineLabel.fontColor = UIColor(white: 0.85, alpha: 1.0)
                }

                // Handle long lines with proper word wrapping
                let words = line.components(separatedBy: " ")
                var wrappedLines: [String] = []
                var currentLine = ""
                
                // Create a test label to measure text width
                let testLabel = SKLabelNode(fontNamed: lineLabel.fontName)
                testLabel.fontSize = lineLabel.fontSize
                
                for word in words {
                    let testText = currentLine.isEmpty ? word : currentLine + " " + word
                    testLabel.text = testText
                    
                    if testLabel.frame.width > maxTextWidth && !currentLine.isEmpty {
                        wrappedLines.append(currentLine)
                        currentLine = word
                    } else {
                        currentLine = testText
                    }
                }
                if !currentLine.isEmpty {
                    wrappedLines.append(currentLine)
                }
                
                // If no wrapping needed, use original
                if wrappedLines.isEmpty {
                    wrappedLines = [line]
                }
                
                // Add all wrapped lines
                for (wrapIndex, wrappedLine) in wrappedLines.enumerated() {
                    if wrapIndex == 0 {
                        lineLabel.text = wrappedLine
                        scrollContainer.addChild(lineLabel)
                        currentY -= isFirstLineInSection ? 28 : 20
                    } else {
                        let continuedLabel = SKLabelNode(text: wrappedLine)
                        continuedLabel.fontName = lineLabel.fontName
                        continuedLabel.fontSize = lineLabel.fontSize
                        continuedLabel.fontColor = lineLabel.fontColor
                        continuedLabel.horizontalAlignmentMode = .left
                        continuedLabel.position = CGPoint(x: -maxTextWidth/2, y: currentY)
                        scrollContainer.addChild(continuedLabel)
                        currentY -= 18  // Slightly less spacing for wrapped continuation
                    }
                }
                isFirstLineInSection = false
            }

            currentY -= 12 // Extra space between sections
        }

        // Position scroll container at origin - content positions handle the layout
        scrollContainer.position = CGPoint(x: 0, y: 0)

        // Scroll indicator with iOS-style animation
        let scrollIndicator = SKLabelNode(text: "Swipe up to read more")
        scrollIndicator.fontName = UIConstants.Text.regularFont
        scrollIndicator.fontSize = 12
        scrollIndicator.fontColor = UIColor(white: 0.5, alpha: 1.0)
        scrollIndicator.position = CGPoint(x: 0, y: -scrollViewHeight/2 + 25)

        // Subtle pulsing animation
        let fadeIn = SKAction.fadeAlpha(to: 0.6, duration: 1.0)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 1.0)
        scrollIndicator.run(SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut])))
        dialog.addChild(scrollIndicator)

        // iOS-style close button
        let closeButton = SKShapeNode(circleOfRadius: 18)
        closeButton.fillColor = UIColor(white: 0.2, alpha: 0.8)
        closeButton.strokeColor = UIColor(white: 0.4, alpha: 0.5)
        closeButton.lineWidth = 0.5
        closeButton.position = CGPoint(x: dialogWidth/2 - 25, y: dialogHeight/2 - 25)
        closeButton.name = "closePrivacyButton"

        // iOS close symbol (X)
        let closeX = SKLabelNode(text: "×")
        closeX.fontName = "Helvetica-Bold"
        closeX.fontSize = 20
        closeX.fontColor = UIColor(white: 0.8, alpha: 1.0)
        closeX.verticalAlignmentMode = .center
        closeX.horizontalAlignmentMode = .center
        closeButton.addChild(closeX)

        dialog.addChild(closeButton)

        // Store scroll bounds for smooth iOS-style scrolling
        // Content starts at top (scrollViewHeight/2 - 30) and goes down to currentY
        // When scrolling UP (to read more), we move the container UP (increase Y)
        let contentTopY = scrollViewHeight/2 - 30 // Where content starts
        let contentBottomY = currentY // Where content ends (negative value)
        let totalContentHeight = contentTopY - contentBottomY // Total height of content
        let visibleHeight = scrollViewHeight - 40 // Visible scroll area height
        
        // Initial position is 0 (content at top visible)
        // To see bottom content, we need to move container UP (positive direction)
        // maxScroll = how far UP we can scroll to see bottom content
        let maxScroll: CGFloat = max(0, totalContentHeight - visibleHeight)
        // minScroll = 0 (can't scroll down past the top)
        let minScroll: CGFloat = 0
        
        let scrollData = NSMutableDictionary()
        scrollData["scrollMinY"] = minScroll
        scrollData["scrollMaxY"] = maxScroll
        scrollData["scrollMomentum"] = 0.0
        dialog.userData = scrollData

        // Debug output
        print("DEBUG: Privacy scroll - contentTopY: \(contentTopY), contentBottomY: \(contentBottomY), totalContentHeight: \(totalContentHeight), visibleHeight: \(visibleHeight), maxScroll: \(maxScroll), minScroll: \(minScroll)")

        return dialog
    }

    private func calculatePrivacyPolicyContentHeight() -> CGFloat {
        let privacyText = """
        HopVerse - Privacy Policy

        Last Updated: November 30, 2025

        Welcome to HopVerse! This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile game application (the "App").

        1. INFORMATION WE COLLECT

        1.1 Personal Information
        • Email address (if you create an account)
        • Username and display name
        • Apple ID or Google account information (if using social sign-in)
        • Profile picture/avatar (if uploaded)

        1.2 Game Data and Analytics
        • High scores and game statistics
        • Level completion data
        • Achievement progress
        • Daily login streaks
        • In-game purchases and currency
        • Device information (iOS version, device model)

        1.3 Game Center Data
        • Leaderboard scores
        • Achievement unlocks
        • Game Center player ID

        2. HOW WE USE YOUR INFORMATION

        We use the collected information to:
        • Provide and maintain the game service
        • Track and display leaderboards
        • Award achievements
        • Process in-app purchases
        • Improve game performance and features
        • Provide customer support
        • Send game-related notifications

        3. INFORMATION SHARING AND DISCLOSURE

        We do not sell, trade, or otherwise transfer your personal information to third parties except:
        • Game Center (Apple's gaming service) for leaderboards and achievements
        • When required by law
        • With your explicit consent

        4. DATA SECURITY

        We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

        5. CHILDREN'S PRIVACY

        HopVerse is not specifically designed for children under 13. We do not knowingly collect personal information from children under 13. If we learn that we have collected personal information from a child under 13, we will delete it immediately.

        6. YOUR RIGHTS

        You have the right to:
        • Access your personal information
        • Correct inaccurate information
        • Delete your account and data
        • Opt out of data collection (though this may limit game functionality)

        7. CHANGES TO THIS PRIVACY POLICY

        We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App.

        8. CONTACT US

        If you have any questions about this Privacy Policy, please contact us at:
        Email: makllipse@gmail.com

        By using HopVerse, you agree to this Privacy Policy.
        """

        let sections = privacyText.components(separatedBy: "\n\n")
        var totalHeight: CGFloat = 0

        for section in sections {
            let lines = section.components(separatedBy: "\n")

            for (_, line) in lines.enumerated() {
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    continue
                }

                if line.contains("HopVerse") || line.contains("Last Updated") {
                    totalHeight += 28
                } else if line.hasPrefix("1.") || line.hasPrefix("2.") || line.hasPrefix("3.") ||
                          line.hasPrefix("4.") || line.hasPrefix("5.") || line.hasPrefix("6.") ||
                          line.hasPrefix("7.") || line.hasPrefix("8.") {
                    totalHeight += 28
                } else if line.contains("•") {
                    totalHeight += 20
                } else {
                    totalHeight += 22
                }
            }

            totalHeight += 12 // Extra space between sections
        }

        return totalHeight
    }
    
    private func showCredits() {
        // Create a simple credits popup
        let popupNode = SKNode()
        popupNode.zPosition = 100
        popupNode.name = "creditsPopup"
        popupNode.position = CGPoint(x: size.width/2, y: size.height/2) // Center the popup on screen
        
        // Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.zPosition = -1
        overlay.position = CGPoint.zero // Position relative to popupNode
        popupNode.addChild(overlay)
        
        // Credits panel
        let panel = SKShapeNode(rectOf: CGSize(width: size.width - 100, height: 400), cornerRadius: 20)
        panel.fillColor = UIColor(white: 0.2, alpha: 0.9)
        panel.strokeColor = .white
        panel.lineWidth = 2
        panel.position = CGPoint.zero // Centered relative to popupNode
        popupNode.addChild(panel)
        
        // Title
        let title = SKLabelNode(text: "Credits")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 30
        title.position = CGPoint(x: 0, y: 150)
        panel.addChild(title)
        
        // Credits text
        let credits = [
            "HopVerse Game",
            "Created by MAKLLIPSE",
            "",
            "Programming: MAKLLIPSE",
            "Design: MAKLLIPSE",
            "Graphics: MAKLLIPSE",
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
    
    private func handleSignOut() {
        AuthenticationManager.shared.logout()
        let transition = SKTransition.fade(withDuration: 0.4)
        let authScene = AuthenticationScene(size: size)
        authScene.scaleMode = .aspectFill
        view?.presentScene(authScene, transition: transition)
    }
    
    private func confirmDeleteAccount() {
        // Simple confirmation pop-up
        let popupSize = CGSize(width: size.width - 80, height: 200)
        let popup = SKShapeNode(rectOf: popupSize, cornerRadius: 18)
        popup.name = "deleteConfirmPopup"
        popup.fillColor = UIColor(white: 0.15, alpha: 0.95)
        popup.strokeColor = UIColor(white: 1.0, alpha: 0.15)
        popup.lineWidth = 1.5
        popup.position = CGPoint(x: size.width/2, y: size.height/2)
        popup.zPosition = 500
        
        let title = SKLabelNode(text: "Delete Account?")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 22
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 50)
        popup.addChild(title)
        
        let message = SKLabelNode(text: "This will remove your profile and local data.")
        message.fontName = "AvenirNext-Regular"
        message.fontSize = 16
        message.fontColor = UIColor(white: 0.85, alpha: 1.0)
        message.position = CGPoint(x: 0, y: 10)
        popup.addChild(message)
        
        let buttonWidth: CGFloat = (popupSize.width - 60) / 2
        
        let cancel = createButton(title: "Cancel", position: CGPoint(x: -buttonWidth/2 - 10, y: -50))
        cancel.name = "cancelDeleteAccount"
        popup.addChild(cancel)
        
        let confirm = createButton(title: "Delete", position: CGPoint(x: buttonWidth/2 + 10, y: -50), color: UIColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1.0))
        confirm.name = "confirmDeleteAccount"
        popup.addChild(confirm)
        
        addChild(popup)
    }
    
    private func performDeleteAccount() {
        AuthenticationManager.shared.deleteAccount { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    let transition = SKTransition.fade(withDuration: 0.4)
                    let authScene = AuthenticationScene(size: self.size)
                    authScene.scaleMode = .aspectFill
                    self.view?.presentScene(authScene, transition: transition)
                case .failure(let error):
                    self.showMessage(error.localizedDescription)
                }
            }
        }
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

            // If privacy dialog is visible, block all touches except for the close button
            if let privacyDialog = childNode(withName: "privacyDialog") {
                // Check if close button was tapped
                for node in touchedNodes {
                    if node.name == "closePrivacyButton" || node.parent?.name == "closePrivacyButton" {
                        privacyDialog.removeFromParent()
                        return
                    }
                }
                // Block all other touches when privacy dialog is visible (consume the touch)
                lastScrollY = location.y
                return
            }
            
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
                
                // Map default option has been moved to Character Selection
                
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
                
                if node.name == "signOutButton" || node.parent?.name == "signOutButton" {
                    handleSignOut()
                    return
                }
                
                if node.name == "deleteAccountButton" || node.parent?.name == "deleteAccountButton" {
                    confirmDeleteAccount()
                    return
                }
                
                if node.name == "cancelDeleteAccount" || node.parent?.name == "cancelDeleteAccount" {
                    childNode(withName: "deleteConfirmPopup")?.removeFromParent()
                    return
                }
                
                if node.name == "confirmDeleteAccount" || node.parent?.name == "confirmDeleteAccount" {
                    childNode(withName: "deleteConfirmPopup")?.removeFromParent()
                    performDeleteAccount()
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

                if node.name == "closePrivacyButton" || node.parent?.name == "closePrivacyButton" {
                    childNode(withName: "privacyDialog")?.removeFromParent()
                    return
            }
        }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let privacyDialog = childNode(withName: "privacyDialog"),
              let cropNode = privacyDialog.children.first(where: { $0 is SKCropNode }) as? SKCropNode,
              let scrollContainer = cropNode.childNode(withName: "scrollContainer"),
              let scrollData = privacyDialog.userData,
              let scrollMinY = scrollData["scrollMinY"] as? CGFloat,
              let scrollMaxY = scrollData["scrollMaxY"] as? CGFloat else { return }

        let location = touch.location(in: self)

        // Only scroll if we're not over a button (allow scrolling in text area only)
        let touchedNodes = nodes(at: location)
        let hasInteractiveElement = touchedNodes.contains { node in
            let nodeName = node.name ?? ""
            return nodeName.contains("Button") || nodeName.contains("Toggle") || nodeName.contains("checkbox")
        }

        if hasInteractiveElement {
            return // Don't scroll if touching interactive elements
        }
        let previousLocation = touch.previousLocation(in: self)

        // Check if touch is within privacy dialog bounds
        let dialogBounds = privacyDialog.calculateAccumulatedFrame()
        if dialogBounds.contains(location) {
            let deltaY = location.y - previousLocation.y

            // iOS natural scrolling behavior:
            // - Swipe UP (finger moves up, deltaY is negative) = see content BELOW = move container UP
            // - Content is positioned with positive Y at top, going negative downward
            // - To see content below, container.position.y needs to INCREASE (shift content up)
            // - So: swipe up (deltaY < 0) should increase position.y → use + deltaY... wait no
            // Actually: when finger moves UP, deltaY is NEGATIVE
            // We want content to move UP (reveal below) → position.y should INCREASE
            // So we ADD the NEGATIVE of deltaY → position.y + (-deltaY) = position.y - deltaY... 
            // But that's inverted. Let's think again:
            // Standard iOS: drag finger DOWN = content moves DOWN (scroll up to see above)
            // drag finger UP = content moves UP (scroll down to see below)
            // In SpriteKit with crop node: moving container.y UP reveals content that was BELOW
            // So swipe UP (deltaY negative) → container goes UP → ADD to position.y
            // That means: newY = position.y + deltaY... but deltaY is negative when swiping up
            // So position decreases... that's wrong.
            // Let's just use: newY = position.y + deltaY (standard) and see
            let newY = scrollContainer.position.y + deltaY

            // Apply resistance at scroll boundaries (iOS rubber banding effect)
            let constrainedY: CGFloat
            if newY > scrollMaxY {
                let overscroll = newY - scrollMaxY
                constrainedY = scrollMaxY + overscroll * 0.3 // Rubber band at bottom
            } else if newY < scrollMinY {
                let overscroll = scrollMinY - newY
                constrainedY = scrollMinY - overscroll * 0.3 // Rubber band at top
            } else {
                constrainedY = newY
            }

            scrollContainer.position.y = constrainedY
            isScrollingPrivacy = true

            // Store momentum for smooth deceleration
            if let userData = privacyDialog.userData {
                userData["scrollMomentum"] = deltaY * 0.8 // Dampened momentum
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Apply iOS-style momentum scrolling
        if isScrollingPrivacy,
           let privacyDialog = childNode(withName: "privacyDialog"),
           let cropNode = privacyDialog.children.first(where: { $0 is SKCropNode }) as? SKCropNode,
           let scrollContainer = cropNode.childNode(withName: "scrollContainer"),
           let scrollData = privacyDialog.userData,
           let scrollMinY = scrollData["scrollMinY"] as? CGFloat,
           let scrollMaxY = scrollData["scrollMaxY"] as? CGFloat,
           let momentum = scrollData["scrollMomentum"] as? CGFloat {

            // Apply momentum-based scrolling animation
            applyScrollMomentum(to: scrollContainer, momentum: momentum, minY: scrollMinY, maxY: scrollMaxY)
        }

        isScrollingPrivacy = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Reset momentum on touch cancellation
        if let privacyDialog = childNode(withName: "privacyDialog"),
           let userData = privacyDialog.userData {
            userData["scrollMomentum"] = 0.0
        }
        isScrollingPrivacy = false
    }

    private func applyScrollMomentum(to scrollContainer: SKNode, momentum: CGFloat, minY: CGFloat, maxY: CGFloat) {
        guard abs(momentum) > 0.5 else {
            // Snap to bounds if momentum is too low
            snapToScrollBounds(scrollContainer, minY: minY, maxY: maxY)
            return
        }

        let damping: CGFloat = 0.95
        var currentMomentum = momentum
        var currentY = scrollContainer.position.y

        // Apply momentum animation
        let momentumAction = SKAction.customAction(withDuration: 0.5) { node, elapsedTime in
            if abs(currentMomentum) < 0.1 {
                // Stop animation when momentum is low
                node.removeAction(forKey: "scrollMomentum")
                self.snapToScrollBounds(node, minY: minY, maxY: maxY)
                return
            }

            currentY += currentMomentum
            currentMomentum *= damping

            // Apply boundary constraints with rubber band effect
            if currentY > maxY {
                let overscroll = currentY - maxY
                currentY = maxY + overscroll * 0.3
                currentMomentum *= 0.5 // Reduce momentum on boundary
            } else if currentY < minY {
                let overscroll = minY - currentY
                currentY = minY - overscroll * 0.3
                currentMomentum *= 0.5 // Reduce momentum on boundary
            }

            node.position.y = currentY
        }

        scrollContainer.run(momentumAction, withKey: "scrollMomentum")
    }

    private func snapToScrollBounds(_ scrollContainer: SKNode, minY: CGFloat, maxY: CGFloat) {
        let currentY = scrollContainer.position.y
        let targetY: CGFloat

        if currentY > maxY {
            targetY = maxY
        } else if currentY < minY {
            targetY = minY
        } else {
            return // Already within bounds
        }

        // Smooth snap animation
        let snapAction = SKAction.moveTo(y: targetY, duration: 0.2)
        snapAction.timingMode = .easeOut
        scrollContainer.run(snapAction)
    }
    
    private func handleBackButton() {
        // Transition back to main menu
        let mainMenu = MainMenuScene(size: size)
        mainMenu.scaleMode = scaleMode
        view?.presentScene(mainMenu, transition: SKTransition.fade(withDuration: 0.5))
    }
}