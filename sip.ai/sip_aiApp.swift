//
//  sip_aiApp.swift
//  sip.ai
//
//  Created by Jon Grimes on 6/13/25.
//

import SwiftUI

@main
struct sip_aiApp: App {
    @StateObject var dataManager = DataManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
