import SpriteKit

// MARK: - Yeti and Snowball hazards for mountain maps

final class YetiNode: SKSpriteNode {
    enum State { case idle, telegraph, throwSnowball, cooldown }
    var state: State = .idle
    var lastThrowTime: TimeInterval = 0
    var telegraphMs: Int = 300
    var cooldownMs: Int = 1200
    var snowballSpeed: CGFloat = 240
    var snowballArc: CGFloat = 0.55
    var allowBounce: Bool = false
    var bounceLoss: CGFloat = 0.4
    weak var sceneRef: SKScene?

    func configureForDifficulty(stars: Int) {
        switch stars {
        case 3:
            telegraphMs = Int.random(in: 250...320)
            cooldownMs = Int.random(in: 900...1100)
            snowballSpeed *= 1.15
        default:
            telegraphMs = Int.random(in: 300...400)
            cooldownMs = Int.random(in: 1100...1400)
            break
        }
    }

    func attemptThrow(currentTime: TimeInterval) {
        guard let scene = sceneRef else { return }
        if state == .idle || state == .cooldown {
            if (currentTime - lastThrowTime) * 1000.0 >= Double(cooldownMs) {
                telegraphThenThrow(in: scene)
            }
        }
    }

    private func telegraphThenThrow(in scene: SKScene) {
        state = .telegraph
        // Simple arm-raise telegraph via scale/rotation
        let raise = SKAction.group([
            SKAction.rotate(byAngle: 0.12, duration: Double(telegraphMs)/1000.0),
            SKAction.scale(to: 1.08, duration: Double(telegraphMs)/1000.0)
        ])
        let whoosh = SKAction.playSoundFileNamed("whoosh.caf", waitForCompletion: false)
        let throwAction = SKAction.run { [weak self] in self?.performThrow(in: scene) }
        let cd = SKAction.run { [weak self] in self?.enterCooldown() }
        let seq = SKAction.sequence([raise, whoosh, throwAction, cd])
        run(seq)
    }

    private func performThrow(in scene: SKScene) {
        guard let parent = parent else { return }
        state = .throwSnowball
        lastThrowTime = scene.currentTime()
        let ball = SnowballNode(radius: 6)
        ball.position = CGPoint(x: position.x + 16, y: position.y + 20)
        ball.zPosition = zPosition + 1
        ball.configure(speed: snowballSpeed, arc: snowballArc, allowBounce: allowBounce, bounceLoss: bounceLoss)
        parent.addChild(ball)
        ball.launch()
    }

    private func enterCooldown() { state = .cooldown }
}

final class SnowballNode: SKShapeNode {
    private var initialVelocity: CGVector = .zero
    private var allowBounce = false
    private var bounceLoss: CGFloat = 0.4

    convenience init(radius: CGFloat) {
        self.init(circleOfRadius: radius)
        fillColor = .white
        strokeColor = UIColor(white: 0.9, alpha: 1.0)
        lineWidth = 1
        name = "snowball"
        zPosition = 15
        // Slightly inset collider to avoid unfair edge hits
        physicsBody = SKPhysicsBody(circleOfRadius: radius - 2)
        physicsBody?.affectedByGravity = true
        physicsBody?.allowsRotation = false
        physicsBody?.linearDamping = 0.1
        physicsBody?.categoryBitMask = 1 << 20
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 0
    }

    func configure(speed: CGFloat, arc: CGFloat, allowBounce: Bool, bounceLoss: CGFloat) {
        self.allowBounce = allowBounce
        self.bounceLoss = bounceLoss
        initialVelocity = CGVector(dx: speed, dy: speed * arc)
    }

    func launch() {
        physicsBody?.velocity = initialVelocity
    }

    func step(currentTime: TimeInterval) {
        guard allowBounce, let body = physicsBody else { return }
        // Simple ground hit detection at y ~ 60 (approx ground height)
        if position.y <= 62 && body.velocity.dy < 0 {
            body.velocity = CGVector(dx: body.velocity.dx * (1.0 - bounceLoss),
                                     dy: abs(body.velocity.dy) * (1.0 - bounceLoss))
        }
    }
}

private extension SKScene {
    func currentTime() -> TimeInterval { return (view?.preferredFramesPerSecond ?? 60) > 0 ? CACurrentMediaTime() : CACurrentMediaTime() }
}


