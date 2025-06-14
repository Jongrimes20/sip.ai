//
//  DataManager.swift
//  sip.ai
//
//  Created by Jon Grimes on 6/14/25.
//


import Foundation
import SwiftUI
import Combine

class DataManager: ObservableObject {
    @Published var drinks: [Drink] = []
    
    private let beersKey = "savedDrinks"
    
    /**
     - loadBeers: Loads locally saved beers from UserDefaults
     - loadBreweries: Fetches ALL approved Breweries from supabase
     */
    init() {
        loadDrinks()
    }
    
    // MARK: - Beer Operations
    
    func loadDrinks() {
        if let data = UserDefaults.standard.data(forKey: beersKey),
           let decodedDrinks = try? JSONDecoder().decode([Drink].self, from: data) {
            self.drinks = decodedDrinks
        }
    }
    
    func saveDrink(_ drink: Drink) {
        drinks.append(drink)
        saveDrinks()
    }

    func updateDrink(_ drink: Drink) {
        if let index = drinks.firstIndex(where: { $0.id == drink.id }) {
            drinks[index] = drink
            saveDrinks()
        }
    }

    func deleteDrink(_ drink: Drink) {
        drinks.removeAll { $0.id == drink.id }
        saveDrinks()
    }

    private func saveDrinks() {
        if let encoded = try? JSONEncoder().encode(drinks) {
            UserDefaults.standard.set(encoded, forKey: beersKey)
        }
    }
} 

extension DataManager {
    static let preview: DataManager = {
        let manager = DataManager()
        manager.drinks = Drink.samples
        return manager
    }()
}
