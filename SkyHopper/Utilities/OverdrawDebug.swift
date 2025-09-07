import SpriteKit

/// Tints nodes by zPosition bands to reveal layering/overdraw.
enum OverdrawDebug {
    static func apply(to root: SKNode, enabled: Bool) {
        root.enumerateChildNodes(withName: "//*") { node, _ in
            if let sprite = node as? SKSpriteNode {
                if enabled {
                    let z = sprite.zPosition
                    let color: UIColor
                    switch z {
                    case ..<UIConstants.Z.background: color = .purple
                    case UIConstants.Z.background..<UIConstants.Z.decor: color = .blue
                    case UIConstants.Z.decor..<UIConstants.Z.content: color = .cyan
                    case UIConstants.Z.content..<UIConstants.Z.ui: color = .green
                    case UIConstants.Z.ui..<UIConstants.Z.topBar: color = .yellow
                    default: color = .red
                    }
                    sprite.colorBlendFactor = 0.6
                    sprite.color = color
                } else {
                    sprite.colorBlendFactor = 0.0
                }
            }
        }
    }
}


