//
//  SettingsView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI

// --- NY SKUFF: PROCESS SELECTION DRAWER ---
// (Denne ligner på UnifiedInputDrawer, men er tilpasset prosessvalg)
struct ProcessSelectionDrawer: View {
    @Binding var hiddenProcessCodes: String
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Bakgrunn (Samme stil som timer-skuffen)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.dim, lineWidth: 1))
                .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 15)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("CONFIGURE PROCESS LIST")
                        .font(RetroTheme.font(size: 12, weight: .bold))
                        .foregroundColor(RetroTheme.dim)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(RetroTheme.primary)
                    }
                }
                .padding(15)
                .background(Color.white.opacity(0.05))
                
                Divider().background(RetroTheme.dim.opacity(0.3))
                
                // Liste over prosesser
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(WeldingProcess.allProcesses, id: \.self) { process in
                            let isHidden = hiddenProcessCodes.contains(process.code)
                            let isLocked = process.code == "Arc" // ARc kan ikke skjules
                            
                            Button(action: {
                                if !isLocked {
                                    toggleProcess(process.code)
                                    Haptics.selection()
                                }
                            }) {
                                HStack {
                                    // Venstre side: Navn og kode
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(process.name)
                                            .font(RetroTheme.font(size: 14, weight: .bold))
                                            .foregroundColor(isHidden ? RetroTheme.dim : RetroTheme.primary)
                                        Text("ISO 4063: \(process.code)")
                                            .font(RetroTheme.font(size: 9))
                                            .foregroundColor(RetroTheme.dim)
                                    }
                                    
                                    Spacer()
                                    
                                    // Høyre side: K-faktor og Checkboks
                                    HStack(spacing: 15) {
                                        VStack(alignment: .trailing, spacing: 0) {
                                            Text("k-factor")
                                                .font(RetroTheme.font(size: 8))
                                                .foregroundColor(RetroTheme.dim)
                                            Text(String(format: "%.1f", process.kFactor))
                                                .font(RetroTheme.font(size: 14, weight: .black))
                                                .foregroundColor(isHidden ? RetroTheme.dim : RetroTheme.primary)
                                        }
                                        
                                        // Retro Checkboks visualisering
                                        ZStack {
                                            Rectangle()
                                                .stroke(isHidden ? RetroTheme.dim : RetroTheme.primary, lineWidth: 1)
                                                .frame(width: 20, height: 20)
                                            
                                            if !isHidden {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(RetroTheme.primary)
                                            }
                                        }
                                        .opacity(isLocked ? 0.3 : 1.0)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 15)
                                .background(isHidden ? Color.clear : RetroTheme.primary.opacity(0.05))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isLocked)
                            
                            Divider().background(RetroTheme.dim.opacity(0.2)).padding(.leading, 15)
                        }
                    }
                }
            }
        }
        .frame(width: 340, height: 450) // Litt større høyde for å vise listen godt
    }
    
    // Logikk for å oppdatere den lagrede strengen
    private func toggleProcess(_ code: String) {
        var codes = hiddenProcessCodes.split(separator: ",").map { String($0) }
        if codes.contains(code) {
            codes.removeAll { $0 == code }
        } else {
            codes.append(code)
        }
        hiddenProcessCodes = codes.joined(separator: ",")
    }
}

// --- KOMPONENT: RETRO SLIDE SWITCH ---
struct RetroSlideSwitch: View {
    let title: LocalizedStringKey
    let leftLabel: String
    let rightLabel: String
    @Binding var isLeftSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.primary)
            ZStack {
                Rectangle().stroke(RetroTheme.dim, lineWidth: 1).background(Color.black).frame(height: 40)
                GeometryReader { geo in
                    let width = geo.size.width / 2
                    Rectangle().fill(RetroTheme.primary).frame(width: width, height: geo.size.height).offset(x: isLeftSelected ? 0 : width).animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLeftSelected)
                    HStack(spacing: 0) {
                        Button(action: { if !isLeftSelected { isLeftSelected = true; Haptics.selection() } }) {
                            Text(leftLabel).font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(isLeftSelected ? .black : RetroTheme.primary).frame(width: width, height: geo.size.height).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        Button(action: { if isLeftSelected { isLeftSelected = false; Haptics.selection() } }) {
                            Text(rightLabel).font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(!isLeftSelected ? .black : RetroTheme.primary).frame(width: width, height: geo.size.height).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }
            }.frame(height: 40)
        }.padding(.vertical, 5)
    }
}

