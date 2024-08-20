//
//  About.swift
//  kickit
//
//  Created by myle$ on 8/7/24.
//

import Foundation
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {

            Text("This game is developed using SwiftUI and SpriteKit.")
                .padding()


            Button(action: {
                NotificationCenter.default.post(name: .showMenu, object: nil)
            }) {
                Text("Bet")
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .cornerRadius(100)
            }
        }
    }
}
