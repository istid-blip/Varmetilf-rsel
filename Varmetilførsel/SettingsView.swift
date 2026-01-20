//
//  SettingsView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI
import SwiftData

// --- CHUNKY SWITCH (Medium størrelse) ---
struct RetroChunkySwitch: View {
    let leftLabel: String
    let rightLabel: String
    @Binding var isLeftSelected: Bool
    
    // Justerte dimensjoner for "mellomstor" størrelse
    let height: CGFloat = 36
    let hPadding: CGFloat = 16
    
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
                    .font(RetroTheme.font(size: 13, weight: .bold)) // Litt mindre font
                    .foregroundColor(isLeftSelected ? Color.black : RetroTheme.primary)
                    .frame(height: height)
                    .padding(.horizontal, hPadding)
                    .background(isLeftSelected ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(.plain)
            
            // Skillelinje
            Rectangle()
                .fill(RetroTheme.primary)
                .frame(width: 2, height: height)
            
            // Høyre valg
            Button(action: {
                if isLeftSelected {
                    Haptics.selection()
                    isLeftSelected = false
                }
            }) {
                Text(rightLabel)
                    .font(RetroTheme.font(size: 13, weight: .bold)) // Litt mindre font
                    .foregroundColor(!isLeftSelected ? Color.black : RetroTheme.primary)
                    .frame(height: height)
                    .padding(.horizontal, hPadding)
                    .background(!isLeftSelected ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(.plain)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(RetroTheme.primary, lineWidth: 2)
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
                .font(RetroTheme.font(size: 16, weight: .bold))
                .foregroundColor(RetroTheme.primary)
            
            Spacer()
            
            content
        }
        .padding(.vertical, 10) // Litt mindre luft enn sist
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
        let hiddenSet = Set(hiddenProcessCodes.split(separator: ",").map(String.init))
        return WeldingProcess.allProcesses.filter { !hiddenSet.contains($0.code) }.count
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
                            .font(RetroTheme.font(size: 13, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }
                .padding()
              //  .background(RetroTheme.surface)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) { // Justert avstand
                        
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
                            
                            // MODUL: Tekst til venstre, Knapp til høyre
                            HStack(alignment: .center, spacing: 16) {
                                // VENSTRE SIDE: Forklaring
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SVEISEMETODER")
                                        .font(RetroTheme.font(size: 16, weight: .bold))
                                        .foregroundColor(RetroTheme.primary)
                                    
                                    Text("Velg prosesser, k-faktor og standarder (ISO/AWS).")
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
                                
                                // HØYRE SIDE: Handlingsknapp (Litt mindre enn sist)
                                Button(action: {
                                    Haptics.selection()
                                    showProcessDrawer = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.system(size: 20)) // Litt mindre ikon
                                        Text("ENDRE")
                                            .font(RetroTheme.font(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(RetroTheme.primary)
                                    .frame(width: 60, height: 48) // Litt mindre ramme
                                    .background(Color.black)
                                    .overlay(
                                        Rectangle().stroke(RetroTheme.primary, lineWidth: 1)
                                    )
                                    .shadow(color: RetroTheme.dim.opacity(0.3), radius: 0, x: 2, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
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
                            let isLocked = process.code == "Arc"
                            let isChecked = !isHidden
                            
                            Button(action: {
                                if !isLocked {
                                    Haptics.selection()
                                    toggleProcess(process.code)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    
                                    // 1. INFO COLUMN (Navn + Koder)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(process.name)
                                            .font(RetroTheme.font(size: 14, weight: .bold))
                                            .foregroundColor(isChecked ? RetroTheme.primary : RetroTheme.dim)
                                        
                                        // Viser både ISO og AWS kode på linjen under
                                        HStack(spacing: 0) {
                                            Text("ISO: \(process.code)")
                                            if process.awsCode != "-" {
                                                Text(" • AWS: \(process.awsCode)")
                                            }
                                        }
                                        .font(RetroTheme.font(size: 10))
                                        .foregroundColor(RetroTheme.dim)
                                    }
                                    
                                    Spacer()
                                    
                                    // 2. K-FAKTOR (Høyre side)
                                    if !isLocked {
                                        Text("k=\(process.kFactor, specifier: "%.1f")")
                                            .font(RetroTheme.font(size: 12, weight: .bold))
                                            .foregroundColor(RetroTheme.dim)
                                    }
                                    
                                    // 3. CHECKBOX / LOCK
                                    ZStack {
                                        if isLocked {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(RetroTheme.dim)
                                        } else {
                                            if isChecked {
                                                Rectangle().fill(RetroTheme.primary).frame(width: 10, height: 10)
                                            }
                                        }
                                    }
                                    .frame(width: 20, height: 20)
                                    .overlay(Rectangle().stroke(isLocked ? RetroTheme.dim : (isChecked ? RetroTheme.primary : RetroTheme.dim), lineWidth: 1))
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(isChecked ? RetroTheme.primary.opacity(0.05) : Color.black)
                                .contentShape(Rectangle()) // Sikrer trykkflate
                            }
                            .buttonStyle(.plain)
                            .disabled(isLocked)
                            
                            // Skillelinje
                            if process != WeldingProcess.allProcesses.last {
                                Rectangle().fill(RetroTheme.dim.opacity(0.2)).frame(height: 1)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
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
