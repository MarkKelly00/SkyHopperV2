import SpriteKit

class AchievementScene: SKScene {
    
    // UI Elements
    private var scrollContainer: SKNode!
    private var achievementNodes: [SKNode] = []
    private var contentHeight: CGFloat = 0
    private var topBarContainer: SKNode!
    
    // Layout constants
    private let itemHeight: CGFloat = 90
    private let itemSpacing: CGFloat = 15
    private let contentInset: CGFloat = 25
    private let sectionSpacing: CGFloat = 30
    
    // Scroll properties
    private var startingYPosition: CGFloat = 0
    private var isScrolling = false
    private var lastTouchPosition: CGPoint = CGPoint.zero
    private var scrollVelocity: CGFloat = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        setupUI()
        loadAchievements()
    }
    
    private func setupUI() {
        // Add safe area top bar with back button
        topBarContainer = SafeAreaTopBar.build(in: self, title: "Achievements") { [weak self] in
            // Navigate back to main menu
            let transition = SKTransition.fade(withDuration: 0.3)
            let mainMenuScene = MainMenuScene(size: self?.size ?? CGSize.zero)
            mainMenuScene.scaleMode = .aspectFill
            self?.view?.presentScene(mainMenuScene, transition: transition)
        }
        
        // Create scroll container positioned below the top bar
        let safe = SafeAreaLayout(scene: self)
        let topBarBottomY = topBarContainer.userData?["topBarBottomY"] as? CGFloat ?? safe.safeTopY(offset: 120)
        
        scrollContainer = SKNode()
        scrollContainer.name = "scrollContainer"
        addChild(scrollContainer)
        
        startingYPosition = topBarBottomY - 20 // Start content below top bar
    }
    
    private func loadAchievements() {
        let achievementManager = AchievementManager.shared
        
        // Get achievement categories
        let completed = achievementManager.getCompletedAchievements()
        let inProgress = achievementManager.getInProgressAchievements()
        let locked = achievementManager.getLockedAchievements()
        
        var currentY = startingYPosition
        
        // Completed Achievements Section
        if !completed.isEmpty {
            currentY = createSectionHeader(title: "🏆 Completed (\(completed.count))", yPosition: currentY)
            for achievement in completed {
                currentY = createAchievementItem(achievement: achievement, yPosition: currentY, isCompleted: true)
            }
            currentY -= sectionSpacing
        }
        
        // In Progress Achievements Section
        if !inProgress.isEmpty {
            currentY = createSectionHeader(title: "⚡ In Progress (\(inProgress.count))", yPosition: currentY)
            for achievement in inProgress {
                currentY = createAchievementItem(achievement: achievement, yPosition: currentY, isCompleted: false)
            }
            currentY -= sectionSpacing
        }
        
        // Locked Achievements Section
        if !locked.isEmpty {
            currentY = createSectionHeader(title: "🔒 Locked (\(locked.count))", yPosition: currentY)
            for achievement in locked {
                currentY = createAchievementItem(achievement: achievement, yPosition: currentY, isCompleted: false)
            }
            currentY -= sectionSpacing
        }
        
        // Add stats summary at the bottom
        currentY -= 20
        let finalY = createStatsSection(yPosition: currentY)
        
        // Calculate total content height for scrolling
        contentHeight = startingYPosition - finalY + 120
    }
    
    private func createSectionHeader(title: String, yPosition: CGFloat) -> CGFloat {
        let headerContainer = SKNode()
        
        // Section header background
        let headerBg = SKShapeNode(rectOf: CGSize(width: size.width - contentInset * 2, height: 35), cornerRadius: 8)
        headerBg.fillColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.8)
        headerBg.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        headerBg.lineWidth = 1
        headerBg.position = CGPoint(x: size.width/2, y: yPosition - 17.5)
        headerContainer.addChild(headerBg)
        
        let headerLabel = SKLabelNode(text: title)
        headerLabel.fontName = UIConstants.Text.boldFont
        headerLabel.fontSize = 20
        headerLabel.fontColor = UIColor.white
        headerLabel.horizontalAlignmentMode = .left
        headerLabel.verticalAlignmentMode = .center
        headerLabel.position = CGPoint(x: contentInset + 10, y: yPosition - 17.5)
        headerContainer.addChild(headerLabel)
        
        scrollContainer.addChild(headerContainer)
        achievementNodes.append(headerContainer)
        
        return yPosition - 50
    }
    
    private func createAchievementItem(achievement: AchievementManager.Achievement, yPosition: CGFloat, isCompleted: Bool) -> CGFloat {
        let container = SKNode()
        
        // Calculate card dimensions and positioning
        let cardWidth = size.width - contentInset * 2
        let cardHeight = itemHeight
        let cardCenterX = size.width / 2
        let cardCenterY = yPosition - cardHeight / 2
        
        // Background with proper anchor point alignment
        let background = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 12)
        if isCompleted {
            background.fillColor = UIColor(red: 0.1, green: 0.4, blue: 0.2, alpha: 0.4)
            background.strokeColor = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 0.8)
        } else if achievement.progress > 0 {
            background.fillColor = UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.3)
            background.strokeColor = UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 0.8)
        } else {
            background.fillColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.6)
            background.strokeColor = UIColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 0.8)
        }
        background.lineWidth = 2
        background.position = CGPoint(x: cardCenterX, y: cardCenterY)
        container.addChild(background)
        
        // Define consistent layout zones within the card
        let iconZoneX = contentInset + 30 // Icon zone - 30px from left edge
        let contentStartX = contentInset + 70 // Content starts after icon zone
        let rightZoneX = size.width - contentInset - 80 // Right zone for points/progress
        
        // Status icon - centered in icon zone
        let statusIcon = SKLabelNode()
        if isCompleted {
            statusIcon.text = "✅"
        } else if achievement.progress > 0 {
            statusIcon.text = "⚡"
        } else {
            statusIcon.text = "🔒"
        }
        statusIcon.fontSize = 28
        statusIcon.horizontalAlignmentMode = .center
        statusIcon.verticalAlignmentMode = .center
        statusIcon.position = CGPoint(x: iconZoneX, y: cardCenterY)
        container.addChild(statusIcon)
        
        // Achievement name - properly aligned in content zone
        let nameLabel = SKLabelNode(text: achievement.name)
        nameLabel.fontName = UIConstants.Text.boldFont
        nameLabel.fontSize = 18
        if isCompleted {
            nameLabel.fontColor = UIColor(red: 0.7, green: 1.0, blue: 0.7, alpha: 1.0)
        } else if achievement.progress > 0 {
            nameLabel.fontColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        } else {
            nameLabel.fontColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        }
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: contentStartX, y: cardCenterY + 12)
        container.addChild(nameLabel)
        
        // Achievement description - aligned below name
        let maxDescriptionWidth = rightZoneX - contentStartX - 20
        let descLabel = createWrappedLabel(text: achievement.description, maxWidth: maxDescriptionWidth, fontSize: 14)
        descLabel.fontColor = UIColor(red: 0.8, green: 0.8, blue: 0.85, alpha: 1.0)
        descLabel.horizontalAlignmentMode = .left
        descLabel.verticalAlignmentMode = .center
        descLabel.position = CGPoint(x: contentStartX, y: cardCenterY - 12)
        container.addChild(descLabel)
        
        // Points indicator - centered in right zone
        let pointsBg = SKShapeNode(rectOf: CGSize(width: 60, height: 22), cornerRadius: 11)
        pointsBg.fillColor = UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 0.3)
        pointsBg.strokeColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        pointsBg.lineWidth = 1
        pointsBg.position = CGPoint(x: rightZoneX, y: cardCenterY + 18)
        container.addChild(pointsBg)
        
        let pointsLabel = SKLabelNode(text: "+\(achievement.points)")
        pointsLabel.fontName = UIConstants.Text.boldFont
        pointsLabel.fontSize = 13
        pointsLabel.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        pointsLabel.horizontalAlignmentMode = .center
        pointsLabel.verticalAlignmentMode = .center
        pointsLabel.position = CGPoint(x: rightZoneX, y: cardCenterY + 18)
        container.addChild(pointsLabel)
        
        // Progress bar for in-progress achievements - centered in right zone
        if !isCompleted && achievement.progress > 0 {
            let progressBarWidth: CGFloat = 100
            let progressBarHeight: CGFloat = 6
            
            // Progress background
            let progressBg = SKShapeNode(rectOf: CGSize(width: progressBarWidth, height: progressBarHeight), cornerRadius: 3)
            progressBg.fillColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
            progressBg.strokeColor = UIColor.clear
            progressBg.position = CGPoint(x: rightZoneX, y: cardCenterY - 8)
            container.addChild(progressBg)
            
            // Progress fill
            let fillWidth = progressBarWidth * CGFloat(achievement.progress)
            let progressFill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: progressBarHeight), cornerRadius: 3)
            progressFill.fillColor = UIColor(red: 0.1, green: 0.6, blue: 1.0, alpha: 0.9)
            progressFill.strokeColor = UIColor.clear
            // Position fill relative to background center, adjusted for different widths
            let offsetX = -(progressBarWidth - fillWidth) / 2
            progressFill.position = CGPoint(x: rightZoneX + offsetX, y: cardCenterY - 8)
            container.addChild(progressFill)
            
            // Progress percentage
            let progressText = SKLabelNode(text: "\(Int(achievement.progress * 100))%")
            progressText.fontName = UIConstants.Text.mediumFont
            progressText.fontSize = 11
            progressText.fontColor = UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0)
            progressText.horizontalAlignmentMode = .center
            progressText.verticalAlignmentMode = .center
            progressText.position = CGPoint(x: rightZoneX, y: cardCenterY - 22)
            container.addChild(progressText)
        }
        
        scrollContainer.addChild(container)
        achievementNodes.append(container)
        
        return yPosition - itemHeight - itemSpacing
    }
    
    private func createWrappedLabel(text: String, maxWidth: CGFloat, fontSize: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = UIConstants.Text.regularFont
        label.fontSize = fontSize
        
        // Simple truncation if text is too long
        if label.frame.width > maxWidth {
            var truncatedText = text
            while label.frame.width > maxWidth && truncatedText.count > 3 {
                truncatedText = String(truncatedText.dropLast())
                label.text = truncatedText + "..."
            }
        }
        
        return label
    }
    
    private func createStatsSection(yPosition: CGFloat) -> CGFloat {
        let achievementManager = AchievementManager.shared
        let totalAchievements = achievementManager.achievements.count
        let completedCount = achievementManager.getCompletedAchievements().count
        let totalPoints = achievementManager.getCompletedAchievements().reduce(0) { $0 + $1.points }
        
        let statsContainer = SKNode()
        
        // Stats background with better styling
        let statsBg = SKShapeNode(rectOf: CGSize(width: size.width - contentInset * 2, height: 120), cornerRadius: 16)
        statsBg.fillColor = UIColor(red: 0.1, green: 0.15, blue: 0.25, alpha: 0.8)
        statsBg.strokeColor = UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0)
        statsBg.lineWidth = 2
        statsBg.position = CGPoint(x: size.width/2, y: yPosition - 60)
        statsContainer.addChild(statsBg)
        
        // Stats title
        let statsTitle = SKLabelNode(text: "📊 Your Progress")
        statsTitle.fontName = UIConstants.Text.boldFont
        statsTitle.fontSize = 22
        statsTitle.fontColor = UIColor.white
        statsTitle.horizontalAlignmentMode = .center
        statsTitle.verticalAlignmentMode = .center
        statsTitle.position = CGPoint(x: size.width/2, y: yPosition - 25)
        statsContainer.addChild(statsTitle)
        
        // Completion percentage
        let completionPercent = totalAchievements > 0 ? (completedCount * 100) / totalAchievements : 0
        let completionLabel = SKLabelNode(text: "Completed: \(completedCount)/\(totalAchievements) (\(completionPercent)%)")
        completionLabel.fontName = UIConstants.Text.mediumFont
        completionLabel.fontSize = 17
        completionLabel.fontColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        completionLabel.horizontalAlignmentMode = .center
        completionLabel.verticalAlignmentMode = .center
        completionLabel.position = CGPoint(x: size.width/2, y: yPosition - 55)
        statsContainer.addChild(completionLabel)
        
        // Total points with icon
        let pointsLabel = SKLabelNode(text: "🏆 Total Points: \(totalPoints)")
        pointsLabel.fontName = UIConstants.Text.mediumFont
        pointsLabel.fontSize = 17
        pointsLabel.fontColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        pointsLabel.horizontalAlignmentMode = .center
        pointsLabel.verticalAlignmentMode = .center
        pointsLabel.position = CGPoint(x: size.width/2, y: yPosition - 80)
        statsContainer.addChild(pointsLabel)
        
        scrollContainer.addChild(statsContainer)
        achievementNodes.append(statsContainer)
        
        return yPosition - 120 // Return final Y position
    }
    
    // MARK: - Touch Handling for Scrolling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        // Store touch position for potential scrolling
        lastTouchPosition = touchLocation
        isScrolling = false
        
        // Always call super first to let back button handle touches
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPosition = touch.location(in: self)
        
        // Only handle scrolling if touch started in scrollable content area (below top bar)
        if lastTouchPosition.y <= startingYPosition {
            let deltaY = currentPosition.y - lastTouchPosition.y
            
            // Check if content needs scrolling
            let shouldScroll = contentHeight > (size.height - startingYPosition - 100)
            
            if shouldScroll && abs(deltaY) > 3 {
                // iOS-style scrolling:
                // Swipe UP (negative deltaY) = show content below (move container UP = positive position)
                // Swipe DOWN (positive deltaY) = show content above (move container DOWN = negative position)
                scrollContainer.position.y += deltaY  // iOS standard direction
                scrollVelocity = deltaY * 0.8 + scrollVelocity * 0.2  // Smooth velocity tracking
                
                // Calculate proper scroll bounds
                let availableHeight = size.height - startingYPosition - 100
                let contentOverflow = contentHeight - availableHeight
                
                // Scroll bounds:
                // maxScrollUp = contentOverflow (scroll up to show bottom content)
                // maxScrollDown = 0 (don't scroll below starting position)
                let maxScrollUp = max(0, contentOverflow)
                let maxScrollDown: CGFloat = 0
                
                // Apply bounds with rubber band effect
                if scrollContainer.position.y > maxScrollUp {
                    let overscroll = scrollContainer.position.y - maxScrollUp
                    scrollContainer.position.y = maxScrollUp + overscroll * 0.3
                } else if scrollContainer.position.y < maxScrollDown {
                    let overscroll = maxScrollDown - scrollContainer.position.y
                    scrollContainer.position.y = maxScrollDown - overscroll * 0.3
                }
                
                isScrolling = true
            }
            
            lastTouchPosition = currentPosition
        } else {
            // Touch is in top bar area, let super handle it (for back button)
            super.touchesMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Only call super if we weren't scrolling, to avoid interfering with back button
        if !isScrolling {
            super.touchesEnded(touches, with: event)
            return
        }
        isScrolling = false
        
        // Calculate scroll bounds
        let availableHeight = size.height - startingYPosition - 100
        let contentOverflow = contentHeight - availableHeight
        let maxScrollUp = max(0, contentOverflow)
        let maxScrollDown: CGFloat = 0
        
        // Snap back if overscrolled
        if scrollContainer.position.y > maxScrollUp {
            let snapBack = SKAction.moveTo(y: maxScrollUp, duration: 0.3)
            snapBack.timingMode = .easeOut
            scrollContainer.run(snapBack)
            return
        } else if scrollContainer.position.y < maxScrollDown {
            let snapBack = SKAction.moveTo(y: maxScrollDown, duration: 0.3)
            snapBack.timingMode = .easeOut
            scrollContainer.run(snapBack)
            return
        }
        
        // Apply momentum scrolling
        if abs(scrollVelocity) > 2 {
            let momentumDuration: TimeInterval = 0.8
            let friction: CGFloat = 0.95
            
            let deceleration = SKAction.customAction(withDuration: momentumDuration) { [weak self] _, elapsedTime in
                guard let self = self else { return }
                
                let decayFactor = pow(friction, elapsedTime * 60)
                let velocity = self.scrollVelocity * decayFactor * 0.15
                
                guard abs(velocity) > 0.1 else { return }
                
                self.scrollContainer.position.y += velocity
                
                // Clamp to bounds
                if self.scrollContainer.position.y > maxScrollUp {
                    self.scrollContainer.position.y = maxScrollUp
                    self.scrollContainer.removeAllActions()
                } else if self.scrollContainer.position.y < maxScrollDown {
                    self.scrollContainer.position.y = maxScrollDown
                    self.scrollContainer.removeAllActions()
                }
            }
            scrollContainer.run(deceleration, withKey: "momentum")
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        isScrolling = false
    }
}