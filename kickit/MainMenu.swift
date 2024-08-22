//
//  MainMenu.swift
//  kickit
//
//  Created by myle$ on 8/12/24.
//

import SpriteKit

class MainMenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black

        // Create the title label
        let titleLabel = SKLabelNode(text: "My Game")
        titleLabel.fontName = "CourierNewPS-BoldMT"
        titleLabel.fontSize = 50
        titleLabel.fontColor = .brown
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        addChild(titleLabel)

        // Create the Play button
        let playButton = createButton(withText: "Play", name: "playButton", position: CGPoint(x: size.width / 2, y: size.height / 2))
        addChild(playButton)

        // Create the About button
        let aboutButton = createButton(withText: "About", name: "aboutButton", position: CGPoint(x: size.width / 2, y: size.height / 2 - 60))
        addChild(aboutButton)

        // Create the High Scores button
        let highScoresButton = createButton(withText: "High Scores", name: "highScoresButton", position: CGPoint(x: size.width / 2, y: size.height / 2 - 120))
        addChild(highScoresButton)
    }

    private func createButton(withText text: String, name: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(text: text)
        button.fontName = "CourierNewPS-BoldMT"
        button.fontSize = 40
        button.fontColor = .blue
        button.position = position
        button.name = name
        return button
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)

        for node in nodes {
            if node.name == "playButton" {
                view?.presentScene(GameScene(gameCenterManager: GameCenterManager()), transition: .flipHorizontal(withDuration: 0.5))
            } else if node.name == "aboutButton" {
                showAlert(withTitle: "About", message: "This is a fun game where you chase emojis!")
            } else if node.name == "highScoresButton" {
                showAlert(withTitle: "High Scores", message: "High scores will be available here.")
            }
        }
    }

    private func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        if let viewController = view?.window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
