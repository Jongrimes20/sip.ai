//
//  HomeView.swift
//  sip.ai
//
//  Created by Jon Grimes on 6/13/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    var body: some View {
        NavigationSplitView {
            ZStack {
                // Background Color
                Color(red: 0.96, green: 0.96, blue: 0.94)
                    .ignoresSafeArea()
                
                List(dataManager.drinks) { drink in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(drink.name).font(.system(size: 20, weight: .bold, design: .serif))
                            Text(drink.type.rawValue.capitalized).font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .foregroundStyle(.white.opacity(0.5))
                                .blur(radius: 5)
                                .frame(width: 50)
                                .glassEffect()
                            Text(String(format: "%.1f", drink.rating))
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(
                                    drink.rating >= 4.0 ? .green :
                                    drink.rating >= 2.5 ? .yellow :
                                    .red
                                )
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        NavigationLink(destination: {NewDrinkView().environmentObject(dataManager)},
                                       label: {Label("Add Item", systemImage: "plus")}
                        )
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager.preview)
}
