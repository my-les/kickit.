import SwiftUI
import SpriteKit

struct ContentView: View {
    var scene: SKScene {
        let scene = MainMenuScene()
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}
