//
//  RetroGuideView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI

// MARK: - Data Model
struct GuideStep: Identifiable {
    let id = UUID()
    let number: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let details: LocalizedStringKey?
    var hideInDetailed: Bool? = false // <-- NY LINJE: Standardverdi er false (vises alltid)
}

// MARK: - Data Source
// Tekstene her fungerer som standard (Norsk) OG som oppslagsnøkler for engelsk.
let guideSteps: [GuideStep] = [
    GuideStep(
        number: "01",
        title: "VELG METODE",
        description: "For logging uten k-faktor aktiver BUEENERGI i menyen STRENG DATA.",
        details: nil
    ),
    GuideStep(
        number: "02",
        title: "LEGG INN DATA",
        description: "Trykk på feltene for å justere verdiene. Utvidet data legges inn i STRENG DATA.",
        details: nil
    ),
    GuideStep(
        number: "03",
        title: "LOGG STRENG",
        description: "Trykk 'LOGG STRENG' for å lagre strengen",
        details: nil
    ),
    GuideStep(
        number: "04",
        title: "UTVIDET INFORMASJON",
        description: "Mer informasjon og innstillinger finnes i konfigurasjonsmenyen øverst til venstre (tannhjulet).",
        details: nil,
        hideInDetailed: true
    )
]

// MARK: - Main View
struct Brukermanual: View {
    let isDetailed: Bool // True = Settings (mer tekst), False = Empty State (kun punkter)

    var body: some View {
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading, spacing: 20) {
                // Looper gjennom listen definert over
                ForEach(guideSteps) { step in
                                // Sjekker om punktet skal vises
                                if !(isDetailed && (step.hideInDetailed == true)) {
                                    guideStepView(for: step)
                                }
                }
            }
        }
        .padding(isDetailed ? 0 : 20)
        .opacity(isDetailed ? 1.0 : 0.8) // Litt mer gjennomsiktig som bakgrunn
    }

    // Hjelpefunksjon for rader
    @ViewBuilder
    func guideStepView(for step: GuideStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            
            // Nummerering
            Text("[\(step.number)]")
                .font(RetroTheme.font(size: 14, weight: .bold))
                .foregroundColor(RetroTheme.primary)
                .frame(width: 35, alignment: .leading) // Sikrer rett linjering
            
            VStack(alignment: .leading, spacing: 4) {
                // Tittel
                Text(step.title)
                    .font(RetroTheme.font(size: 14, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                
                // 1. Standard beskrivelse (Vises ALLTID)
                Text(step.description)
                    .font(RetroTheme.font(size: 12))
                    .foregroundColor(RetroTheme.dim)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // 2. Utvidet detaljtekst (Vises KUN ved isDetailed + hvis tekst finnes)
                if isDetailed, let detailText = step.details {
                    Text(detailText)
                        .font(RetroTheme.font(size: 12))
                        .foregroundColor(RetroTheme.dim) // Bruk gjerne en annen farge for kontrast
                        .padding(.top, 2)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
        }
    }
}
