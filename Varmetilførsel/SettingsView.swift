//
//  SettingsView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI

// --- NY KOMPONENT: KOMPAKT BRYTER (For å ha på linje) ---
struct RetroCompactSwitch: View {
    let leftLabel: String
    let rightLabel: String
    @Binding var isLeftSelected: Bool // True = Venstre, False = Høyre
    
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
                    .font(RetroTheme.font(size: 12, weight: .bold))
                    .foregroundColor(isLeftSelected ? Color.black : RetroTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isLeftSelected ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(.plain)
            
            // Skillelinje
            Rectangle()
                .fill(RetroTheme.primary)
                .frame(width: 1, height: 20)
            
            // Høyre valg
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
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(RetroTheme.primary, lineWidth: 1)
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
                .font(RetroTheme.font(size: 14))
                .foregroundColor(RetroTheme.primary)
            
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
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            showSettings = false
                        }
                    }){
                        Text("TILBAKE")
                            .font(RetroTheme.font(size: 14, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
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
                                RetroCompactSwitch(
                                    leftLabel: "NO",
                                    rightLabel: "EN",
                                    isLeftSelected: isNorwegian
                                )
                            }
                            
                            DividerLine()
                            
                            RetroSettingRow("Vibrasjon") {
                                RetroCompactSwitch(
                                    leftLabel: "PÅ",
                                    rightLabel: "AV",
                                    isLeftSelected: isHapticsOn
                                )
                            }
                        }
                        
                        // --- SVEISEPROSESSER ---
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "KALKULATOR")
                            
                            Text("Velg hvilke sveiseprosesser som skal være synlige i kalkulatoren.")
                                .font(RetroTheme.font(size: 12))
                                .foregroundColor(RetroTheme.dim)
                                .padding(.bottom, 4)
                            
                            Button(action: {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showProcessDrawer = true
                                }
                            }) {
                                HStack {
                                    Text("VELG AKTIVE PROSESSER")
                                        .font(RetroTheme.font(size: 14, weight: .bold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
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
            
            // 3. SKUFFEN (DRAWER)
            if showProcessDrawer {
                // Klikk-fanger bak
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { showProcessDrawer = false }
                    }
                
                // Selve skuffen
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Skuff Header
                        HStack {
                            Text("AKTIVE PROSESSER")
                                .font(RetroTheme.font(size: 14, weight: .bold))
                                .foregroundColor(RetroTheme.primary)
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) { showProcessDrawer = false }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                            }
                        }
                        .padding()
                        .background(Color.black)
                        .overlay(Rectangle().frame(height: 1).foregroundColor(RetroTheme.primary), alignment: .bottom)
                        
                        // Skuff Innhold
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
                                            
                                            // Retro Checkbox
                                            ZStack {
                                                if isChecked {
                                                    Rectangle()
                                                        .fill(RetroTheme.primary)
                                                        .frame(width: 10, height: 10)
                                                }
                                            }
                                            .frame(width: 20, height: 20)
                                            .overlay(Rectangle().stroke(isChecked ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1))
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .background(isChecked ? RetroTheme.primary.opacity(0.05) : Color.clear)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isLocked)
                                    
                                    // Skillelinje mellom valgene
                                    Divider().background(RetroTheme.dim.opacity(0.3))
                                }
                            }
                        }
                        .frame(maxHeight: 400) // Begrenser høyden
                    }
                    .background(Color.black)
                    .overlay(
                        // Grønn kantlinje rundt toppen av skuffen
                        Rectangle()
                            .stroke(RetroTheme.primary, lineWidth: 1)
                            .padding(.top, -1) // Justering for å unngå dobbel linje
                    )
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
                .zIndex(10)
            }
        }
        .crtScreen() // Hvis du har denne modifieren tilgjengelig
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
    
    // Enkel hjelper for overskrifter
    private func SectionHeader(title: String) -> some View {
        Text(title)
            .font(RetroTheme.font(size: 12))
            .foregroundColor(RetroTheme.dim)
            .padding(.bottom, 2)
    }
    
    // Enkel hjelper for linjer
    private func DividerLine() -> some View {
        Rectangle()
            .fill(RetroTheme.dim.opacity(0.2))
            .frame(height: 1)
    }
}

