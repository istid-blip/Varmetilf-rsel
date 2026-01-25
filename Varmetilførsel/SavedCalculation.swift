//
//  SavedCalculation.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import Foundation
import SwiftData

// --- 1. SVEISEJOBB (GRUPPE) ---
@Model
final class WeldGroup {
    var id: UUID
    var name: String
    var date: Date
    var notes: String = ""
    
    // Metadata
    var wpqrNumber: String = ""
    var baseMaterial: String = ""
    var preheatTemp: String = ""
    var interpassTemp: String = ""
    
    // Relasjon: En jobb har mange sveiser
    @Relationship(deleteRule: .cascade, inverse: \SavedCalculation.group)
    var passes: [SavedCalculation] = []
    
    init(name: String, date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.date = date
    }
}

// --- 2. ENKELT SVEISESTRENG (BEREGNING) ---
@Model
final class SavedCalculation {
    var id: UUID
    var name: String        // F.eks "Pass #1"
    var timestamp: Date
    
    // --- Kjerne Data ---
    var voltage: Double?
    var amperage: Double?
    var travelTime: Double?
    var weldLength: Double?
    var heatInput: Double   // Resultatet (kJ/mm)
    
    // --- Prosess Data ---
    var processName: String
    var kFactorUsed: Double
    
    // --- Utvidet Data ---
    var fillerDiameter: Double? // mm
    var polarity: String?       // DC+, DC-, AC
    var wireFeedSpeed: Double?  // m/min
    var isArcEnergy: Bool = false  // false = Heat Input, true = Arc Energy
    
    // --- NYE FELTER (25.01.2026) ---
    var actualInterpass: Double? // Faktisk målt temperatur
    var gasType: String?         // Navn på gass
    var passType: String?        // "Root", "Fill", "Cap", "-"
    
    // Relasjon til jobben
    var group: WeldGroup?
    
    init(name: String,
         voltage: Double? = nil,
         amperage: Double? = nil,
         travelTime: Double? = nil,
         weldLength: Double? = nil,
         heatInput: Double,
         processName: String,
         kFactorUsed: Double,
         fillerDiameter: Double? = nil,
         polarity: String? = nil,
         wireFeedSpeed: Double? = nil,
         isArcEnergy: Bool = false,
         actualInterpass: Double? = nil,
         gasType: String? = nil,
         passType: String? = nil) {
        
        self.id = UUID()
        self.name = name
        self.timestamp = Date()
        
        self.voltage = voltage
        self.amperage = amperage
        self.travelTime = travelTime
        self.weldLength = weldLength
        self.heatInput = heatInput
        
        self.processName = processName
        self.kFactorUsed = kFactorUsed
        
        self.fillerDiameter = fillerDiameter
        self.polarity = polarity
        self.wireFeedSpeed = wireFeedSpeed
        self.isArcEnergy = isArcEnergy
        
        self.actualInterpass = actualInterpass
        self.gasType = gasType
        self.passType = passType
    }
    
    // Hjelpe-variabel for visning i lister
    var resultValue: String {
        let value = String(format: "%.2f kJ/mm", heatInput)
        return isArcEnergy ? "\(value) (AE)" : value
    }
}
