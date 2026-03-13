import SpriteKit

final class TrajectoryHelper {
    private weak var parent: SKNode?
    private var dots: [SKShapeNode] = []

    private let maxPoints = 20
    private let step: CGFloat = 0.12

    init(parent: SKNode) {
        self.parent = parent
    }

    func drawTrajectory(from origin: CGPoint, dragVector: CGVector) {
        clear()

        let velocity = CGVector(dx: dragVector.dx * 0.3 * 12, dy: dragVector.dy * 0.3 * 12)
        let gravity: CGFloat = -9.8

        for i in 0..<maxPoints {
            let t = CGFloat(i) * step
            let x = origin.x + velocity.dx * t
            let y = origin.y + velocity.dy * t + 0.5 * gravity * t * t
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = .gray
            dot.strokeColor = .clear
            dot.position = CGPoint(x: x, y: y)
            dot.zPosition = 20

            dots.append(dot)
            parent?.addChild(dot)
        }
    }

    func clear() {
        dots.forEach { $0.removeFromParent() }
        dots.removeAll()
    }
}
