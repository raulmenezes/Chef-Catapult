import SpriteKit

final class Projectile: SKShapeNode {
    let radius: CGFloat = 20
    private(set) var isLaunched = false

    var canLaunch: Bool { !isLaunched }

    init(position: CGPoint) {
        super.init()
        path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        fillColor = .systemBlue
        strokeColor = .clear
        self.position = position
        name = "projectile"

        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.affectedByGravity = true
        physicsBody?.allowsRotation = true
        physicsBody?.linearDamping = 0.25
        physicsBody?.friction = 0.5
        physicsBody?.restitution = 0.2
        physicsBody?.mass = 0.8
        physicsBody?.categoryBitMask = PhysicsCategory.projectile
        physicsBody?.collisionBitMask = PhysicsCategory.world | PhysicsCategory.enemy | PhysicsCategory.block
        physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.block
        physicsBody?.isDynamic = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func launch(with impulse: CGVector) {
        guard !isLaunched else { return }
        isLaunched = true
        physicsBody?.isDynamic = true
        physicsBody?.applyImpulse(impulse)
    }
}
