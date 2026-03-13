import SpriteKit

final class Block: SKShapeNode {
    init(size: CGSize, position: CGPoint) {
        super.init()
        path = CGPath(rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), transform: nil)
        fillColor = .systemBrown
        strokeColor = .clear
        self.position = position
        name = "block"

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.affectedByGravity = true
        physicsBody?.allowsRotation = true
        physicsBody?.friction = 0.7
        physicsBody?.restitution = 0.05
        physicsBody?.mass = 1.1
        physicsBody?.categoryBitMask = PhysicsCategory.block
        physicsBody?.collisionBitMask = PhysicsCategory.world | PhysicsCategory.projectile | PhysicsCategory.enemy | PhysicsCategory.block
        physicsBody?.contactTestBitMask = PhysicsCategory.projectile
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
