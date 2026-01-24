//
//  SettingsView.swift
//  Varmetilførsel
//
//  Refactored for Clean Retro Style & Native Localization
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- LAGREDE INNSTILLINGER ---
    @AppStorage("app_language") private var selectedLanguage: String = "nb"
    @AppStorage("enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("hidden_process_codes") private var hiddenProcessCodes: String = ""
    @AppStorage("enableExtendedData") private var enableExtendedData = false
    
    // State for skuffen (Process Drawer)
    @State private var showProcessDrawer: Bool = false
    
    @Binding var showSettings: Bool
    
    // --- BEREGNEDE EGENSKAPER ---
    
    // Konverterer String ("nb"/"en") til Bool for Toggle
    var isNorwegian: Binding<Bool> {
        Binding(
            get: { selectedLanguage == "nb" },
            set: { selectedLanguage = $0 ? "nb" : "en" }
        )
    }
    
    // Teller for aktive prosesser
    var activeCount: Int {
        let hiddenSet = Set(hiddenProcessCodes.split(separator: ",").map(String.init))
        return WeldingProcess.allProcesses.filter { !hiddenSet.contains($0.code) }.count
    }
    
    var body: some View {
        ZStack {
            // 1. BAKGRUNN
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 2. HEADER
                HStack {
                    Text("KONFIGURASJON") // Key for Localizable
                        .font(RetroTheme.font(size: 18, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut) { showSettings = false }
                    }){
                        Text("LUKK") // Key for Localizable
                            .font(RetroTheme.font(size: 12, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }
                .padding()
                
                // 3. HOVEDLISTE
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // --- A: GENERELT ---
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "GENERELT")
                            
                            // Språk (Toggle styrer nb/en)
                            RetroToggle(
                                title: "SPRÅK", // Oversettelsen av denne bør inkludere evt status i teksten hvis ønskelig, eller bare hete "Språk" / "Language"
                                isOn: isNorwegian
                            )
                            
                            DividerLine()
                            
                            // Vibrasjon
                            RetroToggle(
                                title: "VIBRASJON",
                                isOn: $enableHaptics
                            )
                            
                            DividerLine()
                            
                            // Utvidet Data (Ny funksjon)
                            RetroToggle(
                                title: "UTVIDET DATA",
                                isOn: $enableExtendedData
                            )
                        }
                        
                        // --- B: KALKULATOR / PROSESSER ---
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "KALKULATOR")
                            
                            HStack(alignment: .center, spacing: 16) {
                                // Info tekst
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SVEISEMETODER")
                                        .font(RetroTheme.font(size: 16, weight: .bold))
                                        .foregroundColor(RetroTheme.primary)
                                    
                                    Text("Velg prosesser, k-faktor og standarder.")
                                        .font(RetroTheme.font(size: 12))
                                        .foregroundColor(RetroTheme.dim)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    // SwiftUI interpolering håndterer oversettelse hvis nøkkelen finnes i stringsdict,
                                    // ellers bør man bruke en format-string.
                                    Text("STATUS: \(activeCount) AKTIVE")
                                        .font(RetroTheme.font(size: 10, weight: .bold))
                                        .foregroundColor(RetroTheme.primary)
                                        .padding(.top, 4)
                                }
                                
                                Spacer()
                                
                                // Endre-knapp
                                Button(action: {
                                    Haptics.selection()
                                    showProcessDrawer = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.system(size: 18))
                                        Text("ENDRE")
                                            .font(RetroTheme.font(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(RetroTheme.primary)
                                    .frame(width: 60, height: 48)
                                    .background(Color.black)
                                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
                        }
                        
                        // --- C: MANUAL ---
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "BRUKERVEILEDNING")
                            RetroGuideView(isDetailed: true)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // --- FOOTER ---
                        VStack(spacing: 6) {
                            Text("Varmetilførsel v1.1")
                            Text("© \(String(Calendar.current.component(.year, from: Date()))) Frode Halrynjo")
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
            
            // 4. SKUFFEN (PROSESS-VELGER)
            RetroModalDrawer(
                isPresented: $showProcessDrawer,
                title: "AKTIVE PROSESSER", // Lokaliseres automatisk
                fromTop: false
            ) {
                processSelectionList
            }
        }
        .crtScreen()
    }
    
    // --- RYDDIG LISTE FOR PROSESSER ---
    var processSelectionList: some View {
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
                            // Navn og kode
                            VStack(alignment: .leading, spacing: 4) {
                                Text(process.name) // Navn kommer fra modell, bør ideelt sett også være LocalizedStringKey
                                    .font(RetroTheme.font(size: 14, weight: .bold))
                                    .foregroundColor(isChecked ? RetroTheme.primary : RetroTheme.dim)
                                
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
                            
                            // k-faktor
                            if !isLocked {
                                Text("k=\(process.kFactor, specifier: "%.1f")")
                                    .font(RetroTheme.font(size: 12, weight: .bold))
                                    .foregroundColor(RetroTheme.dim)
                            }
                            
                            // Checkbox
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
                            .overlay(Rectangle().stroke(isChecked || isLocked ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(isChecked ? RetroTheme.primary.opacity(0.05) : Color.black)
                        .contentShape(Rectangle())
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
    
    // Tar nå inn LocalizedStringKey for automatisk oversettelse
    private func SectionHeader(title: LocalizedStringKey) -> some View {
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

// --- STANDARD RETRO TOGGLE COMPONENT ---
// (Kan gjerne flyttes til Helpers.swift hvis du vil bruke den andre steder)
struct RetroToggle: View {
    let title: LocalizedStringKey // Endret til LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(RetroTheme.font(size: 18, weight: .bold))
                .foregroundColor(RetroTheme.primary)

            Spacer()

            // Selve bryter-området
            ZStack {
                // Rammen (Track)
                RoundedRectangle(cornerRadius: 4)
                    .stroke(RetroTheme.primary, lineWidth: 2)
                    .background(Color.black.opacity(0.01))
                    .frame(width: 60, height: 32)
                
                // Bakgrunn som indikerer PÅ
                if isOn {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RetroTheme.primary.opacity(0.2))
                        .frame(width: 60, height: 32)
                }

                // Knappen (Thumb)
                RoundedRectangle(cornerRadius: 2)
                    .fill(isOn ? RetroTheme.primary : RetroTheme.dim)
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.black, lineWidth: 2)
                            .opacity(0.3)
                    )
                    .shadow(color: isOn ? RetroTheme.primary.opacity(0.8) : .clear, radius: 5)
                    .offset(x: isOn ? 13 : -13)
            }
            .onTapGesture {
                Haptics.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                    isOn.toggle()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isOn.toggle()
            }
        }
    }
}

// Preview
#Preview {
    SettingsView(showSettings: .constant(true))
}
