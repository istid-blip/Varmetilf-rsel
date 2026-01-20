//
//  SettingsView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI

// --- NY KOMPONENT: CHUNKY SWITCH (Større og lettere å treffe) ---
struct RetroChunkySwitch: View {
    let leftLabel: String
    let rightLabel: String
    @Binding var isLeftSelected: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Venstre valg
            Button(action: {
                if !isLeftSelected {
                    Haptics.selection()
                    isLeftSelected = true
                }
            }) {
                Text(leftLabel)
                    .font(RetroTheme.font(size: 14, weight: .bold)) // Større font
                    .foregroundColor(isLeftSelected ? Color.black : RetroTheme.primary)
                    .frame(height: 44) // Fast høyde for god trykkflate
                    .padding(.horizontal, 20) // Bredere trykkflate
                    .background(isLeftSelected ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(.plain)
            
            // Skillelinje
            Rectangle()
                .fill(RetroTheme.primary)
                .frame(width: 2, height: 44) // Tykkere og høyere skillelinje
            
            // Høyre valg
            Button(action: {
                if isLeftSelected {
                    Haptics.selection()
                    isLeftSelected = false
                }
            }) {
                Text(rightLabel)
                    .font(RetroTheme.font(size: 14, weight: .bold)) // Større font
                    .foregroundColor(!isLeftSelected ? Color.black : RetroTheme.primary)
                    .frame(height: 44) // Fast høyde
                    .padding(.horizontal, 20) // Bredere trykkflate
                    .background(!isLeftSelected ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(.plain)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(RetroTheme.primary, lineWidth: 2) // Litt kraftigere ramme
        )
    }
}

// --- RAD FOR INNSTILLINGER ---
struct RetroSettingRow<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content
    
    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(RetroTheme.font(size: 16, weight: .bold)) // Litt større tittel
                .foregroundColor(RetroTheme.primary)
            
            Spacer()
            
            content
        }
        .padding(.vertical, 12) // Mer luft mellom radene
    }
}

