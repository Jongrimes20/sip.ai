//
//  ContentView.swift
//  sip.ai
//
//  Created by Jon Grimes on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill", content: {
                HomeView()
                    .environmentObject(dataManager)
            })
            Tab("Explore", systemImage: "map.fill", content: {
                ExploreView()
            })
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}
