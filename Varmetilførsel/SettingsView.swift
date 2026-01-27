//
//  SettingsView.swift
//  Varmetilførsel
//
//  Redesigned Extended Data Section
//  Clean Retro Style & Native Localization
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var showSettings: Bool
    
    // --- LAGREDE INNSTILLINGER ---
    @AppStorage("app_language") private var selectedLanguage: String = "nb"
    @AppStorage("enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("hidden_process_codes") private var hiddenProcessCodes: String = ""
    @AppStorage("enableExtendedData") private var enableExtendedData = false
    
    // --- FELT LOGIKK ---
    // useDefaults = true betyr "Smart Auto".
    // Vi vil at togglen skal vise "Manuell Overstyring" (som er det motsatte).
    @Binding var useDefaults: Bool
    
    // Vi trenger tilgang til strengen her inne for å telle valgte felter
    @AppStorage("user_custom_fields_string") private var userCustomFieldsString: String = ""
    
    // State for skuffer
    @State private var showProcessDrawer: Bool = false
    @State private var showFieldDrawer: Bool = false
    
    // --- BEREGNEDE EGENSKAPER ---
    var isNorwegian: Binding<Bool> {
        Binding(get: { selectedLanguage == "nb" }, set: { selectedLanguage = $0 ? "nb" : "en" })
    }
    
    // Invertert binding: Når togglen er PÅ (true), settes useDefaults til false (Manuell)
    var isManualOverride: Binding<Bool> {
        Binding(
            get: { !useDefaults },
            set: { useDefaults = !$0 }
        )
    }
    
    var activeCount: Int {
        let hiddenSet = Set(hiddenProcessCodes.split(separator: ",").map(String.init))
        return WeldingProcess.allProcesses.filter { !hiddenSet.contains($0.code) }.count
    }
    
    var selectedFieldsCount: Int {
        if userCustomFieldsString.isEmpty { return 0 }
        return userCustomFieldsString.split(separator: ",").count
    }
    
    // Hjelper for felt-velgeren
    var selectedFields: Set<WeldField> {
        let raws = userCustomFieldsString.split(separator: ",").map { String($0) }
        return Set(raws.compactMap { WeldField(rawValue: $0) })
    }
    
    var body: some View {
        ZStack {
            // 1. BAKGRUNN
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 2. HEADER
                HStack {
                    Text("KONFIGURASJON")
                        .font(RetroTheme.font(size: 18, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    Spacer()
                    Button(action: { withAnimation(.easeInOut) { showSettings = false } }){
                        Text("LUKK")
                            .font(RetroTheme.font(size: 12, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }.padding()
                
                // 3. HOVEDLISTE
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // --- A: GENERELT ---
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "GENERELT")
                            RetroToggle(title: "SPRÅK", isOn: isNorwegian)
                            DividerLine()
                            RetroToggle(title: "VIBRASJON", isOn: $enableHaptics)
                            
                            DividerLine()
                            
                            // --- UTVIDET DATA SEKSJON ---
                            VStack(spacing: 0) {
                                RetroToggle(title: "UTVIDET DATA", isOn: $enableExtendedData)
                                
                                // Det "tekniske panelet" som felles ned
                                if enableExtendedData {
                                    VStack(alignment: .leading, spacing: 12) {
                                        
                                        // 1. Forklaring / Status
                                        HStack(alignment: .top) {
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 10))
                                                .foregroundColor(RetroTheme.dim)
                                                .padding(.top, 2)
                                            Text(useDefaults ? "Smart-modus aktiv. Felter tilpasses automatisk valgt sveiseprosess." : "Manuell modus. Du bestemmer hvilke felter som vises uansett prosess.")
                                                .font(RetroTheme.font(size: 10))
                                                .foregroundColor(RetroTheme.dim)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.bottom, 4)
                                        
                                        // 2. Overstyrings-bryter
                                        RetroToggle(title: "MANUELL OVERSTYRING", isOn: isManualOverride, isSubToggle: true)
                                        
                                        // 3. Rediger-knapp (Kun synlig ved manuell)
                                        if isManualOverride.wrappedValue {
                                            Button(action: {
                                                Haptics.selection()
                                                showFieldDrawer = true
                                            }) {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("REDIGER FELTER")
                                                            .font(RetroTheme.font(size: 12, weight: .bold))
                                                        Text("\(selectedFieldsCount) valgt")
                                                            .font(RetroTheme.font(size: 9))
                                                            .foregroundColor(RetroTheme.dim)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 10))
                                                }
                                                .foregroundColor(RetroTheme.primary)
                                                .padding(10)
                                                .background(RetroTheme.primary.opacity(0.1))
                                                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                            }
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white.opacity(0.03)) // Svak bakgrunn
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4])) // Stiplet "teknisk" linje
                                            .foregroundColor(RetroTheme.dim.opacity(0.5))
                                    )
                                    .padding(.top, 12) // Avstand fra hovedbryteren
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        
                        // --- B: KALKULATOR ---
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "KALKULATOR")
                            HStack(alignment: .center, spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SVEISEMETODER").font(RetroTheme.font(size: 16, weight: .bold)).foregroundColor(RetroTheme.primary)
                                    Text("Velg prosesser, k-faktor og standarder.").font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim).fixedSize(horizontal: false, vertical: true)
                                    Text("STATUS: \(activeCount) AKTIVE").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(RetroTheme.primary).padding(.top, 4)
                                }
                                Spacer()
                                Button(action: { Haptics.selection(); showProcessDrawer = true }) {
                                    VStack(spacing: 4) { Image(systemName: "slider.horizontal.3").font(.system(size: 18)); Text("ENDRE").font(RetroTheme.font(size: 10, weight: .bold)) }
                                        .foregroundColor(RetroTheme.primary).frame(width: 60, height: 48).background(Color.black).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                }.buttonStyle(.plain)
                            }.padding(14).overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
                        }
                        
                        // --- C: BRUKERVEILEDNING ---
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "BRUKERVEILEDNING")
                            RetroGuideView(isDetailed: true)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // --- FOOTER ---
                        VStack(spacing: 6) {
                            Text("Varmetilførsel v1.2").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                            Text("© \(String(Calendar.current.component(.year, from: Date()))) Frode Halrynjo")
                        }.font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim).frame(maxWidth: .infinity)
                    }.padding(24)
                }
            }
            .opacity(showProcessDrawer || showFieldDrawer ? 0.3 : 1.0)
            .disabled(showProcessDrawer || showFieldDrawer)
            
            // 4. PROSESS-SKUFFEN
            RetroModalDrawer(isPresented: $showProcessDrawer, title: "AKTIVE PROSESSER", fromTop: false) {
                processSelectionList
            }
            
            // 5. FELT-SKUFFEN
            RetroModalDrawer(isPresented: $showFieldDrawer, title: "DINE DATA-FELTER", fromTop: false) {
                fieldSelectionList
            }
        }.crtScreen()
    }
    
    // --- LISTE: FELTER ---
    var fieldSelectionList: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Du overstyrer nå de smarte standardvalgene. Kryss av feltene du ønsker skal være synlige.")
                }
                .font(RetroTheme.font(size: 10))
                .foregroundColor(RetroTheme.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RetroTheme.primary.opacity(0.1))
                .overlay(Rectangle().stroke(RetroTheme.primary.opacity(0.3), lineWidth: 1))
                .padding()
                
                ForEach(WeldField.allCases) { field in
                    let isChecked = selectedFields.contains(field)
                    Button(action: { Haptics.selection(); toggleField(field) }) {
                        HStack {
                            Text(field.rawValue).font(RetroTheme.font(size: 14)).foregroundColor(isChecked ? RetroTheme.primary : RetroTheme.dim)
                            Spacer()
                            ZStack { if isChecked { Rectangle().fill(RetroTheme.primary).frame(width: 10, height: 10) } }.frame(width: 20, height: 20).overlay(Rectangle().stroke(isChecked ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1))
                        }
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .background(isChecked ? RetroTheme.primary.opacity(0.05) : Color.black)
                    }.buttonStyle(.plain)
                    if field != WeldField.allCases.last { Rectangle().fill(RetroTheme.dim.opacity(0.2)).frame(height: 1).padding(.horizontal, 16) }
                }
            }
        }.frame(maxHeight: 400)
    }

    // --- LISTE: PROSESSER ---
    var processSelectionList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(WeldingProcess.allProcesses, id: \.self) { process in
                    let isHidden = hiddenProcessCodes.contains(process.code); let isLocked = process.code == "Arc"; let isChecked = !isHidden
                    Button(action: { if !isLocked { Haptics.selection(); toggleProcess(process.code) } }) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(process.name).font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(isChecked ? RetroTheme.primary : RetroTheme.dim)
                                HStack(spacing: 0) { Text("ISO: \(process.code)"); if process.awsCode != "-" { Text(" • AWS: \(process.awsCode)") } }.font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                            }
                            Spacer()
                            if !isLocked { Text("k=\(process.kFactor, specifier: "%.1f")").font(RetroTheme.font(size: 12, weight: .bold)).foregroundColor(RetroTheme.dim) }
                            ZStack { if isLocked { Image(systemName: "lock.fill").font(.system(size: 12)).foregroundColor(RetroTheme.dim) } else { if isChecked { Rectangle().fill(RetroTheme.primary).frame(width: 10, height: 10) } } }.frame(width: 20, height: 20).overlay(Rectangle().stroke(isChecked || isLocked ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1))
                        }.padding(.vertical, 12).padding(.horizontal, 16).background(isChecked ? RetroTheme.primary.opacity(0.05) : Color.black).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(isLocked)
                    if process != WeldingProcess.allProcesses.last { Rectangle().fill(RetroTheme.dim.opacity(0.2)).frame(height: 1).padding(.horizontal, 16) }
                }
            }
        }.frame(maxHeight: 400)
    }
    
    // --- HJELPEFUNKSJONER ---
    private func toggleProcess(_ code: String) {
        var codes = hiddenProcessCodes.split(separator: ",").map { String($0) }; if codes.contains(code) { codes.removeAll { $0 == code } } else { codes.append(code) }; hiddenProcessCodes = codes.joined(separator: ",")
    }
    
    private func toggleField(_ field: WeldField) {
        var current = selectedFields
        if current.contains(field) { current.remove(field) } else { current.insert(field) }
        userCustomFieldsString = current.map { $0.rawValue }.joined(separator: ",")
    }
    
    private func SectionHeader(title: LocalizedStringKey) -> some View {
        Text(title).font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim).padding(.bottom, 4)
    }
    private func DividerLine() -> some View {
        Rectangle().fill(RetroTheme.dim.opacity(0.2)).frame(height: 1).padding(.vertical, 4)
    }
}


