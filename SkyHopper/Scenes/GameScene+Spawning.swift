import SpriteKit

extension GameScene {
    // Call from update() to drive hazard behavior when current map is mountain
    func updateMountainHazards(currentTime: TimeInterval) {
        guard MapManager.shared.currentMap == .mountain else { return }
        // Ensure Yetis exist at desired density
        let existingYetis = children.compactMap { $0 as? YetiNode }
        let profile = LevelProfiles.star3 // default tuning for mountain maps
        let maxConcurrent = profile.yetiMaxConcurrent ?? 2
        if existingYetis.count < maxConcurrent, Bool.random(percentage: profile.yetiSpawnChance ?? 30) {
            spawnYeti()
        }
        // Drive throws
        for yeti in existingYetis {
            yeti.attemptThrow(currentTime: currentTime)
        }
    }

    private func spawnYeti() {
        let yeti = YetiNode(color: UIColor(white: 0.95, alpha: 1.0), size: CGSize(width: 28, height: 38))
        yeti.sceneRef = self
        yeti.zPosition = 12
        yeti.position = CGPoint(x: size.width + 40, y: 80)
        yeti.configureForDifficulty(stars: MapManager.shared.currentMap.difficulty)
        addChild(yeti)
        // Move with the world speed (parallax adjusted minimal)
        let duration = TimeInterval((size.width + 100) / (obstacleSpeed))
        let move = SKAction.moveBy(x: -(size.width + 100), y: 0, duration: duration)
        let remove = SKAction.removeFromParent()
        yeti.run(SKAction.sequence([move, remove]))
    }
}


