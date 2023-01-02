//
//  SpeakaboloApp.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 12/23/22.
//

import SwiftUI

@main
struct SpeakaboloApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView().frame(width: 1200, height: 800)
        }.commands {
            SidebarCommands()
            TextEditingCommands()
        }
    }
}
