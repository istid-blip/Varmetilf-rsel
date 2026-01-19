//
//  SettingsView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//
import SwiftUI

struct RetroCheckbox: View {
    let label: String
    let code: String
    let isChecked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack {
                Text(label)
                    .font(RetroTheme.font(size: 14, weight: .bold))
                    .foregroundColor(isChecked ? RetroTheme.primary : RetroTheme.dim)
                
                Spacer()
                
                Text(code)
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(RetroTheme.dim)
                    .padding(.trailing, 8)
                
                // Retro checkboks stil: [X] eller [ ]
                Text(isChecked ? "[X]" : "[ ]")
                    .font(RetroTheme.font(size: 14, weight: .bold))
                    .foregroundColor(isChecked ? RetroTheme.primary : RetroTheme.dim)
            }
            .padding(12)
            .background(isChecked ? RetroTheme.primary.opacity(0.1) : Color.clear)
            .overlay(Rectangle().stroke(isChecked ? RetroTheme.primary : RetroTheme.dim.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// --- NY KOMPONENT: RETRO SLIDE SWITCH ---
struct RetroSlideSwitch: View {
    let title: LocalizedStringKey
    let leftLabel: String
    let rightLabel: String
    @Binding var isLeftSelected: Bool // True = Venstre valg, False = Høyre valg
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tittel
            Text(title)
                .font(RetroTheme.font(size: 14))
                .foregroundColor(RetroTheme.primary)
            
            // Selve bryteren
            ZStack {
                // Ramme/Bakgrunn
                Rectangle()
                    .stroke(RetroTheme.dim, lineWidth: 1)
                    .background(Color.black)
                    .frame(height: 40)
                
                GeometryReader { geo in
                    let width = geo.size.width / 2
                    
                    // Den "aktive" blokken som sklir (Invertert farge)
                    Rectangle()
                        .fill(RetroTheme.primary)
                        .frame(width: width, height: geo.size.height)
                        .offset(x: isLeftSelected ? 0 : width)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLeftSelected)
                    
                    // Tekst-lagene
                    HStack(spacing: 0) {
                        // Venstre Valg
                        Button(action: {
                            if !isLeftSelected {
                                isLeftSelected = true
                                Haptics.selection()
                            }
                        }) {
                            Text(leftLabel)
                                .font(RetroTheme.font(size: 14, weight: .bold))
                                // Hvis valgt -> Sort tekst (fordi bakgrunnen er lys), ellers Primary tekst
                                .foregroundColor(isLeftSelected ? .black : RetroTheme.primary)
                                .frame(width: width, height: geo.size.height)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Høyre Valg
                        Button(action: {
                            if isLeftSelected {
                                isLeftSelected = false
                                Haptics.selection()
                            }
                        }) {
                            Text(rightLabel)
                                .font(RetroTheme.font(size: 14, weight: .bold))
                                .foregroundColor(!isLeftSelected ? .black : RetroTheme.primary)
                                .frame(width: width, height: geo.size.height)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 40)
        }
        .padding(.vertical, 5)
    }
}

// --- HOVEDVIEW ---
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- LAGREDE INNSTILLINGER ---
    @AppStorage("app_language") private var selectedLanguage: String = "nb"
    @AppStorage("enable_haptics") private var enableHaptics: Bool = true
    // Vi lagrer prosesser som er SKJULT. Format: "111,141,15"
        // Dette er sikrere enn å lagre de som er vist, i tilfelle vi legger til nye senere.
        @AppStorage("hidden_process_codes") private var hiddenProcessCodes: String = ""
    
    // Hjelpe-variabler for SlideSwitchen
    // Vi mapper app-storage variablene til en Bool for switchen
    var isNorwegian: Binding<Bool> {
        Binding(
            get: { selectedLanguage == "nb" },
            set: { selectedLanguage = $0 ? "nb" : "en" }
        )
    }
    
    var isHapticsOn: Binding<Bool> {
        Binding(
            get: { enableHaptics },
            set: { enableHaptics = $0 }
        )
    }
    
    @Binding var showSettings: Bool //Kobling for å få settings inn og ut fra venstre
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    
                    
                    Text("CONFIGURATION")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut) {
                            showSettings = false
                        }
                    }){
                        Text("BACK")
                            .font(RetroTheme.font(size: 16, weight: .heavy))
                            .foregroundColor(RetroTheme.primary)
                            .padding(8)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                    
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        
                        // DEKORATIV LINJE
                        Rectangle()
                            .fill(RetroTheme.dim.opacity(0.3))
                            .frame(height: 1)
                        
                        // SECTION: LANGUAGE
                        RetroSlideSwitch(
                            title: "LANGUAGE",
                            leftLabel: "NORSK (NO)",
                            rightLabel: "ENGLISH (EN)",
                            isLeftSelected: isNorwegian
                        )
                        
                        // SECTION: HAPTICS
                        // Merk: Logikken her er litt annerledes siden "PÅ" ofte føles naturlig til høyre,
                        // men switchen tar "Venstre/Høyre".
                        // Her: Venstre = PÅ, Høyre = AV (eller omvendt etter preferanse).
                        // La oss kjøre: Venstre = ON, Høyre = OFF for å matche "1" og "0".
                        RetroSlideSwitch(
                            title: "VIBRATION FEEDBACK",
                            leftLabel: "ENABLED [1]",
                            rightLabel: "DISABLED [0]",
                            isLeftSelected: isHapticsOn
                        )
                        
                        
                        // SECTION: PROCESS CONFIGURATION
                                                Text("ACTIVE WELDING PROCESSES")
                                                    .font(RetroTheme.font(size: 14))
                                                    .foregroundColor(RetroTheme.primary)
                                                    .padding(.bottom, 5)
                                                
                                                Text("Select which processes to show in the calculator.")
                                                    .font(RetroTheme.font(size: 10))
                                                    .foregroundColor(RetroTheme.dim)
                                                    .padding(.bottom, 10)
                                                
                                                VStack(spacing: 8) {
                                                    ForEach(WeldingProcess.allProcesses, id: \.self) { process in
                                                        let isHidden = hiddenProcessCodes.contains(process.code)
                                                        // Vi kan ikke skjule "RAW" (Arc Energy), den må alltid være der som fallback
                                                        let isLocked = process.code == "RAW"
                                                        
                                                        RetroCheckbox(
                                                            label: process.name,
                                                            code: process.code,
                                                            isChecked: !isHidden, // Den er sjekket hvis den IKKE er skjult
                                                            action: {
                                                                if !isLocked {
                                                                    toggleProcess(process.code)
                                                                }
                                                            }
                                                        )
                                                        .opacity(isLocked ? 0.5 : 1.0) // Visuelt indiker at RAW er låst
                                                    }
                                                }
                                                
                                                Rectangle().fill(RetroTheme.dim.opacity(0.3)).frame(height: 1).padding(.vertical, 20)
                        
                        // DEKORATIV LINJE
                        Rectangle()
                            .fill(RetroTheme.dim.opacity(0.3))
                            .frame(height: 1)
                            .padding(.vertical, 20)

                        // SECTION: MANUAL
                        // Her viser vi den detaljerte versjonen av guiden
                        RetroGuideView(isDetailed: true)

                        Spacer()
                        
                        let year = Calendar.current.component(.year, from: Date())
                        let yearString = year.formatted(.number.grouping(.never))

                            VStack(spacing: 8) {
                                Text("Varmetilførsel v1.0")
                                Text("© \(yearString) Frode Halrynjo. Med enerett.")
                        }
                        .font(RetroTheme.font(size: 10))
                        .foregroundColor(RetroTheme.dim)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                }
            }
        }
        .crtScreen()
        .navigationBarHidden(true)
        
        
        
    }
    // ... (resten av body-koden slutter her) ...
        
        // Funksjon for å legge til eller fjerne koder fra den lagrede strengen
        private func toggleProcess(_ code: String) {
            var codes = hiddenProcessCodes.split(separator: ",").map { String($0) }
            
            if codes.contains(code) {
                // Hvis den er skjult -> fjern den (gjør den synlig)
                codes.removeAll { $0 == code }
            } else {
                // Hvis den er synlig -> legg til i skjult-listen
                codes.append(code)
            }
            
            hiddenProcessCodes = codes.joined(separator: ",")
        }

    } // <--- Dette er den aller siste parentesen i SettingsView
    


