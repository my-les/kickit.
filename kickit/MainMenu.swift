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
        let titleLabel = SKLabelNode(text: "kickit.")
        titleLabel.fontName = "CourierNewPS-BoldMT"
        titleLabel.fontSize = 35
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        addChild(titleLabel)

        // Create the subtitle
        let subtitleLabel = SKLabelNode(text: "chase the money")
        subtitleLabel.fontName = "CourierNewPS-BoldMT"
        subtitleLabel.fontSize = 20
        subtitleLabel.fontColor = .green
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        addChild(subtitleLabel)

        // Create the Play button
        let playButton = createButton(withText: "play", name: "playButton", position: CGPoint(x: size.width / 2, y: size.height / 2))
        addChild(playButton)

        // Create the About button
        let aboutButton = createButton(withText: "about", name: "aboutButton", position: CGPoint(x: size.width / 2, y: size.height / 2 - 60))
        addChild(aboutButton)

        // Create the High Scores button
        let highScoresButton = createButton(withText: "high scores", name: "highScoresButton", position: CGPoint(x: size.width / 2, y: size.height / 2 - 120))
        addChild(highScoresButton)
    }

    private func createButton(withText text: String, name: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(text: text)
        button.fontName = "CourierNewPS-BoldMT"
        button.fontSize = 20
        button.fontColor = .darkGray
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
                showAlert(withTitle: "about", message:
                """
                    thank you for your support.

                this game is a friendly reminder to chase a check and avoid distractions :)

                1) tap where you want to go on screen...

                2) kick it from the opps

                3) get the munyun...

                hint: try to get the opps to collide.

                oh & $happybirthdaymyles if you wanna buy me coffee lol

                developed by @visionsofbillions

                bro @jptrsick produced the music
                """
                )
            } else if node.name == "highScoresButton" {


                if (view?.window?.rootViewController) != nil {
                    GameCenterManager.shared.showLeaderboard(for: "002")
                }
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
