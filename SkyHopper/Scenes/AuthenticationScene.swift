import SpriteKit
import AuthenticationServices

class AuthenticationScene: SKScene {
    
    // UI Elements
    private var backgroundGradient: SKSpriteNode!
    private var logoNode: SKLabelNode!
    private var formContainer: SKShapeNode!
    private var modeToggle: SKNode!
    
    // Form fields
    private var usernameField: UITextField?
    private var emailField: UITextField?
    private var passwordField: UITextField?
    private var referralField: UITextField?
    
    // Buttons
    private var submitButton: SKNode!
    private var appleSignInButton: SKNode!
    private var googleSignInButton: SKNode!
    
    // Mode
    private var isSignUpMode = true
    
    // Layout constants
    private let formWidth: CGFloat = 320
    private let fieldHeight: CGFloat = 50
    private let fieldSpacing: CGFloat = 16
    private let buttonSpacing: CGFloat = 20
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupLogo()
        setupFormContainer()
        setupModeToggle()
        
        // Delay text field setup to ensure view is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupTextFields()
        }
        
        setupButtons()
        
        // Add subtle particle effects
        addFloatingParticles()
    }
    
    private func setupBackground() {
        // Animated gradient background
        let gradientTexture = createGradientTexture()
        backgroundGradient = SKSpriteNode(texture: gradientTexture, size: size)
        backgroundGradient.position = CGPoint(x: size.width/2, y: size.height/2)
        backgroundGradient.zPosition = -100
        addChild(backgroundGradient)
        
        // Add subtle animation
        let colorShift = SKAction.colorize(with: UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1.0), colorBlendFactor: 0.5, duration: 5.0)
        let colorRevert = SKAction.colorize(with: UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1.0), colorBlendFactor: 0.5, duration: 5.0)
        backgroundGradient.run(SKAction.repeatForever(SKAction.sequence([colorShift, colorRevert])))
    }
    
    private func createGradientTexture() -> SKTexture {
        return SKTexture(size: size) { size, context in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1.0).cgColor,
                UIColor(red: 0.2, green: 0.1, blue: 0.4, alpha: 1.0).cgColor,
                UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.5, 1.0]
            
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }
            
            context.drawLinearGradient(gradient,
                                     start: CGPoint(x: 0, y: 0),
                                     end: CGPoint(x: size.width, y: size.height),
                                     options: [])
        }
    }
    
    private func setupLogo() {
        // Sky Hopper logo with glow effect
        logoNode = SKLabelNode(text: "Sky Hopper")
        logoNode.fontName = "AvenirNext-Bold"
        logoNode.fontSize = 48
        logoNode.fontColor = .white
        logoNode.position = CGPoint(x: size.width/2, y: size.height - 150)
        logoNode.zPosition = 10
        addChild(logoNode)
        
        // Add glow effect
        let glowNode = logoNode.copy() as! SKLabelNode
        glowNode.fontColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.5)
        glowNode.zPosition = 9
        glowNode.setScale(1.1)
        
        let glowEffect = SKEffectNode()
        glowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10])
        glowEffect.shouldRasterize = true
        glowEffect.addChild(glowNode)
        glowEffect.position = logoNode.position
        addChild(glowEffect)
        
        // Floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 2.0)
        let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 2.0)
        floatUp.timingMode = .easeInEaseOut
        floatDown.timingMode = .easeInEaseOut
        logoNode.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))
        glowEffect.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))
    }
    
    private func setupFormContainer() {
        // Calculate form height based on content
        let toggleHeight: CGFloat = 50
        let fieldsCount: CGFloat = isSignUpMode ? 4 : 2
        let submitButtonHeight: CGFloat = 50
        let socialSectionHeight: CGFloat = 100
        let padding: CGFloat = 40
        
        let containerHeight = toggleHeight + (fieldsCount * (fieldHeight + fieldSpacing)) + 
                            submitButtonHeight + socialSectionHeight + padding * 2
        
        let containerSize = CGSize(width: formWidth + 40, height: containerHeight)
        let containerPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -containerSize.width/2, y: -containerSize.height/2),
                                                            size: containerSize),
                                        cornerRadius: 24)
        
        formContainer = SKShapeNode(path: containerPath.cgPath)
        formContainer.position = CGPoint(x: size.width/2, y: size.height/2 - 20)
        formContainer.zPosition = 1
        
        // Glass effect
        formContainer.fillColor = UIColor(white: 0.1, alpha: 0.9)
        formContainer.strokeColor = UIColor(white: 1.0, alpha: 0.15)
        formContainer.lineWidth = 1
        
        addChild(formContainer)
    }
    
    private func setupModeToggle() {
        modeToggle = SKNode()
        modeToggle.position = CGPoint(x: 0, y: 150)
        formContainer.addChild(modeToggle)
        
        // Sign Up button
        let signUpButton = createToggleButton(text: "Sign Up", isActive: true)
        signUpButton.position = CGPoint(x: -70, y: 0)
        signUpButton.name = "signUpToggle"
        modeToggle.addChild(signUpButton)
        
        // Login button
        let loginButton = createToggleButton(text: "Login", isActive: false)
        loginButton.position = CGPoint(x: 70, y: 0)
        loginButton.name = "loginToggle"
        modeToggle.addChild(loginButton)
    }
    
    private func createToggleButton(text: String, isActive: Bool) -> SKNode {
        let container = SKNode()
        
        let background = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 20)
        background.fillColor = isActive ? UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.3) : UIColor(white: 1.0, alpha: 0.05)
        background.strokeColor = isActive ? UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.5) : UIColor(white: 1.0, alpha: 0.1)
        background.lineWidth = 1
        container.addChild(background)
        
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 18
        label.fontColor = isActive ? .white : UIColor(white: 0.7, alpha: 1.0)
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
    }
    
    private func setupTextFields() {
        // Remove existing fields
        usernameField?.removeFromSuperview()
        emailField?.removeFromSuperview()
        passwordField?.removeFromSuperview()
        referralField?.removeFromSuperview()
        
        guard let view = self.view else { return }
        
        // Calculate container position in screen coordinates
        let containerScreenPos = convertPoint(toView: formContainer.position)
        
        // Start position for fields just below the toggle, anchored to the top of the container
        let containerTopY = containerScreenPos.y - formContainer.frame.height/2
        var yOffset: CGFloat = containerTopY + 160  // 40 padding + 50 toggle + ~70 margin
        
        // Username field (only for sign up)
        if isSignUpMode {
            usernameField = createTextField(placeholder: "Username", isSecure: false)
            usernameField?.frame = CGRect(
                x: (view.frame.width - formWidth) / 2,
                y: yOffset,
                width: formWidth,
                height: fieldHeight
            )
            view.addSubview(usernameField!)
            yOffset += fieldHeight + fieldSpacing
        }
        
        // Email field
        emailField = createTextField(placeholder: "Email", isSecure: false)
        emailField?.frame = CGRect(
            x: (view.frame.width - formWidth) / 2,
            y: yOffset,
            width: formWidth,
            height: fieldHeight
        )
        emailField?.keyboardType = .emailAddress
        emailField?.autocapitalizationType = .none
        view.addSubview(emailField!)
        yOffset += fieldHeight + fieldSpacing
        
        // Password field
        passwordField = createTextField(placeholder: "Password", isSecure: true)
        passwordField?.frame = CGRect(
            x: (view.frame.width - formWidth) / 2,
            y: yOffset,
            width: formWidth,
            height: fieldHeight
        )
        view.addSubview(passwordField!)
        yOffset += fieldHeight + fieldSpacing
        
        // Referral code field (only for sign up)
        if isSignUpMode {
            referralField = createTextField(placeholder: "Referral Code (Optional)", isSecure: false)
            referralField?.frame = CGRect(
                x: (view.frame.width - formWidth) / 2,
                y: yOffset,
                width: formWidth,
                height: fieldHeight
            )
            referralField?.autocapitalizationType = .allCharacters
            view.addSubview(referralField!)
        }
    }
    
    private func createTextField(placeholder: String, isSecure: Bool) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.borderStyle = .none
        textField.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        textField.textColor = .white
        textField.tintColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
        textField.layer.cornerRadius = fieldHeight / 2
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: fieldHeight))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: fieldHeight))
        textField.rightViewMode = .always
        textField.autocorrectionType = .no
        textField.returnKeyType = isSecure ? .done : .next
        textField.font = UIFont.systemFont(ofSize: 16)
        
        // Custom placeholder color
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(white: 1.0, alpha: 0.4),
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )
        
        return textField
    }
    
    private func setupButtons() {
        // Calculate button positions based on form height
        let containerHeight = formContainer.frame.height
        let bottomPadding: CGFloat = 40
        
        // Submit button
        submitButton = createGlassButton(text: isSignUpMode ? "Create Account" : "Login",
                                       size: CGSize(width: formWidth - 40, height: 50),
                                       isPrimary: true)
        submitButton.position = CGPoint(x: 0, y: -containerHeight/2 + 140)
        submitButton.name = "submitButton"
        formContainer.addChild(submitButton)
        
        // Divider
        let dividerLabel = SKLabelNode(text: "or continue with")
        dividerLabel.fontName = "AvenirNext-Regular"
        dividerLabel.fontSize = 14
        dividerLabel.fontColor = UIColor(white: 0.6, alpha: 1.0)
        dividerLabel.position = CGPoint(x: 0, y: -containerHeight/2 + 80)
        formContainer.addChild(dividerLabel)
        
        // Social sign in buttons
        appleSignInButton = createSocialButton(type: .apple)
        appleSignInButton.position = CGPoint(x: -60, y: -containerHeight/2 + bottomPadding)
        appleSignInButton.name = "appleSignIn"
        formContainer.addChild(appleSignInButton)
        
        googleSignInButton = createSocialButton(type: .google)
        googleSignInButton.position = CGPoint(x: 60, y: -containerHeight/2 + bottomPadding)
        googleSignInButton.name = "googleSignIn"
        formContainer.addChild(googleSignInButton)
    }
    
    private func createGlassButton(text: String, size: CGSize, isPrimary: Bool) -> SKNode {
        let container = SKNode()
        
        let button = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
        if isPrimary {
            // Gradient fill for primary button
            button.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8)
            button.strokeColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        } else {
            button.fillColor = UIColor(white: 1.0, alpha: 0.1)
            button.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        }
        button.lineWidth = 1.5
        container.addChild(button)
        
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        // Add shimmer effect
        if isPrimary {
            addShimmerEffect(to: button)
        }
        
        return container
    }
    
    private func createSocialButton(type: SocialLoginType) -> SKNode {
        let container = SKNode()
        
        let button = SKShapeNode(circleOfRadius: 30)
        button.fillColor = UIColor(white: 1.0, alpha: 0.1)
        button.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        button.lineWidth = 1.5
        container.addChild(button)
        
        // Icon
        let iconName: String
        switch type {
        case .apple:
            iconName = "apple.logo"
        case .google:
            iconName = "g.circle.fill"
        }
        
        if let image = UIImage(systemName: iconName) {
            let texture = SKTexture(image: image)
            let icon = SKSpriteNode(texture: texture)
            icon.size = CGSize(width: 30, height: 30)
            icon.colorBlendFactor = 1.0
            icon.color = .white
            container.addChild(icon)
        }
        
        return container
    }
    
    private func addShimmerEffect(to node: SKShapeNode) {
        let shimmer = SKShapeNode(rect: CGRect(x: -15, y: -25, width: 30, height: 50))
        shimmer.fillColor = UIColor(white: 1.0, alpha: 0.3)
        shimmer.strokeColor = .clear
        shimmer.zRotation = .pi / 6
        
        let mask = SKCropNode()
        mask.maskNode = node.copy() as? SKNode
        mask.addChild(shimmer)
        node.addChild(mask)
        
        // Animate
        let moveRight = SKAction.moveBy(x: 220, y: 0, duration: 2.0)
        let moveLeft = SKAction.moveBy(x: -250, y: 0, duration: 0)
        let wait = SKAction.wait(forDuration: 2.0)
        shimmer.run(SKAction.repeatForever(SKAction.sequence([wait, moveRight, moveLeft])))
    }
    
    private func addFloatingParticles() {
        // Create particle emitter for background ambiance
        for _ in 0..<3 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 20...40))
            particle.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.1)
            particle.strokeColor = .clear
            particle.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                      y: CGFloat.random(in: 0...size.height))
            particle.zPosition = -50
            
            let blur = SKEffectNode()
            blur.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 15])
            blur.shouldRasterize = true
            blur.addChild(particle)
            addChild(blur)
            
            // Float animation
            let duration = Double.random(in: 10...20)
            let moveX = CGFloat.random(in: -50...50)
            let moveY = CGFloat.random(in: -30...30)
            let move = SKAction.moveBy(x: moveX, y: moveY, duration: duration)
            let moveBack = move.reversed()
            blur.run(SKAction.repeatForever(SKAction.sequence([move, moveBack])))
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Dismiss keyboard
        view?.endEditing(true)
        
        // Handle button taps
        if let nodeName = touchedNode.name ?? touchedNode.parent?.name {
            switch nodeName {
            case "signUpToggle":
                if !isSignUpMode {
                    isSignUpMode = true
                    updateFormMode()
                }
            case "loginToggle":
                if isSignUpMode {
                    isSignUpMode = false
                    updateFormMode()
                }
            case "submitButton":
                handleSubmit()
            case "appleSignIn":
                handleAppleSignIn()
            case "googleSignIn":
                handleGoogleSignIn()
            default:
                break
            }
        }
    }
    
    private func updateFormMode() {
        // Update toggle buttons
        modeToggle.children.forEach { node in
            if let background = node.children.first as? SKShapeNode,
               let label = node.children.last as? SKLabelNode {
                
                let isActive = (node.name == "signUpToggle" && isSignUpMode) ||
                             (node.name == "loginToggle" && !isSignUpMode)
                
                background.fillColor = isActive ?
                    UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.3) :
                    UIColor(white: 1.0, alpha: 0.05)
                background.strokeColor = isActive ?
                    UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.5) :
                    UIColor(white: 1.0, alpha: 0.1)
                label.fontColor = isActive ? .white : UIColor(white: 0.7, alpha: 1.0)
            }
        }
        
        // Update form fields
        setupTextFields()
        
        // Update submit button
        if let buttonLabel = submitButton.children.compactMap({ $0 as? SKLabelNode }).first {
            buttonLabel.text = isSignUpMode ? "Create Account" : "Login"
        }
    }
    
    private func handleSubmit() {
        guard let email = emailField?.text, !email.isEmpty,
              let password = passwordField?.text, !password.isEmpty else {
            showError("Please fill in all required fields")
            return
        }
        
        if isSignUpMode {
            guard let username = usernameField?.text, !username.isEmpty else {
                showError("Please enter a username")
                return
            }
            
            // Sign up
            AuthenticationManager.shared.signUpWithEmail(username: username, email: email, password: password) { [weak self] result in
                switch result {
                case .success:
                    // Apply referral code if provided
                    if let referralCode = self?.referralField?.text, !referralCode.isEmpty {
                        AuthenticationManager.shared.applyReferralCode(referralCode) { _ in }
                    }
                    self?.transitionToMainMenu()
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        } else {
            // Login
            AuthenticationManager.shared.loginWithEmail(email: email, password: password) { [weak self] result in
                switch result {
                case .success:
                    self?.transitionToMainMenu()
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func handleAppleSignIn() {
        guard let viewController = view?.window?.rootViewController else { return }
        
        AuthenticationManager.shared.signInWithApple(presentingViewController: viewController) { [weak self] result in
            switch result {
            case .success:
                self?.transitionToMainMenu()
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }
    
    private func handleGoogleSignIn() {
        // Google sign in implementation
        showError("Google Sign In coming soon!")
    }
    
    private func showError(_ message: String) {
        let errorLabel = SKLabelNode(text: message)
        errorLabel.fontName = "AvenirNext-Regular"
        errorLabel.fontSize = 16
        errorLabel.fontColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        errorLabel.position = CGPoint(x: size.width/2, y: 100)
        errorLabel.zPosition = 100
        addChild(errorLabel)
        
        // Fade out after 3 seconds
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        errorLabel.run(SKAction.sequence([wait, fadeOut, remove]))
    }
    
    private func transitionToMainMenu() {
        // Clean up text fields
        usernameField?.removeFromSuperview()
        emailField?.removeFromSuperview()
        passwordField?.removeFromSuperview()
        referralField?.removeFromSuperview()
        
        // Transition
        let transition = SKTransition.fade(withDuration: 0.5)
        let mainMenu = MainMenuScene(size: size)
        mainMenu.scaleMode = .aspectFill
        view?.presentScene(mainMenu, transition: transition)
    }
    
    override func willMove(from view: SKView) {
        // Clean up text fields
        usernameField?.removeFromSuperview()
        emailField?.removeFromSuperview()
        passwordField?.removeFromSuperview()
        referralField?.removeFromSuperview()
    }
    
    enum SocialLoginType {
        case apple
        case google
    }
}

// SKTexture extension moved to Utilities/Extensions.swift