// --- HOVEDVIEW: SETTINGS VIEW ---
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showSettings: Bool
    
    @AppStorage("app_language") private var selectedLanguage: String = "nb"
    @AppStorage("enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("hidden_process_codes") private var hiddenProcessCodes: String = ""
    @AppStorage("show_extended_data") private var showExtendedData: Bool = false
    
    @State private var showProcessDrawer = false // State for å styre skuffen
    
    var isNorwegian: Binding<Bool> { Binding(get: { selectedLanguage == "nb" }, set: { selectedLanguage = $0 ? "nb" : "en" }) }
    var isHapticsOn: Binding<Bool> { Binding(get: { enableHaptics }, set: { enableHaptics = $0 }) }
    // NY BINDING FOR KNAPPEN:
    var isExtendedDataOn: Binding<Bool> { Binding(get: { showExtendedData }, set: { showExtendedData = $0 }) }
    // Beregner antall aktive prosesser for å vise på knappen
    var activeCount: Int {
        let hidden = hiddenProcessCodes.split(separator: ",").count
        return max(0, WeldingProcess.allProcesses.count - hidden)
    }
    
    var body: some View {
        ZStack {
            // BAKGRUNN
            RetroTheme.background.ignoresSafeArea()
            
            // Klikk-fanger for å lukke skuffen
            if showProcessDrawer {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showProcessDrawer = false }
                    }
                    .zIndex(10)
            }
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Text("CONFIGURATION").font(RetroTheme.font(size: 16, weight: .heavy)).foregroundColor(RetroTheme.primary)
                    Spacer()
                    Button(action: { withAnimation(.easeInOut) { showSettings = false } }){
                        Text("BACK").font(RetroTheme.font(size: 16, weight: .heavy)).foregroundColor(RetroTheme.primary).padding(8).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }.padding()
                .zIndex(1) // Sikrer at knappen alltid er trykkbar (hvis ikke skuffen dekker den)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        Rectangle().fill(RetroTheme.dim.opacity(0.3)).frame(height: 1)
                        
                        // SECTION: LANGUAGE & HAPTICS
                        RetroSlideSwitch(title: "LANGUAGE", leftLabel: "NORSK (NO)", rightLabel: "ENGLISH (EN)", isLeftSelected: isNorwegian)
                        RetroSlideSwitch(title: "VIBRATION FEEDBACK", leftLabel: "ENABLED [1]", rightLabel: "DISABLED [0]", isLeftSelected: isHapticsOn)
                        RetroSlideSwitch(title: "EXTENDED DATA BUTTON", leftLabel: "SHOW [1]", rightLabel: "HIDE [0]", isLeftSelected: isExtendedDataOn)
                        Rectangle().fill(RetroTheme.dim.opacity(0.3)).frame(height: 1).padding(.vertical, 10)
                        
                        // SECTION: PROCESS CONFIGURATION (Nå med knapp for skuff)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACTIVE WELDING PROCESSES")
                                .font(RetroTheme.font(size: 14))
                                .foregroundColor(RetroTheme.primary)
                            
                            Text("Customize the list of available processes.")
                                .font(RetroTheme.font(size: 10))
                                .foregroundColor(RetroTheme.dim)
                            
                            // KNAPP FOR Å ÅPNE SKUFFEN
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showProcessDrawer = true
                                    Haptics.selection()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle.portrait")
                                        .font(.system(size: 18))
                                        .foregroundColor(RetroTheme.primary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("CONFIGURE PROCESSES")
                                            .font(RetroTheme.font(size: 14, weight: .bold))
                                            .foregroundColor(RetroTheme.primary)
                                        Text("\(activeCount) active processes selected")
                                            .font(RetroTheme.font(size: 10))
                                            .foregroundColor(RetroTheme.dim)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(RetroTheme.dim)
                                }
                                .padding(15)
                                .background(Color.black.opacity(0.3))
                                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Rectangle().fill(RetroTheme.dim.opacity(0.3)).frame(height: 1).padding(.vertical, 20)

                        // SECTION: MANUAL
                        RetroGuideView(isDetailed: true)

                        Spacer()
                        
                        // FOOTER
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
                // Vi gjør innholdet litt uskarpt og "deaktivert" når skuffen er oppe
                .opacity(showProcessDrawer ? 0.3 : 1.0)
                .disabled(showProcessDrawer)
            }
            
            // SKUFFEN
            if showProcessDrawer {
                VStack {
                    Spacer()
                    ProcessSelectionDrawer(
                        hiddenProcessCodes: $hiddenProcessCodes,
                        onClose: { withAnimation { showProcessDrawer = false } }
                    )
                    .padding(.bottom, 30) // Løft den litt opp fra bunnen
                }
                .transition(.move(edge: .bottom))
                .zIndex(100)
            }
        }
        .crtScreen()
        .navigationBarHidden(true)
    }
}
