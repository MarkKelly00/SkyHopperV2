import SpriteKit

enum LightingMasks {
    static let keyLight: UInt32 = 0b1
    static let fillLight: UInt32 = 0b10
    static let both: UInt32 = keyLight | fillLight
}

/// Centralized SpriteKit lighting setup using normal maps and two-point lighting.
enum LightingSystem {
    /// Adds two SKLightNodes (key/fill) and returns them for further tuning if needed.
    @discardableResult
    static func addDefaultLights(to scene: SKScene) -> (key: SKLightNode, fill: SKLightNode) {
        // Key light - warm, above-left
        let key = SKLightNode()
        key.categoryBitMask = LightingMasks.keyLight
        key.lightColor = UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0)
        key.ambientColor = UIColor(white: 0.15, alpha: 1.0)
        key.falloff = 1.0
        key.shadowColor = UIColor(white: 0.0, alpha: 0.65)
        key.position = CGPoint(x: scene.size.width * 0.25, y: scene.size.height * 0.8)
        key.zPosition = UIConstants.Z.ui
        scene.addChild(key)

        // Fill light - cool, above-right & dimmer
        let fill = SKLightNode()
        fill.categoryBitMask = LightingMasks.fillLight
        fill.lightColor = UIColor(red: 0.65, green: 0.75, blue: 1.0, alpha: 1.0)
        fill.ambientColor = UIColor(white: 0.1, alpha: 1.0)
        fill.falloff = 1.2
        fill.shadowColor = UIColor(white: 0.0, alpha: 0.4)
        fill.position = CGPoint(x: scene.size.width * 0.75, y: scene.size.height * 0.8)
        fill.zPosition = UIConstants.Z.ui
        scene.addChild(fill)

        return (key, fill)
    }

    /// Recursively applies lighting/normal-map settings to sprites in a subtree.
    static func applyLighting(to node: SKNode, lightingMask: UInt32 = LightingMasks.both) {
        if let sprite = node as? SKSpriteNode {
            sprite.lightingBitMask = lightingMask
            sprite.shadowCastBitMask = lightingMask
            sprite.shadowedBitMask = lightingMask

            // Attempt to attach a pre-generated normal texture if available ("asset.normals")
            if let texName = sprite.texture?.descriptionNameWithoutNoise(),
               SKTextureAtlasCheck.textureExists(named: texName + ".normals") {
                sprite.normalTexture = SKTexture(imageNamed: texName + ".normals")
            }
        }
        for child in node.children {
            applyLighting(to: child, lightingMask: lightingMask)
        }
    }
}

// MARK: - Helpers

private extension SKTexture {
    /// Extract an asset-like name from debug description if possible.
    func descriptionNameWithoutNoise() -> String? {
        // SKTexture description often contains the asset name in parentheses.
        // This is a best-effort extraction and safe no-op if it fails.
        let s = String(describing: self)
        if let start = s.firstIndex(of: "(") , let end = s.firstIndex(of: ")") , start < end {
            let inner = s[s.index(after: start)..<end]
            // Remove file extensions if present
            return inner.replacingOccurrences(of: ".png", with: "")
                       .replacingOccurrences(of: ".jpg", with: "")
        }
        return nil
    }
}

enum SKTextureAtlasCheck {
    /// Returns true if a texture with this name exists in any atlas or asset catalog.
    static func textureExists(named name: String) -> Bool {
        #if os(iOS)
        // Using UIImage to probe existence in asset catalogs
        if UIImage(named: name) != nil { return true }
        #endif
        // Fallback: try creating SKTexture (will assert if truly missing at runtime; avoid).
        return false
    }
}


