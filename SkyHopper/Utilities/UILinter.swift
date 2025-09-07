import SpriteKit

#if DEBUG
enum UILinter {
    static func run(scene: SKScene, topBar: SKNode?) {
        validateSafeArea(scene: scene, topBar: topBar)
        validateTapTargets(in: scene)
        validateTextContrast(in: scene)
    }

    private static func validateSafeArea(scene: SKScene, topBar: SKNode?) {
        guard let topBar = topBar else { return }
        let safeTop = scene.view?.safeAreaInsets.top ?? 44
        // Any node in topBar should not be above safeTop inset from top
        for child in topBar.children {
            let y = child.position.y
            if y > scene.size.height - safeTop + 1 {
                print("[UILint] Node \(child.name ?? "<unnamed>") intrudes into notch area")
            }
        }
    }

    private static func validateTapTargets(in scene: SKScene) {
        scene.enumerateChildNodes(withName: "**") { node, _ in
            guard let shape = node as? SKShapeNode else { return }
            if let name = node.name?.lowercased(), name.contains("button") {
                let frame = shape.frame
                if frame.width < 44 || frame.height < 44 {
                    print("[UILint] Tap target <44pt for \(name): \(Int(frame.width))x\(Int(frame.height))")
                }
            }
        }
    }

    private static func contrastRatio(_ c1: UIColor, _ c2: UIColor) -> CGFloat {
        func luminance(_ c: UIColor) -> CGFloat {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            func adjust(_ v: CGFloat) -> CGFloat { v <= 0.03928 ? v/12.92 : pow((v + 0.055)/1.055, 2.4) }
            let L = 0.2126*adjust(r) + 0.7152*adjust(g) + 0.0722*adjust(b)
            return L
        }
        let l1 = luminance(c1) + 0.05
        let l2 = luminance(c2) + 0.05
        return max(l1,l2)/min(l1,l2)
    }

    private static func validateTextContrast(in scene: SKScene) {
        let background = scene.backgroundColor
        scene.enumerateChildNodes(withName: "**") { node, _ in
            guard let label = node as? SKLabelNode, let color = label.fontColor else { return }
            let ratio = contrastRatio(background, color)
            if ratio < 4.5 {
                print("[UILint] Low contrast (\(String(format: "%.2f", ratio))) for label \(label.text ?? "<text>")")
            }
        }
    }
}
#endif


