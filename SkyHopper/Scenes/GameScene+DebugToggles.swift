import SpriteKit

extension GameScene {
    func applyDebugToggles() {
        let dbg = DebugMenu.shared
        // Lighting on/off
        enumerateChildNodes(withName: "//*") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.lightingBitMask = dbg.lightingEnabled ? LightingMasks.both : 0
            }
        }
        // Grading on/off
        childNode(withName: "visualGrade")?.isHidden = !dbg.gradingEnabled
        // Overdraw view
        OverdrawDebug.apply(to: self, enabled: dbg.overdrawEnabled)
    }
}


