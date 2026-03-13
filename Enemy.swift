import SpriteKit

final class Enemy: SKShapeNode {
    let destroyThreshold: CGFloat = 10

    init(position: CGPoint) {
        super.init()
        let size = CGSize(width: 32, height: 32)
        path = CGPath(rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), transform: nil)
        fillColor = .systemRed
        strokeColor = .clear
        self.position = position
        name = "enemy"

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.affectedByGravity = true
        physicsBody?.allowsRotation = true
        physicsBody?.friction = 0.8
        physicsBody?.restitution = 0.1
        physicsBody?.mass = 0.6
        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.collisionBitMask = PhysicsCategory.world | PhysicsCategory.projectile | PhysicsCategory.block | PhysicsCategory.enemy
        physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.block
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
