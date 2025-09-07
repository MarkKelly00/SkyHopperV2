import SpriteKit

/// Utilities for working with safe areas (notch/Dynamic Island) in SpriteKit scenes.
/// Provides helpers to position top-bar UI consistently across devices and orientations.
final class SafeAreaLayout {
    private unowned let scene: SKScene

    init(scene: SKScene) {
        self.scene = scene
    }

    /// Top safe Y coordinate in scene space.
    func safeTopY(offset: CGFloat = 0) -> CGFloat {
        let inset = scene.view?.safeAreaInsets.top ?? 44
        return scene.size.height - inset - offset
    }

    /// Left safe X coordinate in scene space.
    func safeLeftX(offset: CGFloat = 0) -> CGFloat {
        let inset = scene.view?.safeAreaInsets.left ?? 0
        return inset + offset
    }

    /// Right safe X coordinate in scene space.
    func safeRightX(offset: CGFloat = 0) -> CGFloat {
        let inset = scene.view?.safeAreaInsets.right ?? 0
        return scene.size.width - inset - offset
    }

    /// Bottom safe Y coordinate in scene space.
    func safeBottomY(offset: CGFloat = 0) -> CGFloat {
        let inset = scene.view?.safeAreaInsets.bottom ?? 34
        return inset + offset
    }

    /// Creates a container node positioned to the safe-area top band.
    /// Place back button, title, and tab strip inside this container.
    func createTopBarContainer() -> SKNode {
        let container = SKNode()
        container.zPosition = UIConstants.Z.topBar
        scene.addChild(container)
        return container
    }
}