// --- HOVEDVIEW ---
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- LAGREDE INNSTILLINGER ---
    @AppStorage("app_language") private var selectedLanguage: String = "nb"
    @AppStorage("enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("hidden_process_codes") private var hiddenProcessCodes: String = ""
    
    // State for skuffen
    @State private var showProcessDrawer: Bool = false
    
    @Binding var showSettings: Bool
    
    // Hjelpe-variabler
    var isNorwegian: Binding<Bool> {
        Binding(get: { selectedLanguage == "nb" }, set: { selectedLanguage = $0 ? "nb" : "en" })
    }
    
    var isHapticsOn: Binding<Bool> {
        Binding(get: { enableHaptics }, set: { enableHaptics = $0 })
    }
    
    // Teller for status-tekst
    var activeCount: Int {
        let allCount = WeldingProcess.allProcesses.count
        let hiddenCount = hiddenProcessCodes.split(separator: ",").count
        if hiddenProcessCodes.isEmpty { return allCount }
        return max(0, allCount - hiddenCount)
    }
    
    var body: some View {
        ZStack {
            // 1. BAKGRUNN
            RetroTheme.background.ignoresSafeArea()
            
            // 2. HOVEDINNHOLD
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Text("KONFIGURASJON")
                        .font(RetroTheme.font(size: 18, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    Spacer()
                    Button(action: { withAnimation(.easeInOut) { showSettings = false } }){
                        Text("TILBAKE")
                            .font(RetroTheme.font(size: 14, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10) // Større trykkflate på tilbake-knapp også
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }
                .padding()

                
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) { // Mer luft mellom seksjonene
                        
                        // --- GENERAL ---
                        VStack(alignment: .leading, spacing: 0) {
                            SectionHeader(title: "GENERELT")
                            
                            RetroSettingRow("Språk") {
                                RetroChunkySwitch(leftLabel: "NO", rightLabel: "EN", isLeftSelected: isNorwegian)
                            }
                            
                            DividerLine()
                            
                            RetroSettingRow("Vibrasjon") {
                                RetroChunkySwitch(leftLabel: "PÅ", rightLabel: "AV", isLeftSelected: isHapticsOn)
                            }
                        }
                        
                        // --- SVEISEPROSESSER ---
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "KALKULATOR")
                            
                            // NY LAYOUT: Tekst til venstre, Knapp til høyre
                            HStack(alignment: .center, spacing: 16) {
                                // VENSTRE SIDE: Forklaring
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SVEISEMETODER")
                                        .font(RetroTheme.font(size: 16, weight: .bold))
                                        .foregroundColor(RetroTheme.primary)
                                    
                                    Text("Velg hvilke prosesser som skal være tilgjengelig i listen.")
                                        .font(RetroTheme.font(size: 12))
                                        .foregroundColor(RetroTheme.dim)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    // Statusindikator
                                    Text("STATUS: \(activeCount) AKTIVE")
                                        .font(RetroTheme.font(size: 10, weight: .bold))
                                        .foregroundColor(RetroTheme.primary)
                                        .padding(.top, 4)
                                }
                                
                                Spacer()
                                
                                // HØYRE SIDE: Handlingsknapp
                                Button(action: {
                                    Haptics.selection()
                                    showProcessDrawer = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.system(size: 24))
                                        Text("ENDRE")
                                            .font(RetroTheme.font(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(RetroTheme.primary)
                                    .frame(width: 70, height: 60) // Stor, god firkant
                                    .background(Color.black)
                                    .overlay(
                                        Rectangle().stroke(RetroTheme.primary, lineWidth: 1)
                                    )
                                    // Legg til en liten skygge/offset effekt for "trykkbarhet"
                                    .shadow(color: RetroTheme.dim.opacity(0.3), radius: 0, x: 2, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                            .overlay(
                                Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        // --- MANUAL ---
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "BRUKERVEILEDNING")
                            RetroGuideView(isDetailed: true)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // --- FOOTER ---
                        let year = Calendar.current.component(.year, from: Date())
                        VStack(spacing: 6) {
                            Text("Varmetilførsel v1.0")
                            Text("© \(String(year)) Frode Halrynjo")
                        }
                        .font(RetroTheme.font(size: 10))
                        .foregroundColor(RetroTheme.dim)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(24)
                }
            }
            .opacity(showProcessDrawer ? 0.3 : 1.0)
            .disabled(showProcessDrawer)
            
            // 3. SKUFFEN (Unified Drawer)
                        RetroModalDrawer(
                            isPresented: $showProcessDrawer,
                            title: "AKTIVE PROSESSER",
                            fromTop: false
                        ) {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(WeldingProcess.allProcesses, id: \.self) { process in
                                        let isHidden = hiddenProcessCodes.contains(process.code)
                                        // Merk: Sjekk om din modell bruker "RAW", "Arc" eller "ARC" for energiberegning
                                        // Hvis du er usikker, kan du sjekke om koden er lik 111, 136 osv.
                                        // Her antar jeg "RAW" basert på tidligere info.
                                        let isLocked = process.code == "RAW"
                                        let isChecked = !isHidden
                                        
                                        Button(action: {
                                            if !isLocked {
                                                Haptics.selection()
                                                toggleProcess(process.code)
                                            }
                                        }) {
                                            HStack {
                                                Text(process.name)
                                                    .font(RetroTheme.font(size: 14))
                                                    .foregroundColor(isChecked ? RetroTheme.primary : RetroTheme.dim)
                                                
                                                Spacer()
                                                
                                                if isLocked {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(RetroTheme.dim)
                                                        .padding(.trailing, 8)
                                                }
                                                
                                                Text(process.code)
                                                    .font(RetroTheme.font(size: 10))
                                                    .foregroundColor(RetroTheme.dim)
                                                    .padding(.trailing, 8)
                                                
                                                // Retro Checkbox Square
                                                ZStack {
                                                    if isChecked {
                                                        Rectangle().fill(RetroTheme.primary).frame(width: 8, height: 8)
                                                    }
                                                }
                                                .frame(width: 16, height: 16)
                                                .overlay(Rectangle().stroke(isChecked ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1))
                                            }
                                            .padding(.vertical, 16) // Økt høyde for bedre treffsikkerhet
                                            .padding(.horizontal, 16) // Litt luft på sidene
                                            .background(isChecked ? RetroTheme.primary.opacity(0.05) : Color.black) // Color.black sikrer også treff
                                            .contentShape(Rectangle()) // <--- DETTE ER FIXEN: Gjør hele flaten klikkbar
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(isLocked)
                                        
                                        // Skillelinje
                                        if process != WeldingProcess.allProcesses.last {
                                            Rectangle()
                                                .fill(RetroTheme.dim.opacity(0.2))
                                                .frame(height: 1)
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 350)
                        }
        }
        .crtScreen()
    }
    
    // --- HJELPEFUNKSJONER ---
    private func toggleProcess(_ code: String) {
        var codes = hiddenProcessCodes.split(separator: ",").map { String($0) }
        if codes.contains(code) {
            codes.removeAll { $0 == code }
        } else {
            codes.append(code)
        }
        hiddenProcessCodes = codes.joined(separator: ",")
    }
    
    private func SectionHeader(title: String) -> some View {
        Text(title)
            .font(RetroTheme.font(size: 12))
            .foregroundColor(RetroTheme.dim)
            .padding(.bottom, 4)
    }
    
    private func DividerLine() -> some View {
        Rectangle()
            .fill(RetroTheme.dim.opacity(0.2))
            .frame(height: 1)
            .padding(.vertical, 4)
    }
}
