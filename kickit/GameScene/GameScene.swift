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
    private let enemySpeed: CGFloat = 5 // points per second

    private var level: Int = 1
    private var enemiesPerLevel: Int = 1
    private let levelThreshold: Int = 10

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

    private weak var gameCenterManager: GameCenterManager?

    private var levelLabel: SKLabelNode!
    private var pauseButton: SKSpriteNode!
    private var isGamePaused: Bool = false

    private let baseEnemySpeed: CGFloat = 5
    private let maxEnemySpeed: CGFloat = 8
    private let baseSpawnInterval: TimeInterval = 3.0
    private let minSpawnInterval: TimeInterval = 1.0

    private var saladPowerUp: SKLabelNode?
    private let saladSpawnChance: Double = 0.50 // 5% chance per level

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
        updateLevel()
        prepareGame()
        playBackgroundMusic()
        setupPauseButton()

        bestScore = UserDefaults.standard.integer(forKey: "bestScore")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if pauseButton.contains(location) {
            togglePauseGame()
        } else {
            switch gameState {
            case .ready:
                startGame()
            case .playing:
                if !isGamePaused {
                    movePlayer(to: location)
                    moveEnemies(to: location)
                }
            case .gameOver:
                break
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if gameState == .playing && !isGamePaused {
            if startTime == 0 {
                startTime = currentTime
            }
            elapsedTime = currentTime - startTime
            clockLabel.text = format(timeInterval: elapsedTime)
            checkCollisions()
            if score >= level * levelThreshold {
                increaseLevel()
            }
        }
    }

    private func setupPlayer() {
        player = SKLabelNode(text: "🥷🏾") // Ninja emoji
        player.fontSize = 18
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    private func increaseLevel() {
        level += 1
        enemiesPerLevel += 1
        updateLevel()
        print("Level \(level) started. More enemies incoming lil bitch!")
    }

    private func updateLevel() {
        // Update enemy generation rate or speed based on level
        removeAction(forKey: "enemyGenerator")

        let generateEnemyAction = SKAction.run { [weak self] in
            self?.generateEnemies(for: self?.level ?? 1)
        }
        let waitAction = SKAction.wait(forDuration: max(0.8 - 0.1 * Double(level), minSpawnInterval)) // Cap minimum spawn interval
        let sequenceAction = SKAction.sequence([generateEnemyAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        run(repeatAction, withKey: "enemyGenerator")

        updateGameSpeedAndSpawnRate(for: level)

        // Update the level label
        levelLabel.text = "Level: \(level)"

        // Try to spawn a salad power-up
        if Double.random(in: 0...1) < saladSpawnChance {
            spawnSaladPowerUp()
        }
    }

    private func spawnSaladPowerUp() {
        // Remove existing salad power-up if any
        saladPowerUp?.removeFromParent()
        
        let salad = SKLabelNode(text: "🥗")
        salad.fontSize = 16
        salad.position = randomPositionOutsideScreen()
        addChild(salad)
        saladPowerUp = salad

        let moveAction = SKAction.move(to: randomPositionInsideScreen(), duration: 10)
        let fadeOutAction = SKAction.fadeOut(withDuration: 2)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, fadeOutAction, removeAction])
        
        salad.run(sequence) {
            self.saladPowerUp = nil
        }
    }

    private func randomPositionOutsideScreen() -> CGPoint {
        let side = Int.random(in: 0...3)
        switch side {
        case 0: return CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 50)
        case 1: return CGPoint(x: CGFloat.random(in: 0...size.width), y: -50)
        case 2: return CGPoint(x: -50, y: CGFloat.random(in: 0...size.height))
        default: return CGPoint(x: size.width + 50, y: CGFloat.random(in: 0...size.height))
        }
    }

    private func randomPositionInsideScreen() -> CGPoint {
        return CGPoint(x: CGFloat.random(in: 50...(size.width - 50)),
                       y: CGFloat.random(in: 50...(size.height - 50)))
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

        levelLabel = SKLabelNode(text: "Level: 1")
        levelLabel.position = CGPoint(x: size.width - 20, y: size.height - 75)
        levelLabel.fontName = "CourierNewPS-BoldMT"
        levelLabel.fontSize = 14  // Smaller than the score label
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .right
        addChild(levelLabel)
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

        level = 1
        levelLabel.text = "Level: 1"
        enemiesPerLevel = 1  // Reset enemiesPerLevel

        // Remove all existing enemies
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()

        // Remove any existing enemy generator action
        removeAction(forKey: "enemyGenerator")

        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func startGame() {
        gameState = .playing
        startTime = 0
        elapsedTime = 0
        tapToStartLabel.isHidden = true

        // Remove any existing enemy generator action
        removeAction(forKey: "enemyGenerator")

        // Set up the initial enemy generator with appropriate timing
        let generateEnemyAction = SKAction.run { [weak self] in
            self?.generateEnemies(for: self?.level ?? 1)
        }
        let waitAction = SKAction.wait(forDuration: 3.0)
        let sequenceAction = SKAction.sequence([generateEnemyAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        run(repeatAction, withKey: "enemyGenerator")

        // Update game speed and spawn rate for the initial level
        updateGameSpeedAndSpawnRate(for: level)
    }

        // Implement Pause Button
    private func setupPauseButton() {
        pauseButton = SKSpriteNode(imageNamed: "nodiddy")
        pauseButton.size = CGSize(width: 30, height: 30)
        pauseButton.position = CGPoint(x: size.width / 8, y: size.height / 8.5)
        pauseButton.zPosition = 100
        addChild(pauseButton)
    }

    private func togglePauseGame() {
        isGamePaused = !isGamePaused

        if isGamePaused {
            pauseGame()
        } else {
            resumeGame()
        }
    }

    private func pauseGame() {
        pauseButton.texture = SKTexture(imageNamed: "diddy")
        self.isPaused = true

        let pausedLabel = SKLabelNode(text: "NO DIDDY")
        pausedLabel.fontName = "CourierNewPS-BoldMT"
        pausedLabel.fontSize = 40
        pausedLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pausedLabel.zPosition = 100
        pausedLabel.name = "pausedLabel"
        addChild(pausedLabel)
    }

    private func resumeGame() {
        pauseButton.texture = SKTexture(imageNamed: "nodiddy")
        self.isPaused = false

        if let pausedLabel = childNode(withName: "pausedLabel") {
            pausedLabel.removeFromParent()
        }
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
                title: "Crashed Out 😪",
                message: "Your score: \(score)\nBest score: \(UserDefaults.standard.integer(forKey: "bestScore"))\nTime: \(format(timeInterval: elapsedTime))",
                preferredStyle: .alert
            )

            let restartAction = UIAlertAction(title: "Try Again Lil Twin", style: .default) { _ in
                self.startGame()
            }

            let shareScore = score  // Capture the score value at this point
            let shareAction = UIAlertAction(title: "Share Score", style: .default) { _ in
                let gameLink = "https://apps.apple.com/app/kickit/id1254777556"  // Replace with your game's App Store link
                let textToShare = "I just scored \(shareScore) points in the game slim! Can you beat that? Check out the game here: \(gameLink)"
                let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                viewController.present(activityViewController, animated: true, completion: nil)
            }
            let mainMenuAction = UIAlertAction(title: "Main Menu", style: .default) { _ in
                self.returnToMainMenu()
            }


            alert.addAction(restartAction)
            alert.addAction(shareAction)
            alert.addAction(mainMenuAction)
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

    private func returnToMainMenu() {
        let mainMenuScene = MainMenuScene(size: view!.bounds.size)
        view?.presentScene(mainMenuScene, transition: .flipHorizontal(withDuration: 0.5))
    }

    private func generateEnemies(for level: Int) {
        let enemyTypes = getEnemyEmojis(for: level)
        // add cash aspect

        for _ in 0..<enemiesPerLevel {
            let screenEdge = ScreenEdge(rawValue: Int.random(in: 0...3))!
            var position: CGPoint = .zero

            switch screenEdge {
            case .left:
                position = CGPoint(x: 0, y: CGFloat.random(in: 0...size.height))
            case .right:
                position = CGPoint(x: size.width, y: CGFloat.random(in: 0...size.height))
            case .top:
                position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
            case .bottom:
                position = CGPoint(x: CGFloat.random(in: 0...size.width), y: 0)
            }

            let randomIndex = Int.random(in: 0..<enemyTypes.count)
            let emojiNode = SKLabelNode(text: enemyTypes[randomIndex])
            emojiNode.fontSize = 14
            emojiNode.position = position
            addChild(emojiNode)

            let duration = getEnemyDuration(enemy: emojiNode)
            let moveAction = SKAction.move(to: player.position, duration: duration)
            emojiNode.run(moveAction)

            enemies.append(emojiNode)
        }
    }

    private func getEnemyEmojis(for level: Int) -> [String] {
        switch level {
        case 1...2:
            return ["🚔", "💵"] // Basic enemies
        case 3...5:
            return ["🍟", "💵", "🍔"] // Introduce more difficult enemies gradually
        case 6...8:
            return ["📱", "💵", "💔", "🍸"] // Add another enemy type
        case 9...:
            return ["💔", "💵", "🥡", "🍸", "📱"] // Full set of enemies
        default:
            return ["🍟", "💵"] // Fallback to basic enemies
        }
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

    private func format(timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let milliseconds = Int(timeInterval * 1000) % 1000
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    private func checkCollisions() {
        var enemiesToRemove: [SKLabelNode] = []

        for enemy in enemies {
            // Check collision with player
            if player.frame.intersects(enemy.frame) {
                if enemy.text == "💵" { // Dollar bill emoji
                    updateScoreForDollarBill()
                    showCash(at: enemy.position)
                    triggerWinningHaptic()
                    playMoneySound()
                    enemiesToRemove.append(enemy)
                } else {
                    showCrash(at: player.position)
                    triggerHaptic()
                    playCollisionSound()
                    enemiesToRemove.append(enemy)
                    if !isInvincible {
                        loseLife()
                    }
                    break
                }
            }

            // Check collision between enemies
            for otherEnemy in enemies where enemy != otherEnemy && enemy.frame.intersects(otherEnemy.frame) {
                if enemy.text == otherEnemy.text {
                    updateScore()
                    showCash(at: enemy.position)
                    triggerWinningHaptic()
                    enemiesToRemove.append(enemy)
                    enemiesToRemove.append(otherEnemy)
                    break
                }
            }
        }

        // Check collision with salad power-up
        if let salad = saladPowerUp, player.frame.intersects(salad.frame) {
            collectSaladPowerUp()
        }

        // Remove collided enemies
        for enemy in enemiesToRemove {
            enemy.removeFromParent()
            if let index = enemies.firstIndex(of: enemy) {
                enemies.remove(at: index)
            }
        }
    }

    private func loseLife() {
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

    private func triggerInvincibility() {
        isInvincible = true
        let waitAction = SKAction.wait(forDuration: 1.0) // 1 second invincibility
        let resetInvincibilityAction = SKAction.run { [weak self] in
            self?.isInvincible = false
        }
        let sequence = SKAction.sequence([waitAction, resetInvincibilityAction])
        run(sequence)
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

    private func updateGameSpeedAndSpawnRate(for level: Int) {
        // Calculate speed multiplier with a more gradual increase
        let speedMultiplier = min(1 + (CGFloat(level) * 0.05), maxEnemySpeed / baseEnemySpeed)

        // Calculate spawn interval with a more gradual decrease
        let spawnInterval = max(baseSpawnInterval - (TimeInterval(level) * 0.05), minSpawnInterval)

        // Adjust enemy speed based on the calculated speed multiplier
        adjustEnemySpeed(to: baseEnemySpeed * speedMultiplier)

        // Adjust enemy spawn rate (frequency) based on the calculated spawn interval
        adjustEnemySpawnRate(to: spawnInterval)

        // Adjust enemies per level
        enemiesPerLevel = min(1 + (level / 5), 4) // Cap at 4 enemies per spawn, increase every 5 levels
    }

    // Function to adjust enemy speed
    private func adjustEnemySpeed(to speed: CGFloat) {
        for enemy in enemies {
            enemy.speed = speed
        }
    }

    // Function to adjust the enemy spawn rate
    private func adjustEnemySpawnRate(to interval: TimeInterval) {
        removeAction(forKey: "enemyGenerator")

        let generateEnemyAction = SKAction.run { [weak self] in
            self?.generateEnemies(for: self?.level ?? 1)
        }
        let waitAction = SKAction.wait(forDuration: interval)
        let sequenceAction = SKAction.sequence([generateEnemyAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        run(repeatAction, withKey: "enemyGenerator")
    }

    // Use a more efficient way to remove enemies
    private func removeEnemy(_ enemy: SKLabelNode) {
        enemy.removeFromParent()
        if let index = enemies.firstIndex(of: enemy) {
            enemies.remove(at: index)
        }
    }

    private func collectSaladPowerUp() {
        saladPowerUp?.removeFromParent()
        saladPowerUp = nil
        
        if lives < 3 {
            lives += 1
            updateHeartDisplay()
            playSaladCollectionSound()
            showSaladCollectionEffect()
        }
    }

    private func updateHeartDisplay() {
        // Remove all existing hearts
        for heart in heartNodes {
            heart.removeFromParent()
        }
        heartNodes.removeAll()

        // Add hearts based on current lives
        for i in 0..<lives {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.position = CGPoint(x: 20 + (i * 20), y: Int(self.size.height) - 75)
            heart.size = CGSize(width: 12, height: 12)
            heart.zPosition = 100
            addChild(heart)
            heartNodes.append(heart)
        }
    }

    private func playSaladCollectionSound() {
        let soundAction = SKAction.playSoundFileNamed("salad_collect.mp3", waitForCompletion: false)
        self.run(soundAction)
    }

    private func showSaladCollectionEffect() {
        let effectNode = SKLabelNode(text: "+1 Life!")
        effectNode.fontSize = 20
        effectNode.fontColor = .green
        effectNode.position = player.position.applying(CGAffineTransform(translationX: 0, y: 30))
        addChild(effectNode)

        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])
        
        effectNode.run(sequence)
    }

    // Properly clean up resources in deinit
    deinit {
        print("GameScene is being deinitialized")
        removeAllActions()
        removeAllChildren()
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
}
