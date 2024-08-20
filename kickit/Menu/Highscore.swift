//
//  Highscore.swift
//  kickit
//
//  Created by myle$ on 8/7/24.
//

import Foundation
import SwiftUI

struct HighScoresView: View {
    var body: some View {
        VStack {
            Text("Hold on")
                .font(.largeTitle)
                .padding()
        }
        Button(action: {
            NotificationCenter.default.post(name: .showMenu, object: nil)
        }) {
            Text("Back to Menu")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}
