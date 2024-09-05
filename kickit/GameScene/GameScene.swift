import Foundation
import SpriteKit
import UIKit
import GameKit
import AVFoundation

class GameScene: SKScene {

    enum ScreenEdge: Int {
        case top = 0, right, bottom, left
    }

    enum GameState {
        case ready, playing, gameOver
    }

    private let radius: CGFloat = 10
    private let playerAnimationDuration = 0.3
    private let enemySpeed: CGFloat = 10 // points per second
    private var lives = 3
    private var heartNodes: [SKSpriteNode] = []
    private var isInvincible = false
    private var player: SKLabelNode!
    private var enemies: [SKLabelNode] = []
    private var gameState: GameState = .ready

    private var startTime: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0

    private var clockLabel: SKLabelNode!
    private var bestTimeLabel: SKLabelNode!
    private var tapToStartLabel: SKLabelNode!
    private var backgroundMusicPlayer: AVAudioPlayer?

    private var score: Int = 0
    private var scoreLabel: SKLabelNode!

    private var bestScore: Int = 0
    private var bestScoreLabel: SKLabelNode!

    private var gameCenterManager: GameCenterManager?

    // Initialize with GameCenterManager
    init(gameCenterManager: GameCenterManager) {
        self.gameCenterManager = gameCenterManager
        super.init(size: CGSize(width: 300, height: 600))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupPlayer()
        setupLabels()
        prepareGame()
        playBackgroundMusic()

        bestScore = UserDefaults.standard.integer(forKey: "bestScore")
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
            checkCollisions()
        }
    }

    private func setupPlayer() {
        player = SKLabelNode(text: "🥷🏾") // Ninja emoji
        player.fontSize = 18
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    private func setupHearts() {
        for i in 0..<3 {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.position = CGPoint(x: 20 + (i * 20), y: Int(self.size.height) - 75)
            heart.size = CGSize(width: 12, height: 12)
            heart.zPosition = 100
            addChild(heart)
            heartNodes.append(heart)
        }
    }

    private func setupLabels() {
        clockLabel = SKLabelNode(text: "00:00.000")
        clockLabel.position = CGPoint(x: size.width / 2, y: size.height - 75)
        clockLabel.fontName = "CourierNewPS-BoldMT"
        clockLabel.fontColor = .white
        clockLabel.fontSize = 19
        addChild(clockLabel)

        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 95)
        scoreLabel.fontName = "CourierNewPS-BoldMT"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = .white
        addChild(scoreLabel)

        tapToStartLabel = SKLabelNode(text: "Tap to Start")
        tapToStartLabel.position = CGPoint(x: size.width / 2, y: size.height / 4)
        tapToStartLabel.fontName = "CourierNewPS-BoldMT"
        tapToStartLabel.fontColor = .white
        tapToStartLabel.fontSize = 19
        addChild(tapToStartLabel)
    }

    private func prepareGame() {
        gameState = .ready
        startTime = 0
        elapsedTime = 0
        clockLabel.text = "00:00.000"
        score = 0
        scoreLabel.text = "Score: 0"
        tapToStartLabel.isHidden = false
        setupHearts()


        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()

        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func startGame() {
        gameState = .playing
        startTime = 0
        elapsedTime = 0
        tapToStartLabel.isHidden = true


        let generateEnemyAction = SKAction.run { [weak self] in
            self?.generateEnemy()
        }
        let waitAction = SKAction.wait(forDuration: 1.0)
        let sequenceAction = SKAction.sequence([generateEnemyAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        run(repeatAction, withKey: "enemyGenerator")
    }

    private func gameOver() {
        gameState = .gameOver
        removeAction(forKey: "enemyGenerator")

        let formattedElapsedTime = format(timeInterval: elapsedTime)
        let currentBestTime = UserDefaults.standard.string(forKey: "bestTime") ?? "99:99.999"

        if formattedElapsedTime > currentBestTime {
            UserDefaults.standard.set(formattedElapsedTime, forKey: "bestTime")
            bestTimeLabel?.text = "Best Time: \(formattedElapsedTime)"
        }

        let currentBestScore = UserDefaults.standard.integer(forKey: "bestScore")
        if score > currentBestScore {
            UserDefaults.standard.set(score, forKey: "bestScore")
            bestScoreLabel?.text = "Best Score: \(score)"

            // Report score to Game Center
            if gameCenterManager?.isAuthenticated == true {
                reportScoreToGameCenter(score)
            }
        }

        showAlert()
        showShareSheet(with: score) // Show the share sheet after the game over alert

        prepareGame()
    }

    private func reportScoreToGameCenter(_ score: Int) {
        guard let gameCenterManager = gameCenterManager, gameCenterManager.isAuthenticated else { return }

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: ["002"]) { error in
            if let error = error {
                print("Error submitting score to Game Center: \(error.localizedDescription)")
            } else {
                print("Score submitted successfully to Game Center!")
            }
        }
    }

    private func showAlert() {
        if let viewController = self.view?.window?.rootViewController {
            let alert = UIAlertController(
                title: "Crashed Out",
                message: "Your score: \(score)\nBest score: \(UserDefaults.standard.integer(forKey: "bestScore"))\nTime: \(format(timeInterval: elapsedTime))",
                preferredStyle: .alert
            )

            let restartAction = UIAlertAction(title: "Try Again Lil Twin", style: .default) { _ in
                self.startGame()
            }

            let shareScore = score  // Capture the score value at this point
            let shareAction = UIAlertAction(title: "Share Score", style: .default) { _ in
                let gameLink = "https://apps.apple.com/us/app/your-game-id"  // Replace with your game's App Store link
                let textToShare = "I just scored \(shareScore) points in the game! Can you beat that? Check out the game here: \(gameLink)"
                let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                viewController.present(activityViewController, animated: true, completion: nil)
            }

            alert.addAction(restartAction)
            alert.addAction(shareAction)
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    private func showShareSheet(with score: Int) {
        let textToShare = "I just scored \(score) points in the game! Can you beat that?"
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)

        // Ensure that the share sheet is presented on the main thread
        DispatchQueue.main.async {
            if let viewController = self.view?.window?.rootViewController {
                viewController.present(activityViewController, animated: true, completion: nil)
            }
        }
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

        let isDollarBill = arc4random_uniform(6) == 0 // Approx. 1 in 6 chance for dollar bill emoji
        let emojiNode: SKLabelNode

        if isDollarBill {
            emojiNode = SKLabelNode(text: "💵") // Dollar bill emoji
            emojiNode.fontSize = 18
        } else {
            // Randomly select an enemy emoji
            let enemyEmojis = ["🍟", "🍸", "📱", "🥡", "🚔"]
            let randomIndex = Int(arc4random_uniform(UInt32(enemyEmojis.count)))
            emojiNode = SKLabelNode(text: enemyEmojis[randomIndex])
        }

        emojiNode.fontSize = 20
        emojiNode.position = position
        addChild(emojiNode)

        let duration = getEnemyDuration(enemy: emojiNode)
        let moveAction = SKAction.move(to: player.position, duration: duration)
        emojiNode.run(moveAction)

        enemies.append(emojiNode)
    }

    private func getEnemyDuration(enemy: SKNode) -> TimeInterval {
        let dx = player.position.x - enemy.position.x
        let dy = player.position.y - enemy.position.y
        return TimeInterval(sqrt(dx * dx + dy * dy) / enemySpeed)
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


    private func checkCollisions() {
        var indicesToRemove: [Int] = []

        for i in (0..<enemies.count).reversed() {
            let enemy = enemies[i]

            // Check collision with player
            if player.frame.intersects(enemy.frame) {
                if enemy.text == "💵" { // Dollar bill emoji
                    updateScoreForDollarBill()
                    showCash(at: enemy.position)
                    triggerWinningHaptic()
                    playMoneySound()
                    enemy.removeFromParent()
                    enemies.remove(at: i)
                    continue
                } else {
                    showCrash(at: player.position)
                    triggerHaptic()
                    //gameOver()
                    playCollisionSound()
                    enemy.removeFromParent()
                    enemies.remove(at: i)
                    if !isInvincible {
                        loseLife()
                    }
                    return
                }
            }

            // Check collision between enemies
            for j in (0..<i).reversed() where enemies[i].frame.intersects(enemies[j].frame) {
                if enemies[i].text == enemies[j].text {
                    updateScore()
                    showCash(at: enemies[i].position)
                    triggerWinningHaptic()
                    indicesToRemove.append(i)
                    indicesToRemove.append(j)
                    break
                }
            }
        }

        // Remove collided enemies
        for index in indicesToRemove.sorted().reversed() {
            enemies[index].removeFromParent()
            enemies.remove(at: index)
        }

        //        func loseLife() {
        //             if lives > 0 {
        //                 lives -= 1
        //                 let heartToRemove = heartNodes[lives]
        //                 heartToRemove.removeFromParent()
        //                 heartNodes.remove(at: lives)
        //
        //                 if lives == 0 {
        //                     gameOver()
        //                 }
        //             }
        //        }

        func loseLife() {
            if lives > 0 {
                lives -= 1
                let heartToRemove = heartNodes[lives]
                heartToRemove.removeFromParent()
                heartNodes.remove(at: lives)

                if lives > 0 {
                    triggerInvincibility()
                } else {
                    gameOver()
                    lives = 3
                }
            }
        }

        func triggerInvincibility() {
            isInvincible = true
            let waitAction = SKAction.wait(forDuration: 1.0) // 1 second invincibility
            let resetInvincibilityAction = SKAction.run { [weak self] in
                self?.isInvincible = false
            }
            let sequence = SKAction.sequence([waitAction, resetInvincibilityAction])
            run(sequence)
        }
    }

    private func playCollisionSound() {
        let soundAction = SKAction.playSoundFileNamed("opp.mp3", waitForCompletion: false)
        self.run(soundAction)
    }

    private func playMoneySound() {
        let soundAction = SKAction.playSoundFileNamed("money.mp3", waitForCompletion: false)
        self.run(soundAction)
    }

    private func updateScoreForDollarBill() {
        score += 1
        scoreLabel.text = "Score: \(score)"
    }

    private func updateScore() {
        score += 2
        scoreLabel.text = "Score: \(score)"
    }

    private func triggerWinningHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func showCash(at position: CGPoint) {
        let cashLabel = SKLabelNode(text: "💰")
        cashLabel.position = position
        cashLabel.fontSize = 35
        cashLabel.zPosition = 1
        addChild(cashLabel)

        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        cashLabel.run(sequence)
    }

    private func showCrash(at position: CGPoint) {
        let crashLabel = SKLabelNode(text: "💥")
        crashLabel.position = position
        crashLabel.fontSize = 35
        crashLabel.zPosition = 1
        addChild(crashLabel)

        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        crashLabel.run(sequence)
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    private func playBackgroundMusic() {
        if let musicURL = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
                backgroundMusicPlayer?.play()
            } catch {
                print("Could not load background music: \(error)")
            }
        }
    }
}
