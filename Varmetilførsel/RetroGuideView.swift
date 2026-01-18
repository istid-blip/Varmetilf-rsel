//
//  RetroGuideView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI

struct RetroGuideView: View {
    let isDetailed: Bool // True = Settings (mer tekst), False = Empty State (kun punkter)

    var body: some View {
        VStack(alignment: .leading) {
            
            if isDetailed {
                Text("BRUKERMANUAL v1.0")
                    .font(RetroTheme.font(size: 20, weight: .heavy))
                    .foregroundColor(RetroTheme.primary)
                    .padding(.bottom, 10)
            }

            VStack(alignment: .leading, spacing: 15) {
                guideStep(number: "01", title: "VELG PROSESS", description: "Velg sveisemetode øverst for å sette riktig k-faktor.")
                
                guideStep(number: "02", title: "LEGG INN DATA", description: "Trykk på Volt, Ampere, Lengde eller Tid for å justere verdiene.")
                
                guideStep(number: "03", title: "LOGG STRENG", description: "Trykk 'LOGG STRENG' for å lagre strengen")
                
                guideStep(number: "04", title: "JOBB HISTORIKK", description: "Jobben lagres i historikken. Du kan hente opp gamle jobber og redigere dem senere.")

            }
        }
        .padding(isDetailed ? 0 : 20)
        .opacity(isDetailed ? 1.0 : 0.8) // Litt mer gjennomsiktig som bakgrunn
    }

    // Hjelpefunksjon for rader
    @ViewBuilder
    func guideStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("[\(number)]")
                .font(RetroTheme.font(size: 14, weight: .bold))
                .foregroundColor(RetroTheme.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RetroTheme.font(size: 14, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                
                Text(description)
                    .font(RetroTheme.font(size: 12))
                    .foregroundColor(RetroTheme.dim)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
