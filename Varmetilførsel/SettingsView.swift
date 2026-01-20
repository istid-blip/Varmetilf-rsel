//
//  SettingsView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI

// --- NY KOMPONENT: KOMPAKT BRYTER ---
struct RetroCompactSwitch: View {
    let leftLabel: String
    let rightLabel: String
    @Binding var isLeftSelected: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                if !isLeftSelected {
                    Haptics.selection()
                    isLeftSelected = true
                }
            }) {
                Text(leftLabel)
                    .font(RetroTheme.font(size: 12, weight: .bold))
                    .foregroundColor(isLeftSelected ? Color.black : RetroTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isLeftSelected ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(.plain)
            
            Rectangle().fill(RetroTheme.primary).frame(width: 1, height: 20)
            
            Button(action: {
                if isLeftSelected {
                    Haptics.selection()
                    isLeftSelected = false
                }
            }) {
                Text(rightLabel)
                    .font(RetroTheme.font(size: 12, weight: .bold))
                    .foregroundColor(!isLeftSelected ? Color.black : RetroTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(!isLeftSelected ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(.plain)
        }
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(RetroTheme.primary, lineWidth: 1))
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
            Text(title).font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.primary)
            Spacer()
            content
        }
        .padding(.vertical, 8)
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
    
    var body: some View {
        ZStack {
            // 1. BAKGRUNN
            RetroTheme.background.ignoresSafeArea()
            
            // 2. HOVEDINNHOLD
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Text("KONFIGURASJON")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    Spacer()
                    Button(action: { withAnimation(.easeInOut) { showSettings = false } }){
                        Text("TILBAKE")
                            .font(RetroTheme.font(size: 14, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // --- GENERAL ---
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "GENERELT")
                            RetroSettingRow("Språk") {
                                RetroCompactSwitch(leftLabel: "NO", rightLabel: "EN", isLeftSelected: isNorwegian)
                            }
                            DividerLine()
                            RetroSettingRow("Vibrasjon") {
                                RetroCompactSwitch(leftLabel: "PÅ", rightLabel: "AV", isLeftSelected: isHapticsOn)
                            }
                        }
                        
                        // --- SVEISEPROSESSER ---
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "KALKULATOR")
                            Text("Velg hvilke sveiseprosesser som skal være synlige i kalkulatoren.")
                                .font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim).padding(.bottom, 4)
                            
                            Button(action: {
                                Haptics.selection()
                                showProcessDrawer = true // Åpner den nye skuffen
                            }) {
                                HStack {
                                    Text("VELG AKTIVE PROSESSER")
                                        .font(RetroTheme.font(size: 14, weight: .bold))
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12))
                                }
                                .foregroundColor(RetroTheme.primary)
                                .padding()
                                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                            }
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
            .opacity(showProcessDrawer ? 0.3 : 1.0) // Dimmer bakgrunnen
            .disabled(showProcessDrawer) // Hindrer trykk
            
            // 3. SKUFFEN (Den nye Unified Drawer)
            RetroModalDrawer(
                isPresented: $showProcessDrawer,
                title: "AKTIVE PROSESSER",
                fromTop: false // Kommer fra bunnen, sett true for topp
            ) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(WeldingProcess.allProcesses, id: \.self) { process in
                            let isHidden = hiddenProcessCodes.contains(process.code)
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
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(isChecked ? RetroTheme.primary.opacity(0.05) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLocked)
                            
                            // Tynn linje
                            if process != WeldingProcess.allProcesses.last {
                                Rectangle().fill(RetroTheme.dim.opacity(0.2)).frame(height: 1)
                            }
                        }
                    }
                }
                .frame(maxHeight: 350) // Begrenser høyden inni boksen
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
            .padding(.bottom, 2)
    }
    
    private func DividerLine() -> some View {
        Rectangle()
            .fill(RetroTheme.dim.opacity(0.2))
            .frame(height: 1)
    }
}
