//
//  VarmetilforselApp.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI
import SwiftData

@main
struct SveiseformlerApp: App {
    // 1. Hent valgt språk. Merk at vi endret default til "nb" tidligere.
    @AppStorage("app_language") private var languageCode: String = "nb"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedCalculation.self,
            WeldGroup.self
        ]) //Hvilke data som skal lagres
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false) //Lagres på disk og ikke bare i minnet

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HeatInputView()
                // 2. Setter språket i miljøet
                .environment(\.locale, Locale(identifier: languageCode))

        }
        .modelContainer(sharedModelContainer)
    }
}
