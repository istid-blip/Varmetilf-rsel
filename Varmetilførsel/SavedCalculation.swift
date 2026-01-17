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

@Model
class SavedCalculation {
    var id: UUID
    var name: String // F.eks "Pass #1"
    var resultValue: String
    var timestamp: Date
    var category: String
    
    // Detaljer
    var voltage: Double?
    var amperage: Double?
    var travelTime: Double?
    var weldLength: Double?
    var calculatedHeat: Double?
    
    // Relasjon: Hver sveis tilhører en gruppe (valgfritt i starten for bakoverkompatibilitet)
    var group: WeldGroup?
    
    init(name: String, resultValue: String, category: String,
         voltage: Double? = nil, amperage: Double? = nil,
         travelTime: Double? = nil, weldLength: Double? = nil,
         calculatedHeat: Double? = nil) {
        
        self.id = UUID()
        self.name = name
        self.resultValue = resultValue
        self.timestamp = Date()
        self.category = category
        
        self.voltage = voltage
        self.amperage = amperage
        self.travelTime = travelTime
        self.weldLength = weldLength
        self.calculatedHeat = calculatedHeat
    }
}
