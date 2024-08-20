//
//  MainMenu.swift
//  kickit
//
//  Created by myle$ on 8/12/24.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("My Awesome Game")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Menu Buttons
//            NavigationLink(destination: GameScene()) {
//                Text("Start Game")
//                    .font(.title)
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }

            //            NavigationLink(destination: HighScoresView()) {
            //                Text("High Scores")
            //                    .font(.title)
            //                    .padding()
            //                    .background(Color.green)
            //                    .foregroundColor(.white)
            //                    .cornerRadius(10)
            //            }

            //            NavigationLink(destination: SettingsView()) {
            //                Text("Settings")
            //                    .font(.title)
            //                    .padding()
            //                    .background(Color.orange)
            //                    .foregroundColor(.white)
            //                    .cornerRadius(10)
            //            }

            //            NavigationLink(destination: GameCenterView()) {
            //                Text("Game Center")
            //                    .font(.title)
            //                    .padding()
            //                    .background(Color.purple)
            //                    .foregroundColor(.white)
            //                    .cornerRadius(10)
            //            }
            //        }
            //        .padding()
            //    }
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}

