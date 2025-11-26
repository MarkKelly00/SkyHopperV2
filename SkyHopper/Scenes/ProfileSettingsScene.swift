import SpriteKit
import UIKit

class ProfileSettingsScene: SKScene, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Tab System
    enum ProfileTab {
        case profile
        case achievements
        case referrals

        var title: String {
            switch self {
            case .profile: return "Profile"
            case .achievements: return "Achievements"
            case .referrals: return "Referrals"
            }
        }

        var icon: String {
            switch self {
            case .profile: return "person.circle.fill"
            case .achievements: return "trophy.fill"
            case .referrals: return "person.2.fill"
            }
        }
    }

    // UI Elements
    private var backgroundGradient: SKSpriteNode!
    private var topBar: SKNode!
    private var tabButtons: [TabButton] = []
    private var activeTab: ProfileTab = .profile
    private var profileContainer: SKShapeNode!
    private var achievementsContainer: SKShapeNode!
    private var referralsContainer: SKShapeNode!
    private var settingsContainer: SKShapeNode!
    
    // Profile elements
    private var avatarNode: SKNode!
    private var usernameLabel: SKLabelNode!
    private var emailLabel: SKLabelNode!
    private var memberSinceLabel: SKLabelNode!
    private var referralCodeLabel: SKLabelNode!
    
    // Stats
    private var statsNodes: [SKNode] = []

    // Friends list
    private var friendsScrollContainer: SKNode!
    private var friendRequests: [FriendRequest] = []
    
    // Achievements scrolling
    private var achievementScrollContainer: SKNode!
    private var achievementCropNode: SKCropNode!
    private var isAchievementScrolling = false
    private var lastAchievementTouchY: CGFloat = 0
    private var achievementScrollVelocity: CGFloat = 0

    // Tab button struct
    struct TabButton {
        let node: SKNode
        let tab: ProfileTab
        let background: SKShapeNode
        let label: SKLabelNode
        let icon: SKSpriteNode?
    }

    override func didMove(to view: SKView) {
        setupBackground()
        setupTopBar()
        setupTabs()
        setupProfileSection()
        setupAchievementsSection()
        setupReferralsSection()

        // Start with profile tab active
        selectTab(.profile)
        loadUserData()
    }
    
    private func setupBackground() {
        // Modern gradient background
        let gradientTexture = SKTexture(size: size) { size, context in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0).cgColor,
                UIColor(red: 0.15, green: 0.1, blue: 0.25, alpha: 1.0).cgColor
            ] as CFArray
            
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil) else { return }
            
            context.drawLinearGradient(gradient,
                                     start: CGPoint(x: 0, y: 0),
                                     end: CGPoint(x: size.width, y: size.height),
                                     options: [])
        }
        
        backgroundGradient = SKSpriteNode(texture: gradientTexture, size: size)
        backgroundGradient.position = CGPoint(x: size.width/2, y: size.height/2)
        backgroundGradient.zPosition = -100
        addChild(backgroundGradient)
    }
    
    private func setupTopBar() {
        topBar = SKNode()
        topBar.position = CGPoint(x: 0, y: size.height - 70)
        topBar.zPosition = 10
        addChild(topBar)

        // Back button - text only, no icon (cleaner look)
        let backButton = createGlassButton(text: "Back", icon: nil, size: CGSize(width: 70, height: 34))
        backButton.position = CGPoint(x: 50, y: 0)
        backButton.name = "backButton"
        topBar.addChild(backButton)

        // Title
        let titleLabel = SKLabelNode(text: "Profile & Settings")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: size.width/2, y: 0)
        topBar.addChild(titleLabel)
    }

    private func setupTabs() {
        let tabs: [ProfileTab] = [.profile, .achievements, .referrals]
        let horizontalPadding: CGFloat = 20
        let spacing: CGFloat = 8
        let availableWidth = size.width - (horizontalPadding * 2) - (spacing * CGFloat(tabs.count - 1))
        let tabWidth: CGFloat = availableWidth / CGFloat(tabs.count)  // Evenly distributed
        let tabHeight: CGFloat = 38
        let startX = horizontalPadding + tabWidth/2

        for (index, tab) in tabs.enumerated() {
            let xPos = startX + CGFloat(index) * (tabWidth + spacing)
            let tabButton = createTabButton(tab: tab, size: CGSize(width: tabWidth, height: tabHeight))
            tabButton.node.position = CGPoint(x: xPos, y: size.height - 140)
            tabButton.node.zPosition = 5
            addChild(tabButton.node)
            tabButtons.append(tabButton)
        }

        // Activate first tab
        selectTab(.profile)
    }

    private func createTabButton(tab: ProfileTab, size: CGSize) -> TabButton {
        let container = SKNode()

        // Glass background with better contrast
        let background = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
        background.fillColor = UIColor(white: 0.15, alpha: 0.7)
        background.strokeColor = UIColor(white: 1.0, alpha: 0.4)
        background.lineWidth = 1.5
        container.addChild(background)

        // Icon with better visibility - smaller for compact tabs
        var icon: SKSpriteNode? = nil
        if let image = UIImage(systemName: tab.icon) {
            let texture = SKTexture(image: image)
            icon = SKSpriteNode(texture: texture)
            icon?.size = CGSize(width: 14, height: 14)
            icon?.position = CGPoint(x: -size.width/2 + 18, y: 0)
            icon?.colorBlendFactor = 1.0
            icon?.color = .white
            container.addChild(icon!)
        }

        // Label with better contrast - smaller font for compact tabs
        let label = SKLabelNode(text: tab.title)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 6, y: 0)
        container.addChild(label)

        return TabButton(node: container, tab: tab, background: background, label: label, icon: icon)
    }

    private func selectTab(_ tab: ProfileTab) {
        activeTab = tab

        // Update tab appearances
        for tabButton in tabButtons {
            let isActive = tabButton.tab == tab

            // Animate tab selection
            let scaleAction = SKAction.scale(to: isActive ? 1.05 : 1.0, duration: 0.2)
            tabButton.node.run(scaleAction)

            // Update colors with better contrast
            tabButton.background.fillColor = isActive ?
                UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8) :
                UIColor(white: 0.15, alpha: 0.7)

            tabButton.background.strokeColor = isActive ?
                UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0) :
                UIColor(white: 1.0, alpha: 0.1)

            tabButton.label.fontColor = isActive ? .white : UIColor(white: 0.8, alpha: 1.0)
            tabButton.icon?.color = isActive ? .white : UIColor(white: 0.8, alpha: 1.0)
        }

        // Show/hide containers
        profileContainer?.isHidden = tab != .profile
        achievementsContainer?.isHidden = tab != .achievements
        referralsContainer?.isHidden = tab != .referrals
    }
    
    private func setupProfileSection() {
        // Glass container - expanded to include friends, properly centered
        let containerSize = CGSize(width: size.width - 40, height: size.height - 240)
        profileContainer = createGlassContainer(size: containerSize)
        profileContainer.position = CGPoint(x: size.width/2, y: size.height/2 - 40)
        addChild(profileContainer)

        // Avatar - centered at top
        avatarNode = createLargeAvatar()
        avatarNode.position = CGPoint(x: 0, y: containerSize.height/2 - 100)
        profileContainer.addChild(avatarNode)
        
        // User info - centered below avatar
        usernameLabel = SKLabelNode(text: "Loading...")
        usernameLabel.fontName = "AvenirNext-Bold"
        usernameLabel.fontSize = 28
        usernameLabel.fontColor = .white
        usernameLabel.horizontalAlignmentMode = .center
        usernameLabel.position = CGPoint(x: 0, y: containerSize.height/2 - 180)
        profileContainer.addChild(usernameLabel)
        
        emailLabel = SKLabelNode(text: "")
        emailLabel.fontName = "AvenirNext-Regular"
        emailLabel.fontSize = 18
        emailLabel.fontColor = UIColor(white: 0.8, alpha: 1.0)
        emailLabel.horizontalAlignmentMode = .center
        emailLabel.position = CGPoint(x: 0, y: containerSize.height/2 - 210)
        profileContainer.addChild(emailLabel)
        
        memberSinceLabel = SKLabelNode(text: "")
        memberSinceLabel.fontName = "AvenirNext-Regular"
        memberSinceLabel.fontSize = 16
        memberSinceLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
        memberSinceLabel.horizontalAlignmentMode = .center
        memberSinceLabel.position = CGPoint(x: 0, y: containerSize.height/2 - 240)
        profileContainer.addChild(memberSinceLabel)
        
        // Referral code section - centered with proper margins
        let referralContainer = SKNode()
        referralContainer.position = CGPoint(x: 0, y: containerSize.height/2 - 290)
        profileContainer.addChild(referralContainer)
        
        // Code box and share button side by side, centered together
        let codeWidth: CGFloat = 180
        let shareButtonSize: CGFloat = 44
        let spacing: CGFloat = 12
        let totalWidth = codeWidth + spacing + shareButtonSize
        let startX = -totalWidth/2
        
        // Code background - left side of center
        let referralBg = SKShapeNode(rectOf: CGSize(width: codeWidth, height: 44), cornerRadius: 22)
        referralBg.fillColor = UIColor(white: 0.1, alpha: 0.6)
        referralBg.strokeColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.5)
        referralBg.lineWidth = 2
        referralBg.position = CGPoint(x: startX + codeWidth/2, y: 0)
        referralContainer.addChild(referralBg)
        
        referralCodeLabel = SKLabelNode(text: "Code: ------")
        referralCodeLabel.fontName = "AvenirNext-DemiBold"
        referralCodeLabel.fontSize = 16
        referralCodeLabel.fontColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        referralCodeLabel.verticalAlignmentMode = .center
        referralCodeLabel.horizontalAlignmentMode = .center
        referralCodeLabel.position = CGPoint(x: startX + codeWidth/2, y: 0)
        referralContainer.addChild(referralCodeLabel)
        
        // Share button - right side of code box
        let shareButton = createGlassButton(text: nil, icon: "square.and.arrow.up", size: CGSize(width: shareButtonSize, height: shareButtonSize))
        shareButton.position = CGPoint(x: startX + codeWidth + spacing + shareButtonSize/2, y: 0)
        shareButton.name = "shareReferralButton"
        referralContainer.addChild(shareButton)

        // Friends section
        setupFriendsInProfile(containerSize: containerSize)
    }

    private func setupFriendsInProfile(containerSize: CGSize) {
        // Friends section starts well below the referral code (which is at containerSize.height/2 - 290)
        let friendsSectionY: CGFloat = containerSize.height/2 - 420
        
        // Check if user has friends
        let friends = AuthenticationManager.shared.currentUser?.friends ?? []
        
        if friends.isEmpty {
            // Show "Add Friends" prompt when no friends - centered, below code section
            let noFriendsContainer = SKNode()
            noFriendsContainer.position = CGPoint(x: 0, y: friendsSectionY + 40)
            profileContainer.addChild(noFriendsContainer)
            
            let noFriendsLabel = SKLabelNode(text: "No friends yet")
            noFriendsLabel.fontName = "AvenirNext-Medium"
            noFriendsLabel.fontSize = 15
            noFriendsLabel.fontColor = UIColor(white: 0.5, alpha: 1.0)
            noFriendsLabel.horizontalAlignmentMode = .center
            noFriendsLabel.position = CGPoint(x: 0, y: 30)
            noFriendsContainer.addChild(noFriendsLabel)
            
            // Add Friends button - text only, no icon overlap issue
            let addFriendButton = createGlassButton(text: "Add Friends", icon: nil, size: CGSize(width: 140, height: 40))
            addFriendButton.position = CGPoint(x: 0, y: -15)
            addFriendButton.name = "addFriendButton"
            noFriendsContainer.addChild(addFriendButton)
            
            // Don't create the friends scroll container if no friends
            return
        }
        
        // Friends header with count and add button - all centered
        let friendsHeaderContainer = SKNode()
        friendsHeaderContainer.position = CGPoint(x: 0, y: friendsSectionY + 100)
        profileContainer.addChild(friendsHeaderContainer)
        
        let friendsHeader = SKLabelNode(text: "Friends (\(friends.count))")
        friendsHeader.fontName = "AvenirNext-Bold"
        friendsHeader.fontSize = 18
        friendsHeader.fontColor = .white
        friendsHeader.horizontalAlignmentMode = .center
        friendsHeader.verticalAlignmentMode = .center
        friendsHeader.position = CGPoint(x: -40, y: 0)
        friendsHeaderContainer.addChild(friendsHeader)

        // Add friend button - next to header, centered together
        let addFriendButton = createGlassButton(text: nil, icon: "person.badge.plus", size: CGSize(width: 36, height: 36))
        addFriendButton.position = CGPoint(x: 50, y: 0)
        addFriendButton.name = "addFriendButton"
        friendsHeaderContainer.addChild(addFriendButton)

        // Friends container with glass effect - centered
        let friendsContainerBg = SKShapeNode(rectOf: CGSize(width: containerSize.width - 50, height: 140), cornerRadius: 16)
        friendsContainerBg.fillColor = UIColor(white: 0.05, alpha: 0.4)
        friendsContainerBg.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        friendsContainerBg.lineWidth = 1
        friendsContainerBg.position = CGPoint(x: 0, y: friendsSectionY)
        profileContainer.addChild(friendsContainerBg)

        // Friends scroll container
        friendsScrollContainer = SKNode()
        friendsScrollContainer.position = CGPoint(x: 0, y: friendsSectionY)

        let maskSize = CGSize(width: containerSize.width - 60, height: 120)
        let mask = SKShapeNode(rectOf: maskSize, cornerRadius: 12)
        mask.fillColor = .white

        let cropNode = SKCropNode()
        cropNode.maskNode = mask
        cropNode.addChild(friendsScrollContainer)
        cropNode.position = CGPoint(x: 0, y: 0)

        profileContainer.addChild(cropNode)
    }

    private func setupAchievementsSection() {
        // Glass container for achievements - properly centered
        let containerSize = CGSize(width: size.width - 40, height: size.height - 240)
        achievementsContainer = createGlassContainer(size: containerSize)
        achievementsContainer.position = CGPoint(x: size.width/2, y: size.height/2 - 40)
        addChild(achievementsContainer)

        // Title
        let titleLabel = SKLabelNode(text: "Achievements")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: containerSize.height/2 - 50)
        achievementsContainer.addChild(titleLabel)

        // Scroll container for achievements - store reference for scrolling
        achievementScrollContainer = SKNode()
        achievementScrollContainer.position = CGPoint(x: 0, y: 0)
        achievementScrollContainer.name = "achievementScroll"
        
        // Mask for scrolling - slightly smaller than container
        let maskHeight = containerSize.height - 130
        let maskSize = CGSize(width: containerSize.width - 40, height: maskHeight)
        let mask = SKShapeNode(rectOf: maskSize, cornerRadius: 12)
        mask.fillColor = .white
        
        achievementCropNode = SKCropNode()
        achievementCropNode.maskNode = mask
        achievementCropNode.addChild(achievementScrollContainer)
        achievementCropNode.position = CGPoint(x: 0, y: -20)  // Offset below title
        achievementCropNode.name = "achievementCropNode"
        
        achievementsContainer.addChild(achievementCropNode)

        // Load real achievements from AchievementManager
        let achievements = AchievementManager.shared.achievements
        let cardHeight: CGFloat = 85
        let spacing: CGFloat = 10
        let startY = maskHeight/2 - cardHeight/2 - 10  // Start from top of visible area
        var yPos: CGFloat = startY
        
        for (_, achievement) in achievements.enumerated() {
            let achievementCard = createRealAchievementCard(achievement: achievement)
            achievementCard.position = CGPoint(x: 0, y: yPos)
            achievementScrollContainer.addChild(achievementCard)
            yPos -= (cardHeight + spacing)
        }
    }

    private func setupReferralsSection() {
        // Glass container for referrals - properly centered
        let containerSize = CGSize(width: size.width - 40, height: size.height - 240)
        referralsContainer = createGlassContainer(size: containerSize)
        referralsContainer.position = CGPoint(x: size.width/2, y: size.height/2 - 40)
        addChild(referralsContainer)

        // All content positioned relative to container center
        var currentY: CGFloat = containerSize.height/2 - 50  // Start near top with padding

        // Title
        let titleLabel = SKLabelNode(text: "Referral Program")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: currentY)
        referralsContainer.addChild(titleLabel)
        currentY -= 35

        // Description
        let descLabel = SKLabelNode(text: "Invite friends and earn points together!")
        descLabel.fontName = "AvenirNext-Regular"
        descLabel.fontSize = 15
        descLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
        descLabel.horizontalAlignmentMode = .center
        descLabel.position = CGPoint(x: 0, y: currentY)
        referralsContainer.addChild(descLabel)
        currentY -= 50

        // Referral code display - properly sized and centered
        let codeWidth: CGFloat = 220
        let codeBg = SKShapeNode(rectOf: CGSize(width: codeWidth, height: 48), cornerRadius: 24)
        codeBg.fillColor = UIColor(white: 0.1, alpha: 1.0)
        codeBg.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        codeBg.lineWidth = 1
        codeBg.position = CGPoint(x: 0, y: currentY)
        referralsContainer.addChild(codeBg)

        let codeLabel = SKLabelNode(text: "Your Code: \(AuthenticationManager.shared.currentUser?.referralCode ?? "------")")
        codeLabel.fontName = "AvenirNext-Bold"
        codeLabel.fontSize = 17
        codeLabel.fontColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        codeLabel.horizontalAlignmentMode = .center
        codeLabel.verticalAlignmentMode = .center
        codeLabel.position = CGPoint(x: 0, y: currentY)
        referralsContainer.addChild(codeLabel)
        currentY -= 60

        // Share button - icon and text properly spaced
        let shareButton = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 22)
        shareButton.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.3)
        shareButton.strokeColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8)
        shareButton.lineWidth = 2
        shareButton.position = CGPoint(x: 0, y: currentY)
        shareButton.name = "shareReferralCode"
        referralsContainer.addChild(shareButton)
        
        // Share icon - left side
        if let iconImage = UIImage(systemName: "square.and.arrow.up") {
            let iconTexture = SKTexture(image: iconImage)
            let iconNode = SKSpriteNode(texture: iconTexture)
            iconNode.size = CGSize(width: 16, height: 16)
            iconNode.colorBlendFactor = 1.0
            iconNode.color = .white
            iconNode.position = CGPoint(x: -50, y: 0)
            shareButton.addChild(iconNode)
        }
        
        // Share text - right of icon
        let shareLabel = SKLabelNode(text: "Share Code")
        shareLabel.fontName = "AvenirNext-DemiBold"
        shareLabel.fontSize = 15
        shareLabel.fontColor = .white
        shareLabel.verticalAlignmentMode = .center
        shareLabel.horizontalAlignmentMode = .left
        shareLabel.position = CGPoint(x: -30, y: 0)
        shareButton.addChild(shareLabel)
        currentY -= 70

        // Stats container - compact
        let statsBg = SKShapeNode(rectOf: CGSize(width: 220, height: 80), cornerRadius: 16)
        statsBg.fillColor = UIColor(white: 0.05, alpha: 0.8)
        statsBg.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        statsBg.lineWidth = 1
        statsBg.position = CGPoint(x: 0, y: currentY)
        referralsContainer.addChild(statsBg)

        let referredLabel = SKLabelNode(text: "Friends Referred: \(AuthenticationManager.shared.currentUser?.referralCount ?? 0)")
        referredLabel.fontName = "AvenirNext-Medium"
        referredLabel.fontSize = 15
        referredLabel.fontColor = .white
        referredLabel.horizontalAlignmentMode = .center
        referredLabel.position = CGPoint(x: 0, y: currentY + 15)
        referralsContainer.addChild(referredLabel)

        let pointsLabel = SKLabelNode(text: "Referral Points: \((AuthenticationManager.shared.currentUser?.referralCount ?? 0) * 500)")
        pointsLabel.fontName = "AvenirNext-Medium"
        pointsLabel.fontSize = 15
        pointsLabel.fontColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        pointsLabel.horizontalAlignmentMode = .center
        pointsLabel.position = CGPoint(x: 0, y: currentY - 15)
        referralsContainer.addChild(pointsLabel)
    }

    private func createRealAchievementCard(achievement: AchievementManager.Achievement) -> SKNode {
        let container = SKNode()
        let width: CGFloat = size.width - 80
        let height: CGFloat = 80
        
        // Card background with glass effect
        let cardBg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        cardBg.fillColor = achievement.isUnlocked ? 
            UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.3) :
            UIColor(white: 0.1, alpha: 0.5)
        cardBg.strokeColor = achievement.isUnlocked ?
            UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.6) :
            UIColor(white: 1.0, alpha: 0.2)
        cardBg.lineWidth = 1.5
        container.addChild(cardBg)
        
        // Icon (trophy for unlocked, lock for locked)
        let iconName = achievement.isUnlocked ? "trophy.fill" : "lock.fill"
        if let image = UIImage(systemName: iconName) {
            let texture = SKTexture(image: image)
            let iconNode = SKSpriteNode(texture: texture)
            iconNode.size = CGSize(width: 32, height: 32)
            iconNode.colorBlendFactor = 1.0
            iconNode.color = achievement.isUnlocked ? 
                UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) :
                UIColor(white: 0.5, alpha: 1.0)
            iconNode.position = CGPoint(x: -width/2 + 40, y: 10)
            container.addChild(iconNode)
        }
        
        // Achievement name
        let nameLabel = SKLabelNode(text: achievement.name)
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: -width/2 + 80, y: 15)
        container.addChild(nameLabel)
        
        // Achievement description
        let descLabel = SKLabelNode(text: achievement.description)
        descLabel.fontName = "AvenirNext-Regular"
        descLabel.fontSize = 13
        descLabel.fontColor = UIColor(white: 0.7, alpha: 1.0)
        descLabel.horizontalAlignmentMode = .left
        descLabel.verticalAlignmentMode = .center
        descLabel.position = CGPoint(x: -width/2 + 80, y: -5)
        container.addChild(descLabel)
        
        // Progress bar
        let progressBarWidth: CGFloat = width - 100
        let progressBarHeight: CGFloat = 6
        
        let progressBg = SKShapeNode(rectOf: CGSize(width: progressBarWidth, height: progressBarHeight), cornerRadius: 3)
        progressBg.fillColor = UIColor(white: 0.2, alpha: 1.0)
        progressBg.strokeColor = .clear
        progressBg.position = CGPoint(x: 0, y: -25)
        container.addChild(progressBg)
        
        let progressFill = SKShapeNode(rectOf: CGSize(width: progressBarWidth * CGFloat(achievement.progress), height: progressBarHeight), cornerRadius: 3)
        progressFill.fillColor = achievement.isUnlocked ?
            UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0) :
            UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
        progressFill.strokeColor = .clear
        progressFill.position = CGPoint(x: -progressBarWidth/2 + (progressBarWidth * CGFloat(achievement.progress))/2, y: -25)
        container.addChild(progressFill)
        
        // Progress percentage
        let progressText = SKLabelNode(text: "\(Int(achievement.progress * 100))%")
        progressText.fontName = "AvenirNext-Medium"
        progressText.fontSize = 12
        progressText.fontColor = .white
        progressText.position = CGPoint(x: width/2 - 30, y: -25)
        container.addChild(progressText)
        
        return container
    }
    
    private func createAchievementCard(title: String, icon: String, progress: Int, total: Int) -> SKNode {
        let container = SKNode()

        // Card background
        let cardSize = CGSize(width: size.width - 80, height: 60)
        let card = SKShapeNode(rectOf: cardSize, cornerRadius: 12)
        card.fillColor = UIColor(white: 0.08, alpha: 1.0)
        card.strokeColor = UIColor(white: 1.0, alpha: 0.1)
        card.lineWidth = 1
        container.addChild(card)

        // Icon
        if let image = UIImage(systemName: icon) {
            let texture = SKTexture(image: image)
            let iconNode = SKSpriteNode(texture: texture)
            iconNode.size = CGSize(width: 24, height: 24)
            iconNode.colorBlendFactor = 1.0
            iconNode.color = progress > 0 ? UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0) : UIColor(white: 0.5, alpha: 1.0)
            iconNode.position = CGPoint(x: -cardSize.width/2 + 40, y: 0)
            container.addChild(iconNode)
        }

        // Title
        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = "AvenirNext-Medium"
        titleLabel.fontSize = 16
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: -cardSize.width/2 + 80, y: 8)
        container.addChild(titleLabel)

        // Progress text
        let progressLabel = SKLabelNode(text: "\(progress)/\(total)")
        progressLabel.fontName = "AvenirNext-Regular"
        progressLabel.fontSize = 14
        progressLabel.fontColor = UIColor(white: 0.6, alpha: 1.0)
        progressLabel.horizontalAlignmentMode = .left
        progressLabel.position = CGPoint(x: -cardSize.width/2 + 80, y: -8)
        container.addChild(progressLabel)

        // Progress bar background
        let progressBg = SKShapeNode(rectOf: CGSize(width: 120, height: 6), cornerRadius: 3)
        progressBg.fillColor = UIColor(white: 0.2, alpha: 1.0)
        progressBg.strokeColor = .clear
        progressBg.position = CGPoint(x: cardSize.width/2 - 80, y: -8)
        container.addChild(progressBg)

        // Progress bar fill
        if total > 0 {
            let progressWidth = (CGFloat(progress) / CGFloat(total)) * 120
            let progressFill = SKShapeNode(rectOf: CGSize(width: max(progressWidth, 6), height: 6), cornerRadius: 3)
            progressFill.fillColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
            progressFill.strokeColor = .clear
            progressFill.position = CGPoint(x: cardSize.width/2 - 80 - (120 - progressWidth)/2, y: -8)
            container.addChild(progressFill)
        }

        return container
    }

    private func setupStatsSection() {
        // Stats cards
        let statsY = size.height - 500
        let cardWidth: CGFloat = (size.width - 60) / 3
        let cardHeight: CGFloat = 80
        
        let stats = [
            ("trophy.fill", "Total Points", "0"),
            ("person.2.fill", "Friends", "0"),
            ("star.fill", "Referrals", "0")
        ]
        
        for (index, stat) in stats.enumerated() {
            let xPos = 30 + cardWidth/2 + CGFloat(index) * cardWidth
            let statCard = createStatCard(icon: stat.0, title: stat.1, value: stat.2, size: CGSize(width: cardWidth - 10, height: cardHeight))
            statCard.position = CGPoint(x: xPos, y: statsY)
            addChild(statCard)
            statsNodes.append(statCard)
        }
    }
    
    private func createStatCard(icon: String, title: String, value: String, size: CGSize) -> SKNode {
        let container = SKNode()
        
        let bg = SKShapeNode(rectOf: size, cornerRadius: 16)
        bg.fillColor = UIColor(white: 1.0, alpha: 0.06)
        bg.strokeColor = UIColor(white: 1.0, alpha: 0.1)
        bg.lineWidth = 1
        container.addChild(bg)
        
        // Icon
        if let image = UIImage(systemName: icon) {
            let texture = SKTexture(image: image)
            let iconNode = SKSpriteNode(texture: texture)
            iconNode.size = CGSize(width: 24, height: 24)
            iconNode.colorBlendFactor = 1.0
            iconNode.color = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
            iconNode.position = CGPoint(x: 0, y: 15)
            container.addChild(iconNode)
        }
        
        // Value
        let valueLabel = SKLabelNode(text: value)
        valueLabel.fontName = "AvenirNext-Bold"
        valueLabel.fontSize = 20
        valueLabel.fontColor = .white
        valueLabel.verticalAlignmentMode = .center
        valueLabel.position = CGPoint(x: 0, y: -5)
        container.addChild(valueLabel)
        
        // Title
        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = "AvenirNext-Regular"
        titleLabel.fontSize = 12
        titleLabel.fontColor = UIColor(white: 0.6, alpha: 1.0)
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: -25)
        container.addChild(titleLabel)
        
        return container
    }
    
    
    private func setupSettingsSection() {
        // Settings options
        let settingsY = 120
        let options = [
            ("bell", "Notifications", "notificationsButton"),
            ("lock", "Privacy", "privacyButton"),
            ("questionmark.circle", "Help", "helpButton"),
            ("arrow.right.square", "Sign Out", "signOutButton")
        ]
        
        let buttonWidth: CGFloat = size.width - 60
        let buttonHeight: CGFloat = 50
        
        for (index, option) in options.enumerated() {
            let button = createSettingButton(icon: option.0, text: option.1, size: CGSize(width: buttonWidth, height: buttonHeight))
            button.position = CGPoint(x: size.width/2, y: CGFloat(settingsY) - CGFloat(index * 60))
            button.name = option.2
            addChild(button)
        }
    }
    
    private func createSettingButton(icon: String, text: String, size: CGSize) -> SKNode {
        let container = SKNode()
        
        let bg = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
        bg.fillColor = UIColor(white: 1.0, alpha: 0.06)
        bg.strokeColor = UIColor(white: 1.0, alpha: 0.1)
        bg.lineWidth = 1
        container.addChild(bg)
        
        // Icon
        if let image = UIImage(systemName: icon) {
            let texture = SKTexture(image: image)
            let iconNode = SKSpriteNode(texture: texture)
            iconNode.size = CGSize(width: 20, height: 20)
            iconNode.colorBlendFactor = 1.0
            iconNode.color = .white
            iconNode.position = CGPoint(x: -size.width/2 + 40, y: 0)
            container.addChild(iconNode)
        }
        
        // Text
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 16
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -size.width/2 + 70, y: -5)
        container.addChild(label)
        
        // Arrow
        if let arrowImage = UIImage(systemName: "chevron.right") {
            let texture = SKTexture(image: arrowImage)
            let arrow = SKSpriteNode(texture: texture)
            arrow.size = CGSize(width: 16, height: 16)
            arrow.colorBlendFactor = 1.0
            arrow.color = UIColor(white: 0.5, alpha: 1.0)
            arrow.position = CGPoint(x: size.width/2 - 30, y: 0)
            container.addChild(arrow)
        }
        
        return container
    }
    
    private func createGlassContainer(size: CGSize) -> SKShapeNode {
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2),
                                                   size: size),
                              cornerRadius: 20)
        
        let container = SKShapeNode(path: path.cgPath)
        container.fillColor = UIColor(white: 1.0, alpha: 0.08)
        container.strokeColor = UIColor(white: 1.0, alpha: 0.15)
        container.lineWidth = 1.5
        
        return container
    }
    
    private func createGlassButton(text: String?, icon: String?, size: CGSize) -> SKNode {
        let container = SKNode()
        
        let button = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
        button.fillColor = UIColor(white: 1.0, alpha: 0.08)
        button.strokeColor = UIColor(white: 1.0, alpha: 0.15)
        button.lineWidth = 1
        container.addChild(button)
        
        var xOffset: CGFloat = 0
        
        // Icon (explicitly tinted for better contrast)
        if let iconName = icon, let uiImage = UIImage(systemName: iconName)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
            let texture = SKTexture(image: uiImage)
            let iconNode = SKSpriteNode(texture: texture)
            iconNode.size = CGSize(width: 20, height: 20)
            iconNode.colorBlendFactor = 0.0
            
            if text != nil {
                iconNode.position = CGPoint(x: -size.width/4, y: 0)
                xOffset = 10
            }
            
            container.addChild(iconNode)
        }
        
        // Text
        if let text = text {
            let label = SKLabelNode(text: text)
            label.fontName = "AvenirNext-Medium"
            label.fontSize = 16
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: xOffset, y: 0)
            container.addChild(label)
        }
        
        return container
    }
    
    private func createLargeAvatar() -> SKNode {
        let container = SKNode()
        container.name = "avatarContainer"
        
        // Check if user has a custom avatar
        let hasCustomAvatar = AuthenticationManager.shared.currentUser?.customAvatar != nil
        
        // Gradient border - larger and more prominent
        let borderSize: CGFloat = 104
        let borderNode = SKShapeNode(circleOfRadius: borderSize/2)
        
        let gradientTexture = SKTexture(size: CGSize(width: 110, height: 110)) { size, context in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0).cgColor
            ] as CFArray
            
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil) else { return }
            
            let center = CGPoint(x: size.width/2, y: size.height/2)
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                                     endCenter: center, endRadius: size.width/2, options: [])
        }
        
        borderNode.fillTexture = gradientTexture
        borderNode.fillColor = .white
        borderNode.strokeColor = .clear
        container.addChild(borderNode)
        
        // Avatar background - larger
        let avatarBg = SKShapeNode(circleOfRadius: 48)
        avatarBg.fillColor = UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0)
        avatarBg.strokeColor = .clear
        avatarBg.name = "avatarBackground"
        container.addChild(avatarBg)
        
        // Check for custom avatar image
        if let avatarData = AuthenticationManager.shared.currentUser?.customAvatar,
           let avatarImage = UIImage(data: avatarData) {
            // User has uploaded a photo - show it
            let avatarTexture = SKTexture(image: avatarImage)
            let avatarSprite = SKSpriteNode(texture: avatarTexture)
            avatarSprite.size = CGSize(width: 96, height: 96)
            avatarSprite.name = "customAvatarImage"
            
            // Create circular mask for avatar
            let maskNode = SKShapeNode(circleOfRadius: 48)
            maskNode.fillColor = .white
            
            let cropNode = SKCropNode()
            cropNode.maskNode = maskNode
            cropNode.addChild(avatarSprite)
            container.addChild(cropNode)
        } else {
            // Default user icon - larger
            if let image = UIImage(systemName: "person.fill") {
                let texture = SKTexture(image: image)
                let icon = SKSpriteNode(texture: texture)
                icon.size = CGSize(width: 50, height: 50)
                icon.colorBlendFactor = 1.0
                icon.color = .white
                icon.name = "defaultAvatarIcon"
                container.addChild(icon)
            }
        }
        
        // Camera button overlay - ONLY show if no custom avatar
        if !hasCustomAvatar {
            let cameraButton = SKShapeNode(circleOfRadius: 18)
            cameraButton.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
            cameraButton.strokeColor = .white
            cameraButton.lineWidth = 2
            cameraButton.position = CGPoint(x: 35, y: -35)
            cameraButton.name = "cameraButton"
            container.addChild(cameraButton)
            
            if let cameraImage = UIImage(systemName: "camera.fill") {
                let texture = SKTexture(image: cameraImage)
                let cameraIcon = SKSpriteNode(texture: texture)
                cameraIcon.size = CGSize(width: 16, height: 16)
                cameraIcon.colorBlendFactor = 1.0
                cameraIcon.color = .white
                cameraIcon.position = cameraButton.position
                cameraIcon.name = "cameraIcon"
                container.addChild(cameraIcon)
            }
        }
        
        container.name = "avatarContainer"
        
        return container
    }
    
    private func loadUserData() {
        guard let user = AuthenticationManager.shared.currentUser else { return }
        
        usernameLabel.text = user.username
        emailLabel.text = user.email
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        memberSinceLabel.text = "Member since \(formatter.string(from: user.dateJoined))"
        
        referralCodeLabel.text = "Code: \(user.referralCode)"
        
        // Update stats
        updateStats(totalPoints: user.totalPoints, friendsCount: user.friends.count, referralsCount: user.referralCount)
        
        // Load friends
        loadFriends()
    }
    
    private func updateStats(totalPoints: Int, friendsCount: Int, referralsCount: Int) {
        let values = [
            String(totalPoints),
            String(friendsCount),
            String(referralsCount)
        ]
        
        for (index, node) in statsNodes.enumerated() where index < values.count {
            if let valueLabel = node.children.compactMap({ $0 as? SKLabelNode }).first(where: { $0.fontSize == 20 }) {
                valueLabel.text = values[index]
            }
        }
    }
    
    private func loadFriends() {
        // Check if friends scroll container is initialized
        guard friendsScrollContainer != nil else {
            print("WARNING: friendsScrollContainer not initialized, skipping loadFriends")
            return
        }

        // Load friend list
        friendsScrollContainer.removeAllChildren()

        // Mock friends data
        let friends = [
            ("Player123", true),
            ("GameMaster", false),
            ("SkyHero", true)
        ]

        var yPos: CGFloat = 50
        for friend in friends {
            let friendNode = createFriendItem(username: friend.0, isOnline: friend.1)
            friendNode.position = CGPoint(x: 0, y: yPos)
            friendsScrollContainer.addChild(friendNode)
            yPos -= 60
        }
    }
    
    private func createFriendItem(username: String, isOnline: Bool) -> SKNode {
        let container = SKNode()
        let width: CGFloat = size.width - 80
        
        // Avatar
        let avatar = SKShapeNode(circleOfRadius: 20)
        avatar.fillColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        avatar.strokeColor = UIColor(white: 1.0, alpha: 0.1)
        avatar.lineWidth = 1
        avatar.position = CGPoint(x: -width/2 + 30, y: 0)
        container.addChild(avatar)
        
        // Initial
        let initial = SKLabelNode(text: String(username.prefix(1)).uppercased())
        initial.fontName = "AvenirNext-Bold"
        initial.fontSize = 16
        initial.fontColor = .white
        initial.verticalAlignmentMode = .center
        initial.position = avatar.position
        container.addChild(initial)
        
        // Username
        let nameLabel = SKLabelNode(text: username)
        nameLabel.fontName = "AvenirNext-Medium"
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -width/2 + 60, y: 0)
        container.addChild(nameLabel)
        
        // Online status
        if isOnline {
            let onlineDot = SKShapeNode(circleOfRadius: 4)
            onlineDot.fillColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            onlineDot.strokeColor = .clear
            onlineDot.position = CGPoint(x: nameLabel.position.x + nameLabel.frame.width + 10, y: 0)
            container.addChild(onlineDot)
        }
        
        // Remove button
        let removeButton = SKShapeNode(circleOfRadius: 16)
        removeButton.fillColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.1)
        removeButton.strokeColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.3)
        removeButton.lineWidth = 1
        removeButton.position = CGPoint(x: width/2 - 30, y: 0)
        container.addChild(removeButton)
        
        if let xImage = UIImage(systemName: "xmark") {
            let texture = SKTexture(image: xImage)
            let xIcon = SKSpriteNode(texture: texture)
            xIcon.size = CGSize(width: 12, height: 12)
            xIcon.colorBlendFactor = 1.0
            xIcon.color = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            xIcon.position = removeButton.position
            container.addChild(xIcon)
        }
        
        return container
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        // Check for tab taps first
        for tabButton in tabButtons {
            if tabButton.node.contains(location) {
                selectTab(tabButton.tab)
                return
            }
        }

        // Check all ancestor nodes for named buttons (up to 4 levels deep for avatar container)
        var currentNode: SKNode? = touchedNode
        var foundName: String? = nil
        for _ in 0..<5 {
            if let name = currentNode?.name {
                foundName = name
                break
            }
            currentNode = currentNode?.parent
        }
        
        if let nodeName = foundName {
            switch nodeName {
            case "backButton":
                handleBackButton()
            case "editButton":
                handleEditProfile()
            case "avatarContainer", "cameraButton", "cameraIcon", "avatarBackground", "defaultAvatarIcon", "customAvatarImage":
                handleAvatarTap()
            case "shareReferralButton":
                handleShareReferral()
            case "shareReferralCode":
                handleShareReferralCode()
            case "addFriendButton":
                handleAddFriend()
            case "signOutButton":
                handleSignOut()
            case "notificationsButton":
                print("Notifications settings")
            case "privacyButton":
                print("Privacy settings")
            case "helpButton":
                print("Help")
            default:
                break
            }
        }
        
        // Check if we're in achievements tab and touching the scroll area
        if activeTab == .achievements && achievementsContainer.alpha > 0 {
            let locationInContainer = touch.location(in: achievementsContainer)
            if abs(locationInContainer.x) < (size.width - 60)/2 && abs(locationInContainer.y) < (size.height - 280)/2 {
                isAchievementScrolling = true
                lastAchievementTouchY = location.y
                achievementScrollVelocity = 0
                achievementScrollContainer?.removeAction(forKey: "momentum")
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isAchievementScrolling, let scrollContainer = achievementScrollContainer else { return }
        
        let location = touch.location(in: self)
        let deltaY = location.y - lastAchievementTouchY
        scrollContainer.position.y += deltaY
        achievementScrollVelocity = deltaY * 0.8 + achievementScrollVelocity * 0.2
        lastAchievementTouchY = location.y
        
        // Calculate scroll bounds
        let achievements = AchievementManager.shared.achievements
        let cardHeight: CGFloat = 85
        let spacing: CGFloat = 10
        let contentHeight = CGFloat(achievements.count) * (cardHeight + spacing)
        let containerSize = CGSize(width: size.width - 40, height: size.height - 240)
        let visibleHeight = containerSize.height - 130
        
        let maxScrollY: CGFloat = 0
        let minScrollY: CGFloat = max(contentHeight - visibleHeight + 30, 0)
        
        // Rubber band effect at edges
        if scrollContainer.position.y > maxScrollY {
            let overscroll = scrollContainer.position.y - maxScrollY
            scrollContainer.position.y = maxScrollY + overscroll * 0.3
        } else if scrollContainer.position.y < -minScrollY {
            let overscroll = -minScrollY - scrollContainer.position.y
            scrollContainer.position.y = -minScrollY - overscroll * 0.3
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAchievementScrolling, let scrollContainer = achievementScrollContainer else {
            isAchievementScrolling = false
            return
        }
        
        isAchievementScrolling = false
        
        // Calculate scroll bounds
        let achievements = AchievementManager.shared.achievements
        let cardHeight: CGFloat = 85
        let spacing: CGFloat = 10
        let contentHeight = CGFloat(achievements.count) * (cardHeight + spacing)
        let containerSize = CGSize(width: size.width - 40, height: size.height - 240)
        let visibleHeight = containerSize.height - 130
        
        let maxScrollY: CGFloat = 0
        let minScrollY: CGFloat = max(contentHeight - visibleHeight + 30, 0)
        
        // Snap back if overscrolled
        if scrollContainer.position.y > maxScrollY {
            let snapBack = SKAction.moveTo(y: maxScrollY, duration: 0.3)
            snapBack.timingMode = .easeOut
            scrollContainer.run(snapBack)
            return
        } else if scrollContainer.position.y < -minScrollY {
            let snapBack = SKAction.moveTo(y: -minScrollY, duration: 0.3)
            snapBack.timingMode = .easeOut
            scrollContainer.run(snapBack)
            return
        }
        
        // Apply smooth momentum scrolling
        if abs(achievementScrollVelocity) > 2 {
            let momentumDuration: TimeInterval = 0.8
            let friction: CGFloat = 0.95
            
            let deceleration = SKAction.customAction(withDuration: momentumDuration) { [weak self] _, elapsedTime in
                guard let self = self, let container = self.achievementScrollContainer else { return }
                
                let decayFactor = pow(friction, elapsedTime * 60)
                let velocity = self.achievementScrollVelocity * decayFactor * 0.15
                
                guard abs(velocity) > 0.1 else { return }
                
                container.position.y += velocity
                
                // Clamp to bounds
                if container.position.y > maxScrollY {
                    container.position.y = maxScrollY
                    container.removeAllActions()
                } else if container.position.y < -minScrollY {
                    container.position.y = -minScrollY
                    container.removeAllActions()
                }
            }
            scrollContainer.run(deceleration, withKey: "momentum")
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isAchievementScrolling = false
    }
    
    private func handleBackButton() {
        let transition = SKTransition.fade(withDuration: 0.5)
        let mainMenu = MainMenuScene(size: size)
        mainMenu.scaleMode = .aspectFill
        view?.presentScene(mainMenu, transition: transition)
    }
    
    private func handleEditProfile() {
        // Would show edit profile dialog
        print("Edit profile")
    }
    
    private func handleAvatarTap() {
        // Show image picker
        guard let viewController = view?.window?.rootViewController else { return }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
        viewController.present(imagePicker, animated: true)
    }
    
    private func handleShareReferral() {
        guard let user = AuthenticationManager.shared.currentUser else { return }

        let shareText = "Join me on Sky Hopper! Use my referral code \(user.referralCode) to get 500 bonus points! 🚁"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let viewController = view?.window?.rootViewController {
            viewController.present(activityVC, animated: true)
        }
    }

    private func handleShareReferralCode() {
        guard let user = AuthenticationManager.shared.currentUser else { return }

        let shareText = """
        🎮 Join Sky Hopper!

        Use my referral code: \(user.referralCode)

        Get 500 bonus points when you sign up!
        Download now and let's play together! 🚁✨
        """

        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let viewController = view?.window?.rootViewController {
            viewController.present(activityVC, animated: true)
        }
    }
    
    private func handleAddFriend() {
        // Show add friend dialog (same as leaderboard)
        let alert = UIAlertController(
            title: "Add Friend",
            message: "Enter a username to send a friend request",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Username"
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Send Request", style: .default) { [weak self] _ in
            if let username = alert.textFields?.first?.text, !username.isEmpty {
                self?.sendFriendRequest(to: username)
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    private func sendFriendRequest(to username: String) {
        AuthenticationManager.shared.sendFriendRequest(to: username) { result in
            switch result {
            case .success:
                // Show success message
                let alert = UIAlertController(
                    title: "Friend Request Sent",
                    message: "Your friend request has been sent to \(username)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                if let viewController = self.view?.window?.rootViewController {
                    viewController.present(alert, animated: true)
                }
            case .failure(let error):
                // Show error message
                let alert = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                if let viewController = self.view?.window?.rootViewController {
                    viewController.present(alert, animated: true)
                }
            }
        }
    }
    
    private func handleSignOut() {
        AuthenticationManager.shared.logout()
        
        let transition = SKTransition.fade(withDuration: 0.5)
        let authScene = AuthenticationScene(size: size)
        authScene.scaleMode = .aspectFill
        view?.presentScene(authScene, transition: transition)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            // Save image data
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                // Would save to user profile
                print("Avatar image selected: \(imageData.count) bytes")
                
                // Update avatar display
                updateAvatarDisplay(with: image)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func updateAvatarDisplay(with image: UIImage) {
        // Update the avatar node with the selected image
        if let avatarContainer = avatarNode {
            // Remove old icon
            avatarContainer.children.forEach { node in
                if node is SKSpriteNode && node.name != "cameraButton" {
                    node.removeFromParent()
                }
            }
            
            // Add new image
            let texture = SKTexture(image: image)
            let imageNode = SKSpriteNode(texture: texture)
            imageNode.size = CGSize(width: 80, height: 80)
            imageNode.position = .zero
            
            // Circular mask
            let mask = SKShapeNode(circleOfRadius: 40)
            mask.fillColor = .white
            
            let cropNode = SKCropNode()
            cropNode.maskNode = mask
            cropNode.addChild(imageNode)
            
            avatarContainer.addChild(cropNode)
        }
    }
}

// SKTexture extension removed - using shared extension from AuthenticationScene.swift
