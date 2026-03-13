import SpriteKit

final class GameUI {
    private weak var scene: SKScene?

    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let projectileLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private let resetButton = SKShapeNode(rectOf: CGSize(width: 110, height: 40), cornerRadius: 8)
    private let resetText = SKLabelNode(fontNamed: "AvenirNext-Bold")

    var onResetTapped: (() -> Void)?

    init(scene: SKScene) {
        self.scene = scene
        setupUI()
    }

    private func setupUI() {
        guard let scene else { return }

        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .black
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: scene.frame.maxY - 56)
        scoreLabel.zPosition = 50

        projectileLabel.fontSize = 18
        projectileLabel.fontColor = .black
        projectileLabel.horizontalAlignmentMode = .right
        projectileLabel.position = CGPoint(x: scene.frame.maxX - 20, y: scene.frame.maxY - 54)
        projectileLabel.zPosition = 50

        resetButton.fillColor = .systemTeal
        resetButton.strokeColor = .clear
        resetButton.position = CGPoint(x: scene.frame.midX, y: scene.frame.maxY - 56)
        resetButton.zPosition = 50
        resetButton.name = "resetButton"

        resetText.text = "Reset Ball"
        resetText.fontSize = 16
        resetText.verticalAlignmentMode = .center
        resetText.fontColor = .white
        resetText.zPosition = 51
        resetText.name = "resetButton"
        resetText.position = CGPoint(x: 0, y: -1)
        resetButton.addChild(resetText)

        messageLabel.fontSize = 36
        messageLabel.fontColor = .black
        messageLabel.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY + 120)
        messageLabel.zPosition = 60

        scene.addChild(scoreLabel)
        scene.addChild(projectileLabel)
        scene.addChild(resetButton)
        scene.addChild(messageLabel)
    }

    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
    }

    func updateProjectiles(remaining: Int) {
        projectileLabel.text = "Balls: \(remaining)"
    }

    func showMessage(_ text: String) {
        messageLabel.text = text
    }

    @discardableResult
    func handleTouch(at point: CGPoint) -> Bool {
        guard let scene else { return false }
        let touchedNodes = scene.nodes(at: point)
        if touchedNodes.contains(where: { $0.name == "resetButton" }) {
            onResetTapped?()
            return true
        }
        return false
    }
}
