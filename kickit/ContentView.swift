import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameCenterManager = GameCenterManager()

    var scene: SKScene {
        let scene = GameScene(gameCenterManager: gameCenterManager)
        scene.size = CGSize(width: 300, height: 600)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        VStack {
            SpriteView(scene: scene)
                .frame(width: 300, height: 600)
                .ignoresSafeArea()

            if !gameCenterManager.isAuthenticated {
                Text("Authenticating...")
                    .font(.headline)
                    .monospaced()
                    .padding()
            } else {
                Text("how to play: tap & chase the money 😤💸")
                    .font(.caption2)
                    .monospaced()
                    .padding()

            }
        }
        .onAppear {
            // Ensure GameCenterManager is authenticated
            gameCenterManager.authenticatePlayer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
