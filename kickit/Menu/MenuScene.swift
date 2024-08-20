import Foundation
import SpriteKit


class MenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        createMenu()
    }

    private func createMenu() {
        let startButton = createButton(text: "play", name: "startButton", position: CGPoint(x: size.width / 2, y: size.height / 2 + 40))
        addChild(startButton)

        let aboutButton = createButton(text: "how2play", name: "aboutButton", position: CGPoint(x: size.width / 2, y: size.height / 2 - 40))
        addChild(aboutButton)
    }

    private func createButton(text: String, name: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(text: text)
        button.name = name
        button.position = position
        button.fontColor = .black
        button.fontName = "CourierNewPS-BoldMT"
        return button
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)

        switch node.name {
        case "startButton":
            NotificationCenter.default.post(name: .startGame, object: nil)
        case "aboutButton":
            NotificationCenter.default.post(name: .showAbout, object: nil)
        default:
            break
        }
    }
}

extension Notification.Name {
    static let startGame = Notification.Name("startGame")
    static let showHighScores = Notification.Name("showHighScores")
    static let showAbout = Notification.Name("showAbout")
}
