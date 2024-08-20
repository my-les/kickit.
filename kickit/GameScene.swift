//
//  GameScene.swift
//  kickit
//
//  Created by myle$ on 7/15/24.
//

import Foundation
import SpriteKit

class GameScene: SKScene {
    enum ScreenEdge: Int {
        case top = 0, right = 1, bottom = 2, left = 3
    }

    enum GameState {
        case ready, playing, gameOver
    }

    private let radius: CGFloat = 10
    private let playerAnimationDuration = 5.0
    private let enemySpeed: CGFloat = 60 // points per second
    private var colors: [UIColor] = [.green, .blue, .yellow, .orange, .red, .purple, .gray, .black]

    private var player: SKShapeNode!
    private var enemies: [SKShapeNode] = []
    private var gameState: GameState = .ready

    private var startTime: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0

    private var clockLabel: SKLabelNode!
    private var bestTimeLabel: SKLabelNode!

    // MARK: - State Variables
    @Published var playerPosition: CGPoint = CGPoint(x: 200, y: 400)
    @Published var enemyPositions: [CGPoint] = []
    @Published var bestTime: String = "00:00.000"
    @Published var startLabelVisible: Bool = true

    override func didMove(to view: SKView) {
        backgroundColor = .white
        setupPlayer()
        setupLabels()
        prepareGame()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch gameState {
        case .ready:
            startGame()
        case .playing:
            movePlayer(to: location)
            moveEnemies(to: location)
        case .gameOver:
            break
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if gameState == .playing {
            if startTime == 0 {
                startTime = currentTime
            }
            elapsedTime = currentTime - startTime
            clockLabel.text = format(timeInterval: elapsedTime)
            checkCollision()
        }
    }

    private func setupPlayer() {
        player = SKShapeNode(circleOfRadius: radius)
        player.fillColor = .blue
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    private func setupLabels() {
        clockLabel = SKLabelNode(text: "00:00.000")
        clockLabel.position = CGPoint(x: size.width / 2, y: size.height - 40)
        clockLabel.fontColor = .black
        addChild(clockLabel)

        bestTimeLabel = SKLabelNode(text: "Best Time: 00:00.000")
        bestTimeLabel.position = CGPoint(x: size.width / 2, y: size.height - 70)
        bestTimeLabel.fontColor = .black
        addChild(bestTimeLabel)
    }

    private func prepareGame() {
        // Set up the game state
        gameState = .ready
        startTime = 0
        elapsedTime = 0
        clockLabel.text = "00:00.000"
        bestTimeLabel.text = "Best Time: \(UserDefaults.standard.string(forKey: "bestTime") ?? "00:00.000")"

        // Remove all enemies
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()

        // Center the player
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func startGame() {
        gameState = .playing
        startTime = 0
        elapsedTime = 0
        clockLabel.text = "00:00.000"

        let generateEnemyAction = SKAction.run { [weak self] in
            self?.generateEnemy()
        }
        let waitAction = SKAction.wait(forDuration: 2.0)
        let sequenceAction = SKAction.sequence([generateEnemyAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        run(repeatAction, withKey: "enemyGenerator")
    }

    private func gameOver() {


        let bestTime = UserDefaults.standard.string(forKey: "bestTime") ?? "00:00.000"
        if format(timeInterval: elapsedTime) < bestTime {
            UserDefaults.standard.set(format(timeInterval: elapsedTime), forKey: "bestTime")
        }

        gameState = .gameOver
        removeAction(forKey: "enemyGenerator")

        prepareGame()
    }

    private func generateEnemy() {
        let screenEdge = ScreenEdge(rawValue: Int(arc4random_uniform(4)))!
        var position: CGPoint = .zero

        switch screenEdge {
        case .left:
            position = CGPoint(x: 0, y: CGFloat(arc4random_uniform(UInt32(size.height))))
        case .right:
            position = CGPoint(x: size.width, y: CGFloat(arc4random_uniform(UInt32(size.height))))
        case .top:
            position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(size.width))), y: size.height)
        case .bottom:
            position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(size.width))), y: 0)
        }

        let enemy = SKShapeNode(circleOfRadius: radius)
        enemy.fillColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        enemy.position = position
        addChild(enemy)

        let duration = getEnemyDuration(enemy: enemy)
        let moveAction = SKAction.move(to: player.position, duration: duration)
        enemy.run(moveAction)

        enemies.append(enemy)
    }

    private func movePlayer(to location: CGPoint) {
        let moveAction = SKAction.move(to: location, duration: playerAnimationDuration)
        player.run(moveAction)
    }

    private func moveEnemies(to location: CGPoint) {
        for enemy in enemies {
            let duration = getEnemyDuration(enemy: enemy)
            let moveAction = SKAction.move(to: location, duration: duration)
            enemy.run(moveAction)
        }
    }

    private func getEnemyDuration(enemy: SKShapeNode) -> TimeInterval {
        let dx = player.position.x - enemy.position.x
        let dy = player.position.y - enemy.position.y
        return TimeInterval(sqrt(dx * dx + dy * dy) / enemySpeed)
    }

    private func format(timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let milliseconds = Int(timeInterval * 1000) % 1000
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    private func checkCollision() {
        for enemy in enemies {
            if enemy.frame.intersects(player.frame) {
                gameOver()
                break
            }
        }
    }
}
