//
//  GameViewModel.swift
//  kickit
//
//  Created by myle$ on 7/14/24.
//

import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    // MARK: - Enum
    fileprivate enum ScreenEdge: Int {
        case top = 0
        case right = 1
        case bottom = 2
        case left = 3
    }

    public enum GameState {
        case ready
        case playing
        case gameOver
    }

    // MARK: - Constants
    let radius: CGFloat = 10
    fileprivate let playerAnimationDuration = 5.0
    fileprivate let enemySpeed: CGFloat = 60 // points per second
    fileprivate let colors: [Color] = [.green, .blue, .yellow, .orange, .purple, .red, .cyan, .gray, .black, .white]

    // MARK: - State Variables
    @Published var playerPosition: CGPoint = CGPoint(x: 200, y: 400)
    @Published var enemyPositions: [CGPoint] = []
    @Published var enemyColors: [Color] = []
    @Published var gameState = GameState.ready
    @Published var elapsedTime: TimeInterval = 0
    @Published var bestTime: String = "00:00.000"
    @Published var startLabelVisible: Bool = true

    // MARK: - Timer
    private var enemyTimer: Timer?
    private var displayLink: CADisplayLink?
    private var beginTimestamp: TimeInterval = 0

    func setupGame() {
        centerPlayerView()
        getBestTime()
    }

    func startGame() {
        startEnemyTimer()
        startDisplayLink()
        startLabelVisible = false
        beginTimestamp = 0
        gameState = .playing
    }

    func stopGame() {
        enemyTimer?.invalidate()
        enemyTimer = nil
        displayLink?.invalidate()
        displayLink = nil
        gameState = .gameOver
    }

    func movePlayer(to position: CGPoint) {
        withAnimation(.easeInOut(duration: playerAnimationDuration)) {
            playerPosition = position
        }
    }

    func moveEnemies(to position: CGPoint) {
        // Move enemies towards the player position
        withAnimation(.linear(duration: playerAnimationDuration)) {
            for i in 0..<enemyPositions.count {
                enemyPositions[i] = position
            }
        }
    }

    private func startEnemyTimer() {
        enemyTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.generateEnemy()
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .default)
    }

    private func getRandomColor() -> Color {
        let index = Int(arc4random_uniform(UInt32(colors.count)))
        return colors[index]
    }

    private func getEnemyDuration(from position: CGPoint) -> TimeInterval {
        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        return TimeInterval(sqrt(dx * dx + dy * dy) / enemySpeed)
    }

    @objc private func tick() {
        if beginTimestamp == 0 {
            beginTimestamp = displayLink?.timestamp ?? 0
        }
        elapsedTime = (displayLink?.timestamp ?? 0) - beginTimestamp
        checkCollision()
    }

    private func checkCollision() {
        for position in enemyPositions {
            let playerFrame = CGRect(x: playerPosition.x - radius, y: playerPosition.y - radius, width: radius * 2, height: radius * 2)
            let enemyFrame = CGRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2)

            if playerFrame.intersects(enemyFrame) {
                gameOver()
                break
            }
        }
    }

    private func gameOver() {
        stopGame()
        displayGameOverAlert()
    }

    private func displayGameOverAlert() {
        let (title, message) = getGameOverTitleAndMessage()
        let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: title, style: .default) { _ in
            self.setupGame()
        }
        alert.addAction(action)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }

    private func getGameOverTitleAndMessage() -> (String, String) {
        let elapsedSeconds = Int(elapsedTime) % 60
        setBestTime(with: elapsedTimeFormatted)

        switch elapsedSeconds {
        case 0..<10: return ("Try again 😂", "Seriously, you need more practice 😒")
        case 10..<30: return ("Another go 😉", "Not bad, you are getting there 😁")
        case 30..<60: return ("Play again 😉", "Very good 👍")
        default: return ("Of course 😚", "Legend, olympic player, go 🇧🇷")
        }
    }

    private func centerPlayerView() {
        playerPosition = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    }

    private func setBestTime(with time: String) {
        UserDefaults.standard.set(time, forKey: "bestTime")
    }

    private func getBestTime() {
        if let time = UserDefaults.standard.string(forKey: "bestTime") {
            bestTime = "Best Time: \(time)"
        }
    }

    var elapsedTimeFormatted: String {
        let interval = Int(elapsedTime)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let milliseconds = Int(elapsedTime * 1000) % 1000
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    private func generateEnemy() {
        let screenEdge = ScreenEdge(rawValue: Int(arc4random_uniform(4)))!
        let screenBounds = UIScreen.main.bounds
        var position: CGPoint = .zero

        switch screenEdge {
        case .left:
            position = CGPoint(x: 0, y: CGFloat(arc4random_uniform(UInt32(screenBounds.height))))
        case .right:
            position = CGPoint(x: screenBounds.width, y: CGFloat(arc4random_uniform(UInt32(screenBounds.height))))
        case .top:
            position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(screenBounds.width))), y: 0)
        case .bottom:
            position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(screenBounds.width))), y: screenBounds.height)
        }

        enemyPositions.append(position)
        enemyColors.append(getRandomColor())
    }
}

