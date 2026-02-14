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
    var name: String
    var timestamp: Date
    
    // --- Kjerne Data ---
    var voltage: Double?
    var amperage: Double?
    var travelTime: Double?
    var weldLength: Double?
    var heatInput: Double
    
    // --- Prosess Data ---
    var processName: String
    var kFactorUsed: Double
    
    // --- Utvidet Data (Eksisterende) ---
    var fillerDiameter: Double?
    var polarity: String?
    var wireFeedSpeed: Double?
    var isArcEnergy: Bool = false
    
    // --- Utvidet Data (Lagt til 25.01) ---
    var actualInterpass: Double?
    var gasType: String?
    var passType: String?
    
    // --- NYE FELTER (Lagt til NÅ) ---
    var gasFlow: Double?        // l/min
    var transferMode: String?   // Spray, Short, Pulse, etc.
    var fillerMaterial: String? // Type tråd (f.eks "316L")
    var savedTravelSpeed: Double? // Lagret utregnet hastighet (mm/min)
    
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
         passType: String? = nil,
         // Nye parametre:
         gasFlow: Double? = nil,
         transferMode: String? = nil,
         fillerMaterial: String? = nil,
         savedTravelSpeed: Double? = nil
    ) {
        
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
        
        // Nye
        self.gasFlow = gasFlow
        self.transferMode = transferMode
        self.fillerMaterial = fillerMaterial
        self.savedTravelSpeed = savedTravelSpeed
    }
    
    var resultValue: String {
        let value = String(format: "%.2f kJ/mm", heatInput)
        return isArcEnergy ? "\(value) (AE)" : value
    }
}
