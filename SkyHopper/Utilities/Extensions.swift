import SpriteKit
import UIKit

// MARK: - SKTexture Extension

extension SKTexture {
    /// Creates a texture by drawing into a graphics context
    convenience init(size: CGSize, drawing: (CGSize, CGContext) -> Void) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        drawing(size, context)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.init(image: image)
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    /// Creates a color from hex string
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue:  CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - CGPoint Extensions

extension CGPoint {
    /// Distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    /// Angle to another point in radians
    func angle(to point: CGPoint) -> CGFloat {
        return atan2(point.y - y, point.x - x)
    }
}

// MARK: - SKNode Extensions

extension SKNode {
    /// Removes all actions and children
    func cleanup() {
        removeAllActions()
        removeAllChildren()
    }
    
    /// Runs an action with a completion handler
    func run(_ action: SKAction, completion: @escaping () -> Void) {
        run(SKAction.sequence([action, SKAction.run(completion)]))
    }
}
