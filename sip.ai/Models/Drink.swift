//
//  Drink.swift
//  sip.ai
//
//  Created by Jon Grimes on 6/13/25.
//

import Foundation
import FoundationModels

struct Drink: Codable, Identifiable {
    let id: UUID
    var name: String
    var type: DrinkType
    var rating: Double
    var notes: String?
    var image: String?
}

enum DrinkType: String, Codable {
    case beer
    case wine
    case cocktail
}

extension Drink {
    static let samples: [Drink] = [
        Drink(id: UUID(), name: "Summer IPA", type: .beer, rating: 8.4, notes: "Crisp and hoppy!", image: nil),
        Drink(id: UUID(), name: "Chardonnay", type: .wine, rating: 7.1, notes: "Fruity with a hint of oak.", image: nil),
        Drink(id: UUID(), name: "Negroni", type: .cocktail, rating: 9.0, notes: "Classic and bitter-sweet.", image: nil)
    ]
}
