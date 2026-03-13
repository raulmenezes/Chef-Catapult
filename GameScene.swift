import SpriteKit

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let projectile: UInt32 = 1 << 0
    static let enemy: UInt32 = 1 << 1
    static let block: UInt32 = 1 << 2
    static let world: UInt32 = 1 << 3
}

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private var projectile: Projectile?
    private var enemies: [Enemy] = []
    private var blocks: [Block] = []

    private let maxProjectiles = 3
    private var usedProjectiles = 0
    private var score = 0

    private var isAiming = false

    private let spawnPoint = CGPoint(x: 120, y: 180)

    private lazy var trajectoryHelper = TrajectoryHelper(parent: self)
    private lazy var gameUI = GameUI(scene: self)

    override func didMove(to view: SKView) {
        backgroundColor = .white
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        configureWorldBounds()
        createFloor()
        createTowerBlocks()
        createEnemies()
        setupUI()
        spawnProjectileIfPossible()
    }

    private func configureWorldBounds() {
        let body = SKPhysicsBody(edgeLoopFrom: frame)
        body.categoryBitMask = PhysicsCategory.world
        body.contactTestBitMask = PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.projectile | PhysicsCategory.enemy | PhysicsCategory.block
        physicsBody = body
    }

    private func createFloor() {
        let floor = SKShapeNode(rectOf: CGSize(width: frame.width, height: 36))
        floor.fillColor = .darkGray
        floor.strokeColor = .clear
        floor.position = CGPoint(x: frame.midX, y: 18)

        floor.physicsBody = SKPhysicsBody(rectangleOf: floor.frame.size)
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.categoryBitMask = PhysicsCategory.world
        floor.physicsBody?.friction = 0.8

        addChild(floor)
    }

    private func createTowerBlocks() {
        let baseX = frame.width - 150
        let baseY: CGFloat = 60
        let width: CGFloat = 48
        let height: CGFloat = 24

        for row in 0..<3 {
            for col in 0...(2 - row) {
                let x = baseX + CGFloat(col) * (width + 4) + CGFloat(row) * 24
                let y = baseY + CGFloat(row) * (height + 6)
                let block = Block(size: CGSize(width: width, height: height), position: CGPoint(x: x, y: y))
                blocks.append(block)
                addChild(block)
            }
        }
    }

    private func createEnemies() {
        let enemyPositions = [
            CGPoint(x: frame.width - 100, y: 170),
            CGPoint(x: frame.width - 165, y: 120),
            CGPoint(x: frame.width - 70, y: 120)
        ]

        enemyPositions.forEach { position in
            let enemy = Enemy(position: position)
            enemies.append(enemy)
            addChild(enemy)
        }
    }

    private func setupUI() {
        gameUI.updateScore(score)
        gameUI.updateProjectiles(remaining: maxProjectiles - usedProjectiles)

        gameUI.onResetTapped = { [weak self] in
            self?.forceSpawnProjectile()
        }
    }

    private func spawnProjectileIfPossible() {
        guard projectile == nil else { return }
        guard usedProjectiles < maxProjectiles else {
            showLoseIfNeeded()
            return
        }

        usedProjectiles += 1
        let newProjectile = Projectile(position: spawnPoint)
        projectile = newProjectile
        addChild(newProjectile)
        gameUI.updateProjectiles(remaining: maxProjectiles - usedProjectiles)
    }

    private func forceSpawnProjectile() {
        projectile?.removeFromParent()
        projectile = nil
        spawnProjectileIfPossible()
    }

    private func launchCurrentProjectile(with dragVector: CGVector) {
        guard let projectile else { return }
        guard projectile.canLaunch else { return }

        let multiplier: CGFloat = 0.3
        let impulse = CGVector(dx: dragVector.dx * multiplier, dy: dragVector.dy * multiplier)

        projectile.launch(with: impulse)
        isAiming = false
        trajectoryHelper.clear()

        let delay = SKAction.wait(forDuration: 2.0)
        let spawn = SKAction.run { [weak self] in
            self?.spawnProjectileIfPossible()
        }
        run(.sequence([delay, spawn]), withKey: "spawn-next")
    }

    private func removeEnemy(_ enemy: Enemy) {
        enemy.removeFromParent()
        enemies.removeAll(where: { $0 === enemy })
        score += 100
        gameUI.updateScore(score)
        showWinIfNeeded()
    }

    private func showWinIfNeeded() {
        guard enemies.isEmpty else { return }
        gameUI.showMessage("You Win!")
    }

    private func showLoseIfNeeded() {
        guard !enemies.isEmpty else { return }
        guard usedProjectiles >= maxProjectiles, projectile == nil || projectile?.parent == nil else { return }
        gameUI.showMessage("Out of Projectiles")
    }

    override func update(_ currentTime: TimeInterval) {
        if let projectile, projectile.isLaunched {
            if projectile.position.x > frame.maxX + 80 || projectile.position.y < -120 {
                projectile.removeFromParent()
                self.projectile = nil
                showLoseIfNeeded()
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let enemy = (contact.bodyA.node as? Enemy) ?? (contact.bodyB.node as? Enemy) else { return }

        let impactForce = CGFloat(contact.collisionImpulse)
        if impactForce >= enemy.destroyThreshold {
            removeEnemy(enemy)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if gameUI.handleTouch(at: point) { return }

        guard let projectile else { return }
        guard !projectile.isLaunched else { return }

        let dist = hypot(point.x - projectile.position.x, point.y - projectile.position.y)
        if dist <= projectile.radius + 24 {
            isAiming = true
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAiming, let touch = touches.first, let projectile else { return }
        let point = touch.location(in: self)

        let dx = projectile.position.x - point.x
        let dy = projectile.position.y - point.y
        let dragVector = CGVector(dx: dx, dy: dy)

        trajectoryHelper.drawTrajectory(from: projectile.position, dragVector: dragVector)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAiming, let touch = touches.first, let projectile else {
            isAiming = false
            trajectoryHelper.clear()
            return
        }

        let point = touch.location(in: self)
        let dragVector = CGVector(dx: projectile.position.x - point.x, dy: projectile.position.y - point.y)
        launchCurrentProjectile(with: dragVector)
    }
}
