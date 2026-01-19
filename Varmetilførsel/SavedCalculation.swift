//
//  SavedCalculation.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import Foundation
import SwiftData

@Model
class WeldGroup {
    var id: UUID
    var name: String
    var date: Date
    var notes: String = ""
    
    // Ekstra info du kanskje vil manipulere senere
    var wpqrNumber: String = ""
    var baseMaterial: String = ""
    var preheatTemp: String = ""
    var interpassTemp: String = ""
    
    // Relasjon: En jobb har mange sveiser (passes)
    // .cascade betyr: Sletter du jobben, slettes også sveisene i den.
    @Relationship(deleteRule: .cascade, inverse: \SavedCalculation.group)
    var passes: [SavedCalculation] = []
    
    init(name: String, date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.date = date
    }
}

import SwiftData
import Foundation

@Model
final class SavedCalculation {
    var id: UUID
    var name: String
    var resultValue: String
    var category: String
    var date: Date
    
    // Core data
    var voltage: Double
    var amperage: Double
    var travelTime: Double
    var weldLength: Double
    var calculatedHeat: Double
    
    // NYE FELTER (ISO 15609-1 DATA)
    var wireFeedSpeed: String?
    var gasFlow: String?
    var stickOut: String?
    var interpassTemp: String?
    var polarity: String?
    var note: String?
    
    var group: WeldGroup?
    
    init(name: String, resultValue: String, category: String, voltage: Double, amperage: Double, travelTime: Double, weldLength: Double, calculatedHeat: Double) {
        self.id = UUID()
        self.name = name
        self.resultValue = resultValue
        self.category = category
        self.date = Date()
        self.voltage = voltage
        self.amperage = amperage
        self.travelTime = travelTime
        self.weldLength = weldLength
        self.calculatedHeat = calculatedHeat
    }
}
