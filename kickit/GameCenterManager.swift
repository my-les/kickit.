import GameKit
import SwiftUI

class GameCenterManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {

    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var leaderboards: [GKLeaderboard] = []
    @Published var leaderboardEntries: [GKLeaderboard.Entry] = []

    let bestTimeLeaderboardID = "002"
    let bestScoreLeaderboardID = "004"

    override init() {
        super.init()
        authenticatePlayer()
    }

    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                // Present the view controller to the player to complete the authentication
                self.present(viewController: viewController)
                return
            }
            if error != nil {
                // Handle the error
                self.isAuthenticated = false
                return
            }

            // Player was successfully authenticated
            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated

            // Load leaderboards after authentication
            if self.isAuthenticated {
                self.loadLeaderboards()
            }
        }
    }

    func reportScore(_ score: Int, toLeaderboards leaderboardIDs: [String]) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: leaderboardIDs) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            } else {
                print("Score submitted successfully!")
            }
        }
    }

    func reportBestTime(_ time: TimeInterval) {
        // Convert time to milliseconds (Game Center expects integers)
        let timeInMilliseconds = Int(time * 1000)
        reportScore(timeInMilliseconds, toLeaderboard: bestTimeLeaderboardID)
    }

    func reportBestScore(_ score: Int) {
        reportScore(score, toLeaderboard: bestScoreLeaderboardID)
    }

    private func reportScore(_ score: Int, toLeaderboard leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score to leaderboard \(leaderboardID): \(error.localizedDescription)")
            } else {
                print("Score submitted successfully to leaderboard \(leaderboardID)!")
            }
        }
    }

    func loadLeaderboards() {
        GKLeaderboard.loadLeaderboards(IDs: nil) { leaderboards, error in
            if let error = error {
                print("Error loading leaderboards: \(error.localizedDescription)")
            } else if let leaderboards = leaderboards {
                self.leaderboards = leaderboards
                print("Leaderboards loaded successfully!")
            }
        }
    }

    func loadLeaderboardEntries(for leaderboardID: String) {
        guard let leaderboard = leaderboards.first(where: { $0.baseLeaderboardID == leaderboardID }) else { return }

        leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 10)) { localPlayerEntry, entries, totalPlayerCount, error in
            if let error = error {
                print("Error loading leaderboard entries: \(error.localizedDescription)")
            } else if let entries = entries {
                self.leaderboardEntries = entries
                print("Leaderboard entries loaded successfully!")
            }
        }
    }

    func showLeaderboard(for leaderboardID: String) {
        let viewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        viewController.gameCenterDelegate = self
        present(viewController: viewController)
    }

    private func present(viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        rootViewController.present(viewController, animated: true, completion: nil)
    }

    // GKGameCenterControllerDelegate method
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
