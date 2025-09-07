import SpriteKit

/// Simple parallax container that scrolls its children based on a speed factor.
final class ParallaxLayer: SKNode {
    /// Points per second to scroll left. Positive values move to the left.
    let speedPointsPerSecond: CGFloat
    private var lastUpdate: TimeInterval = 0

    init(speed: CGFloat) {
        self.speedPointsPerSecond = speed
        super.init()
        zPosition = UIConstants.Z.background
    }

    required init?(coder: NSCoder) {
        self.speedPointsPerSecond = 10
        super.init(coder: coder)
    }

    func addRepeating(node: SKNode, spacing: CGFloat) {
        // Duplicate node to fill width twice for seamless scroll
        let n1 = node
        let n2 = node.copy() as! SKNode
        n1.position = .zero
        n2.position = CGPoint(x: (node.calculateAccumulatedFrame().width + spacing), y: 0)
        addChild(n1)
        addChild(n2)
    }

    func update(currentTime: TimeInterval) {
        if lastUpdate == 0 { lastUpdate = currentTime; return }
        let dt = CGFloat(currentTime - lastUpdate)
        lastUpdate = currentTime
        let dx = -speedPointsPerSecond * dt
        for child in children {
            child.position.x += dx
        }
        // Wrap-around
        let width = calculateAccumulatedFrame().width / 2
        for child in children {
            if child.position.x < -width { child.position.x += width * 2 }
        }
    }
}


