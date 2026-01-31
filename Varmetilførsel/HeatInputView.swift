//
//  HeatInputView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//  Updated with Resizable SelectableInput & Color Logic
//

import SwiftUI
import SwiftData
import Combine

// --- 0. DATA FIELD DEFINITIONS ---
enum WeldField: String, CaseIterable, Identifiable {
    case passType = "Pass Type"
    case transfer = "Transfer Mode"
    case filler = "Filler Material"
    case diameter = "Diameter"
    case polarity = "Polarity"
    case wfs = "Wire Feed Speed"
    case gas = "Gas Type"
    case flow = "Gas Flow"
    case interpass = "Interpass Temp"
    // case calcSpeed = "Calc. Travel Speed"
    
    var id: String { rawValue }
}

// --- 1. SVEISEPROSESS MODELL ---
struct WeldingProcess: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let awsCode: String
    let kFactor: Double
    let defaultVoltage: String
    let defaultAmperage: String
    let relevantFields: Set<WeldField>
    
    static let allFields: Set<WeldField> = Set(WeldField.allCases)
    
    static let solidProcessFields: Set<WeldField> = [.passType, .filler, .diameter, .polarity, .interpass]
    static let tigFields: Set<WeldField> = [.passType, .filler, .diameter, .polarity, .gas, .flow, .interpass]
    static let wireProcessFields: Set<WeldField> = allFields
    
    static let allProcesses: [WeldingProcess] = [
        WeldingProcess(name: "Arc energy", code: "Arc", awsCode: "-", kFactor: 1.0, defaultVoltage: "0.0", defaultAmperage: "0", relevantFields: allFields),
        WeldingProcess(name: "Submerged arc welding", code: "121", awsCode: "SAW", kFactor: 1.0, defaultVoltage: "30.0", defaultAmperage: "500", relevantFields: [.passType, .filler, .diameter, .polarity, .wfs, .interpass]),
        WeldingProcess(name: "MMA / Covered electrode", code: "111", awsCode: "SMAW", kFactor: 0.8, defaultVoltage: "23.0", defaultAmperage: "120", relevantFields: solidProcessFields),
        WeldingProcess(name: "MIG welding", code: "131", awsCode: "GMAW", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "200", relevantFields: wireProcessFields),
        WeldingProcess(name: "MAG welding", code: "135", awsCode: "GMAW", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "200", relevantFields: wireProcessFields),
        WeldingProcess(name: "FCAW No Gas", code: "114", awsCode: "FCAW-S", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "180", relevantFields: [.passType, .transfer, .filler, .diameter, .polarity, .wfs, .interpass]),
        WeldingProcess(name: "FCAW Active Gas", code: "136", awsCode: "FCAW-G", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "220", relevantFields: wireProcessFields),
        WeldingProcess(name: "FCAW Inert Gas", code: "137", awsCode: "FCAW-G", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "220", relevantFields: wireProcessFields),
        WeldingProcess(name: "MCAW Active Gas", code: "138", awsCode: "GMAW-C", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "240", relevantFields: wireProcessFields),
        WeldingProcess(name: "MCAW Inert Gas", code: "139", awsCode: "GMAW-C", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "240", relevantFields: wireProcessFields),
        WeldingProcess(name: "TIG welding", code: "141", awsCode: "GTAW", kFactor: 0.6, defaultVoltage: "14.0", defaultAmperage: "110", relevantFields: tigFields),
        WeldingProcess(name: "Plasma arc welding", code: "15", awsCode: "PAW", kFactor: 0.6, defaultVoltage: "25.0", defaultAmperage: "150", relevantFields: tigFields)
    ]
}

func formatNumber(_ value: Double, decimals: Int = 1) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimals
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
}

// --- 2. HOVEDVISNING ---
struct HeatInputView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    enum InputTarget: String, Identifiable {
        case voltage, amperage, time, length
        case diameter, wfs
        case interpass, gasFlow
        var id: String { rawValue }
    }
    
    @State private var showSettings = false
    @State private var focusedField: InputTarget? = nil
    @State private var isNamingJob: Bool = false
    @State private var tempJobName: String = ""
    @FocusState private var isJobNameFocused: Bool
    
    
    
    @Query(sort: \WeldGroup.date, order: .reverse) private var jobHistory: [WeldGroup]
    
    // STORAGE
    @AppStorage("enableExtendedData") private var enableExtendedData = false
    @AppStorage("heat_selected_process_name") private var selectedProcessName: String = "Arc energy"
    @AppStorage("heat_voltage") private var voltageStr: String = ""
    @AppStorage("heat_amperage") private var amperageStr: String = ""
    @AppStorage("heat_time") private var timeStr: String = ""
    @AppStorage("heat_length") private var lengthStr: String = ""
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    @AppStorage("heat_pass_counter") private var passCounter: Int = 1
    @AppStorage("heat_active_job_id") private var storedJobID: String = ""
    
    // VISIBILITY SETTINGS
    @AppStorage("hidden_process_codes") private var hiddenProcessCodes: String = ""
    @AppStorage("use_process_field_defaults") private var useProcessDefaults: Bool = true
    @AppStorage("user_custom_fields_string") private var userCustomFieldsString: String = WeldField.allCases.map { $0.rawValue }.joined(separator: ",")
    
    // STORAGE FOR UTVIDET DATA
    @AppStorage("heat_gas_type") private var extGasType: String = ""
    @AppStorage("heat_transfer_mode") private var extTransferMode: String = "Short"
    @AppStorage("heat_filler_mat") private var extFillerMaterial: String = ""
    
    @State private var extActualInterpass: Double = 0.0
    @State private var extPassType: String = "Fill"
    @State private var extGasFlow: Double = 0.0
    
    @State private var currentJobName: String = ""
    
    // STOPWATCH STORAGE
    @AppStorage("stopwatch_is_running") private var isTimerRunning: Bool = false
    @AppStorage("stopwatch_start_timestamp") private var timerStartTimestamp: Double = 0.0
    @AppStorage("stopwatch_accumulated_time") private var timerAccumulatedTime: Double = 0.0
    
    // UI STATES
    @State private var showExtendedDrawer = false

    @State private var extDiameter: Double = 0.0
    @State private var extPolarity: String = "DC+"
    @State private var extWireFeed: Double = 0.0
    @State private var extIsArcEnergy: Bool = false
    
    private let uiUpdateTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var activeJobID: UUID? {
        get { storedJobID.isEmpty ? nil : UUID(uuidString: storedJobID) }
        nonmutating set { storedJobID = newValue?.uuidString ?? "" }
    }
    
    var availableProcesses: [WeldingProcess] {
        let hidden = hiddenProcessCodes.split(separator: ",").map { String($0) }
        return WeldingProcess.allProcesses.filter { process in !hidden.contains(process.code) }
    }
    
    var currentProcess: WeldingProcess {
        WeldingProcess.allProcesses.first(where: { $0.name == selectedProcessName }) ?? WeldingProcess.allProcesses.first!
    }
    
    var visibleFields: Set<WeldField> {
        if useProcessDefaults {
            return currentProcess.relevantFields
        } else {
            let rawValues = userCustomFieldsString.split(separator: ",").map { String($0) }
            return Set(rawValues.compactMap { WeldField(rawValue: $0) })
        }
    }
    
    var heatInput: Double {
        let v = voltageStr.toDouble; let i = amperageStr.toDouble; let t = timeStr.toDouble; let l = lengthStr.toDouble
        let k = extIsArcEnergy ? 1.0 : efficiency
        return l == 0 ? 0 : ((v * i * t) / (l * 1000)) * k
    }
    
    var calculatedSpeed: Double {
        let l = lengthStr.toDouble; let t = timeStr.toDouble
        return t == 0 ? 0 : (l / t) * 60
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. BAKGRUNN
                RetroTheme.background.ignoresSafeArea()
                
                // 2. KLIKK-FANGER
                if focusedField != nil {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { focusedField = nil } }
                        .zIndex(1)
                }
                
                ZStack {
                    VStack(spacing: 0) {
                        
                        // HEADER
                        Group {
                            HStack {
                                Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)){ showSettings = true } }){
                                    Image(systemName: "gearshape.fill").font(.system(size: 20)).foregroundColor(RetroTheme.primary).padding(8)
                                }
                                Spacer()
                                Text(extIsArcEnergy ? "ARC ENERGY" : "HEAT INPUT")
                                    .font(RetroTheme.font(size: 26, weight: .heavy))
                                    .foregroundColor(RetroTheme.primary)
                                Spacer()
                                Color.clear.frame(width: 40, height: 40)
                            }.padding()
                            
                            VStack(spacing: 25) {
                                HStack(alignment: .top, spacing: 0) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("PROCESS").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                        RetroDropdown(title: "PROCESS", selection: currentProcess, options: availableProcesses, onSelect: { selectProcess($0) }, itemText: { $0.name }, itemDetail: { process in process.code == "Arc" ? "ISO/TR 18491" : "ISO 4063: \(process.code)"})
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .disabled(focusedField != nil || isTimerRunning) // Sperrer menyen
                                            .opacity(focusedField != nil || isTimerRunning ? 0.5 : 1.0)
                                    }
                                    Spacer(minLength: 20)
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text("CURRENT PASS (kJ/mm)").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                        Text(String(format: "%.2f", heatInput)).font(RetroTheme.font(size: 36, weight: .black)).foregroundColor(RetroTheme.primary).shadow(color: RetroTheme.primary.opacity(0.5), radius: 5)
                                        if activeJobID != nil { Text("• ACTIVE JOB").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(RetroTheme.primary).blinkEffect() }
                                    }.frame(minWidth: 160, alignment: .trailing)
                                }.padding(.horizontal)
                            }
                        }.zIndex(10)
                        
                        // INPUT BOKS (Formelfeltet)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(isNamingJob ? Color.green.opacity(0.15) : Color.black.opacity(0.2)).stroke(isNamingJob ? Color.green : RetroTheme.dim, lineWidth: isNamingJob ? 2 : 1)
                            
                            if isNamingJob {
                                VStack(spacing: 15) {
                                    Text("SAVE JOB RECORD").font(RetroTheme.font(size: 12, weight: .bold)).foregroundColor(Color.green)
                                    TextField("Job Name / ID", text: $tempJobName).font(RetroTheme.font(size: 18, weight: .bold)).foregroundColor(Color.green).padding(10).background(Color.black.opacity(0.5)).overlay(Rectangle().stroke(Color.green, lineWidth: 1)).padding(.horizontal, 30).focused($isJobNameFocused).onSubmit { finalizeAndSaveJob() }
                                    HStack(spacing: 20) {
                                        Button("CANCEL") { withAnimation { isNamingJob = false } }.font(RetroTheme.font(size: 11)).foregroundColor(Color.green.opacity(0.7))
                                        Button("SAVE & RESET") { finalizeAndSaveJob() }.font(RetroTheme.font(size: 11, weight: .bold)).foregroundColor(.black).padding(10).background(Color.green)
                                    }
                                }
                            } else {
                                VStack(spacing: 15) {
                                    HStack(alignment: .center, spacing: 8) {
                                        // Endre betingelsen i if-setningen:
                                        // Vi sjekker nå både at det ikke er "Arc"-prosessen OG at toggle-knappen (!extIsArcEnergy) er av.
                                        if currentProcess.code != "Arc" && !extIsArcEnergy {
                                            VStack(spacing: 0) {
                                                Text("k-factor")
                                                    .font(RetroTheme.font(size: 10))
                                                    .foregroundColor(RetroTheme.dim)
                                                
                                                // Siden vi nå skjuler hele blokken ved "Arc Energy",
                                                // trenger vi ikke lenger sjekke om vi skal vise 1.0 eller efficiency her.
                                                // Vi viser bare efficiency (f.eks. 0.8).
                                                Text(String(format: "%.1f", efficiency))
                                                    .font(RetroTheme.font(size: 20, weight: .bold))
                                                    .foregroundColor(RetroTheme.primary)
                                                    .padding(8)
                                                
                                                Text("ISO 17671")
                                                    .font(RetroTheme.font(size: 10))
                                                    .foregroundColor(RetroTheme.dim)
                                            }
                                            
                                            Text("×")
                                                .font(RetroTheme.font(size: 20))
                                                .foregroundColor(RetroTheme.dim)
                                        }
                                        VStack(spacing: 4) {
                                            HStack(alignment: .bottom, spacing: 6) {
                                                // MERK: Du kan sette width: 100 her hvis du vil ha fast bredde, ellers nil for full bredde
                                                SelectableInput(label: "Voltage (V)", value: voltageStr.toDouble, isActive: focusedField == .voltage, isAnyFocused: focusedField != nil, precision: 1, width: 80) { focusedField = .voltage }
                                                Text("×").foregroundColor(RetroTheme.dim)
                                                SelectableInput(label: "Current (A)", value: amperageStr.toDouble, isActive: focusedField == .amperage, isAnyFocused: focusedField != nil, precision: 0, width: 80) { focusedField = .amperage }
                                            }
                                            Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                            HStack(alignment: .top, spacing: 4) {
                                                SelectableInput(label: "Length (mm)", value: lengthStr.toDouble, isActive: focusedField == .length, isAnyFocused: focusedField != nil, precision: 0, width: 80) { focusedField = .length }
                                                Text("/").font(RetroTheme.font(size: 16)).foregroundColor(RetroTheme.dim).padding(.top, 10)
                                                SelectableInput(label: "time (s)", value: timeStr.toDouble, isActive: focusedField == .time, isAnyFocused: focusedField != nil, precision: 0, width: 80) { focusedField = .time }
                                                Text("×").foregroundColor(RetroTheme.dim).padding(.top, 10)
                                                HStack(alignment: .top, spacing: 0) { Text("10").font(RetroTheme.font(size: 16, weight: .bold)); Text("3").font(RetroTheme.font(size: 10, weight: .bold)).baselineOffset(8) }.foregroundColor(RetroTheme.dim).padding(.top, 8)
                                            }
                                            Text("Speed: \(String(format: "%.0f", calculatedSpeed)) mm/min").font(RetroTheme.font(size: 9)).foregroundColor(RetroTheme.dim).padding(.trailing, 40)
                                        }
                                    }
                                }.padding()
                            }
                        }
                        .padding(.horizontal).frame(height: 180).padding(.top, 25)
                        .contentShape(Rectangle())
                        .onTapGesture { if focusedField != nil { withAnimation { focusedField = nil } } }
                        .zIndex(5)
                        
                        // KNAPPER
                        Group {
                            HStack(spacing: 15) {
                                Button(action: {
                                    if activeJobID != nil {
                                        // 1. Hent det faktiske navnet fra den aktive jobben
                                        if let activeJob = jobHistory.first(where: { $0.id == activeJobID }) {
                                            tempJobName = activeJob.name
                                        } else {
                                            // Fallback: Hvis vi mot formodning ikke finner jobben, generer dato-navn
                                            tempJobName = currentJobName.isEmpty ? "Job \(Date().formatted(.dateTime.day().month().hour().minute()))" : currentJobName
                                        }
                                        
                                        withAnimation {
                                            isNamingJob = true
                                            isJobNameFocused = true
                                        }
                                    } else {
                                        startNewSession()
                                    } }) { VStack(spacing: 2) { Text("FINISH").font(RetroTheme.font(size: 12, weight: .bold)); Text("NEW JOB").font(RetroTheme.font(size: 8)) }.foregroundColor(RetroTheme.primary).frame(width: 80, height: 50).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1)) }
                                    .disabled(focusedField != nil || isTimerRunning ||
                                              passCounter == 1) // Sperrer ved åpent hjul eller aktiv timer
                                    .opacity(focusedField != nil || isTimerRunning ||
                                             passCounter == 1 ? 0.5 : 1.0)
                                Button(action: logPass) { HStack { HStack(spacing: 4) { Text("LOG PASS").lineLimit(1).minimumScaleFactor(0.8).layoutPriority(0); Text("#\(passCounter)").layoutPriority(1) }.font(RetroTheme.font(size: 20, weight: .heavy)); Spacer(); Image(systemName: "arrow.right.to.line") }.padding().foregroundColor(.black).background(heatInput > 0 ? RetroTheme.primary : RetroTheme.dim) }.disabled(heatInput == 0 || isNamingJob || isTimerRunning || focusedField != nil)
                                    .opacity(isTimerRunning || focusedField != nil ? 0.5 : 1.0)
                                // DATA+ knappen (Nå uten if-sjekk)
                                Button(action: { showExtendedDrawer = true }) {
                                    VStack(spacing: 2) {
                                        Text("PASS")
                                            .font(RetroTheme.font(size: 8))
                                        Image(systemName: "pencil.and.list.clipboard")
                                            .font(RetroTheme.font(size: 16, weight: .bold))
                                        Text("DATA")
                                            .font(RetroTheme.font(size: 8))
                                    }
                                    .foregroundColor(RetroTheme.primary)
                                    .frame(width: 50, height: 50)
                                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                }
                            }.padding(.horizontal).padding(.top, 25)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    if jobHistory.isEmpty { Brukermanual(isDetailed: false).frame(maxWidth: .infinity, alignment: .leading) }
                                    else { Text("> JOB HISTORY").font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary).padding(.top, 10); LazyVStack(spacing: 12) { ForEach(jobHistory) { job in NavigationLink(destination: JobDetailView(job: job)) { RetroJobRow(job: job, isActive: job.id == activeJobID) }.buttonStyle(PlainButtonStyle()) } } }
                                }.padding(.horizontal).padding(.bottom, focusedField != nil ? 320 : 20).animation(.easeOut(duration: 0.3), value: focusedField != nil)
                            }
                        }.zIndex(5)
                        
                    }.frame(height: geometry.size.height)
                }
                .offset(x: showSettings ? 300 : 0).opacity(showSettings ? 0 : 1).zIndex(2)
                
                // SETTINGS VIEW
                if showSettings {
                    SettingsView(
                        showSettings: $showSettings,
                        useDefaults: $useProcessDefaults
                    )
                    .transition(.move(edge: .leading)).zIndex(3)
                }
                
                // DATA+ DRAWER
                RetroModalDrawer(
                    isPresented: $showExtendedDrawer,
                    title: "DATA +",
                    fromTop: true,
                    showHeader: false, // Skjuler header og lukkeknapp
                    fixedHeight: geometry.size.height * 0.45 // Setter høyden til xx% av skjermen
                ) {
                    ScrollView { // Legger innholdet i ScrollView for sikkerhets skyld
                        ExtendedInputView(
                            process: Binding(get: { currentProcess }, set: { selectProcess($0) }),
                            diameter: $extDiameter,
                            polarity: $extPolarity,
                            wireFeedSpeed: $extWireFeed,
                            isArcEnergy: $extIsArcEnergy,
                            actualInterpass: $extActualInterpass,
                            gasType: $extGasType,
                            passType: $extPassType,
                            gasFlow: $extGasFlow,
                            transferMode: $extTransferMode,
                            fillerMaterial: $extFillerMaterial,
                            calculatedTravelSpeed: calculatedSpeed,
                            focusedField: $focusedField,
                            visibleFields: visibleFields
                        )
                    }
                }.zIndex(200)
                
                // UNIFIED DRAWER
                if let target = focusedField {
                    VStack { Spacer(); UnifiedInputDrawer(target: target, value: binding(for: target), range: range(for: target), step: step(for: target), isRecording: $isTimerRunning, onReset: resetStopwatch, onToggle: toggleStopwatch, onSync: { newValue in timerAccumulatedTime = newValue }).padding(.bottom, 50) }.id("DrawerContainer").transition(.move(edge: .bottom)).zIndex(300)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom).navigationBarBackButtonHidden(true).onAppear { restoreActiveJob() }.crtScreen()
        .onReceive(uiUpdateTimer) { _ in if isTimerRunning { let total = timerAccumulatedTime + (Date().timeIntervalSince1970 - timerStartTimestamp); timeStr = total >= 999 ? "999" : String(format: "%.0f", total) } }
        .onChange(of: enableExtendedData) { _, newValue in if !newValue { withAnimation { extIsArcEnergy = false } } }
        // Lukk hjulet automatisk hvis Data+ skuffen lukkes
        .onChange(of: showExtendedDrawer) { _, isOpen in
            if !isOpen {
                withAnimation {
                    focusedField = nil
                }
            }
        }
    }
    
    
    // HELPERS
    func toggleStopwatch() { if isTimerRunning { timerAccumulatedTime += (Date().timeIntervalSince1970 - timerStartTimestamp); isTimerRunning = false; Haptics.play(.medium) } else { timerStartTimestamp = Date().timeIntervalSince1970; isTimerRunning = true; Haptics.play(.heavy) } }
    func resetStopwatch() { isTimerRunning = false; timerAccumulatedTime = 0; timerStartTimestamp = 0; timeStr = "0"; Haptics.play(.medium) }
    
    func logPass() {
            if isTimerRunning {
                timerAccumulatedTime += (Date().timeIntervalSince1970 - timerStartTimestamp)
                timeStr = String(format: "%.0f", timerAccumulatedTime)
                isTimerRunning = false
            }
            
            let job: WeldGroup
            if let id = activeJobID, let existingJob = jobHistory.first(where: { $0.id == id }) {
                job = existingJob
            } else {
                job = WeldGroup(name: currentJobName.isEmpty ? "Job \(Date().formatted(.dateTime.day().month().hour().minute()))" : currentJobName)
                modelContext.insert(job)
                activeJobID = job.id
            }
            
            let calculatedSpeedToSave = calculatedSpeed > 0 ? calculatedSpeed : nil
            
            // HER var feilen: Vi sjekker nå om verdien > 0 eller ikke tom, i stedet for å stole på "enableExtendedData"
            let newPass = SavedCalculation(
                name: "Pass #\(passCounter)",
                voltage: voltageStr.toDouble,
                amperage: amperageStr.toDouble,
                travelTime: timeStr.toDouble,
                weldLength: lengthStr.toDouble,
                heatInput: heatInput,
                processName: selectedProcessName,
                kFactorUsed: extIsArcEnergy ? 1.0 : efficiency,
                
                // Lagrer utvidet data uavhengig av innstillingen "enableExtendedData"
                fillerDiameter: extDiameter > 0 ? extDiameter : nil,
                polarity: extPolarity,
                wireFeedSpeed: extWireFeed > 0 ? extWireFeed : nil,
                isArcEnergy: extIsArcEnergy,
                actualInterpass: extActualInterpass > 0 ? extActualInterpass : nil,
                gasType: !extGasType.isEmpty ? extGasType : nil,
                passType: extPassType,
                gasFlow: extGasFlow > 0 ? extGasFlow : nil,
                transferMode: extTransferMode,
                fillerMaterial: !extFillerMaterial.isEmpty ? extFillerMaterial : nil,
                savedTravelSpeed: calculatedSpeedToSave
            )
            
            newPass.group = job
            passCounter += 1
            job.date = Date() // Oppdater dato for sist endret
            
            try? modelContext.save()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            resetStopwatch()
        }
    
    // BINDINGS
    func binding(for field: InputTarget) -> Binding<Double> {
        switch field {
        case .voltage: return Binding(get: { voltageStr.toDouble }, set: { voltageStr = String(format: "%.1f", $0) })
        case .amperage: return Binding(get: { amperageStr.toDouble }, set: { amperageStr = String(format: "%.0f", $0) })
        case .time: return Binding(get: { timeStr.toDouble }, set: { timeStr = String(format: "%.0f", $0) })
        case .length: return Binding(get: { lengthStr.toDouble }, set: { lengthStr = String(format: "%.0f", $0) })
        case .diameter: return $extDiameter
        case .wfs: return $extWireFeed
        case .interpass: return $extActualInterpass
        case .gasFlow: return $extGasFlow
        }
    }
    
    func range(for field: InputTarget) -> ClosedRange<Double> {
        switch field {
        case .voltage: return 0...100; case .amperage: return 0...1000; case .time: return 0...3600; case .length: return 0...10000; case .diameter: return 0...6.0; case .wfs: return 0...30.0; case .interpass: return 0...500.0; case .gasFlow: return 0...50.0
        }
    }
    
    func step(for field: InputTarget) -> Double {
        switch field { case .voltage: return 0.1; case .diameter: return 0.1; case .wfs: return 0.1; default: return 1.0 }
    }
    
    func selectProcess(_ p: WeldingProcess) {
            selectedProcessName = p.name
            efficiency = p.kFactor
            voltageStr = p.defaultVoltage
            amperageStr = p.defaultAmperage
            
            // Hvis vi velger den rene "Arc"-prosessen, MÅ Arc Energy være på.
            if p.code == "Arc" {
                extIsArcEnergy = true
            }
            // Vi fjerner "else"-blokken her.
            // Da beholder "extIsArcEnergy" sin nåværende verdi (på eller av)
            // selv om du bytter mellom MIG, MAG, TIG etc.
            
            Haptics.selection()
        }
    func restoreActiveJob() { if let id = activeJobID, let j = jobHistory.first(where: { $0.id == id }) { currentJobName = j.name; passCounter = j.passes.count + 1 } else { activeJobID = nil; passCounter = 1 } }
    func startNewSession() { activeJobID = nil; passCounter = 1; currentJobName = ""; extDiameter = 0.0; extPolarity = "DC+"; extWireFeed = 0.0; extIsArcEnergy = false; extActualInterpass = 0.0; extPassType = "Fill"; extGasFlow = 0.0; Haptics.play(.medium) }
    func finalizeAndSaveJob() {
            // 1. Finn aktiv jobb og oppdater navnet
            if let id = activeJobID, let existingJob = jobHistory.first(where: { $0.id == id }) {
                // Hvis brukeren har skrevet et navn, bruk det.
                if !tempJobName.isEmpty {
                    existingJob.name = tempJobName
                }
            }
            
            // 2. Lagre endringen til databasen
            try? modelContext.save()
            
            // 3. Lukk dialogen og start ny sesjon
            withAnimation {
                isNamingJob = false
            }
            startNewSession()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
}

// --- 3. UNIFIED DRAWER (Uendret) ---
struct UnifiedInputDrawer: View {
    let target: HeatInputView.InputTarget
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    @Binding var isRecording: Bool
    var onReset: () -> Void
    var onToggle: () -> Void
    var onSync: (Double) -> Void
    @State private var pulseAmount: CGFloat = 1.0; @State private var dragOffset: CGFloat = 0; @State private var lastDragValue: CGFloat = 0; @State private var showManualInput: Bool = false
    private let visibleTicks = 6
    private func calculateOpacity(yPos: CGFloat, height: CGFloat) -> Double { let dist = abs((height/2) - yPos); return dist > (height/2-10) ? 0 : 1 - Double(dist/(height/2-10)) }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.black).overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.dim, lineWidth: 1)).shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 15)
            if target == .time && !showManualInput {
                VStack(spacing: 20) {
                    Text(isRecording ? "RECORDING..." : "TIMER READY").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(isRecording ? .red : RetroTheme.dim).padding(.top, 10)
                    Button(action: onToggle) {
                        ZStack {
                            Circle().fill(Color.red.opacity(isRecording ? 0.2 : 0.0)).frame(width: 150, height: 150).scaleEffect(pulseAmount + 0.1).blur(radius: 15)
                            Circle().fill(LinearGradient(colors: [isRecording ? .red : Color(white: 0.15), .black], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 130, height: 130).overlay(Circle().stroke(isRecording ? Color.red : RetroTheme.dim, lineWidth: 4))
                            VStack(spacing: 2) { if isRecording { Text(String(format: "%02d", Int(min(value, 999)))).font(.system(size: 50, weight: .black, design: .monospaced)).foregroundColor(.white).contentTransition(.numericText(value: value)); Text("SEC").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.8)) } else { Image(systemName: "play.fill").font(.title).foregroundColor(RetroTheme.primary); Text("START").font(RetroTheme.font(size: 14, weight: .black)).foregroundColor(RetroTheme.primary) } }
                        }.scaleEffect(isRecording ? pulseAmount : 1.0)
                    }.buttonStyle(PlainButtonStyle())
                    Button(action: onReset) { HStack { Image(systemName: "arrow.counterclockwise"); Text("RESET") }.font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(RetroTheme.dim).padding(.vertical, 8).padding(.horizontal, 16).overlay(RoundedRectangle(cornerRadius: 6).stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1)) }.opacity(value > 0 && !isRecording ? 1.0 : 0.2).disabled(isRecording || value == 0)
                }.transition(.opacity).onChange(of: isRecording) { _, newValue in if newValue { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulseAmount = 1.06 } } else { withAnimation(.spring()) { pulseAmount = 1.0 } } }
            } else {
                GeometryReader { geo in let midY = geo.size.height / 2; ZStack { ForEach(-visibleTicks...visibleTicks, id: \.self) { i in let index = round(value / step) + Double(i); let yPos = midY + (CGFloat(index) - CGFloat(value / step)) * 20; HStack { Rectangle().fill(RetroTheme.primary).frame(width: Int(index) % 5 == 0 ? 80 : 40, height: 2) }.position(x: geo.size.width / 2, y: yPos).opacity(calculateOpacity(yPos: yPos, height: geo.size.height)) } } }.clipShape(RoundedRectangle(cornerRadius: 12)).contentShape(Rectangle()).gesture(DragGesture().onChanged { g in
                    let delta = g.translation.height - lastDragValue
                    dragOffset += delta
                    let steps = Int(dragOffset / 12)
                    
                    if steps != 0 {
                        // Beregn ny verdi basert på dra-hastighet
                        let speedMultiplier = abs(delta) > 10 ? 5.0 : 1.0
                        let newValue = value - Double(steps) * step * speedMultiplier
                        
                        // 1. BESTEM ØVRE GRENSE
                        // Hvis det er Tid eller Lengde: Maks 999.
                        // Ellers: Bruk maksverdien fra 'range' (f.eks. 100V eller 1000A)
                        let upperLimit: Double = (target == .time || target == .length) ? 999 : range.upperBound
                        let lowerLimit: Double = range.lowerBound // Som regel 0
                        
                        // 2. LOGIKK FOR ØVRE GRENSE (Spenning, Strøm, Tid, Lengde)
                        if newValue > upperLimit {
                            if value < upperLimit {
                                // Vi treffer taket akkurat nå -> "Heavy" dunk
                                value = upperLimit
                                Haptics.play(.heavy)
                            } else {
                                // Vi er allerede i taket og prøver å dra mer -> "Warning" nekt
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            }
                        }
                        // 3. LOGIKK FOR NEDRE GRENSE (0)
                        else if newValue < lowerLimit {
                            if value > lowerLimit {
                                // Vi treffer bunnen akkurat nå
                                value = lowerLimit
                                Haptics.play(.heavy)
                            } else {
                                // (Valgfritt) Nekt ved bunnen også
                                 UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            }
                        }
                        // 4. VANLIG JUSTERING (Innenfor grensene)
                        else {
                            value = (newValue * 100).rounded() / 100
                            Haptics.selection() // Vanlig klikk
                        }
                        
                        // Nullstill offset for neste "hakk"
                        dragOffset -= Double(steps) * 12
                    }
                    
                    lastDragValue = g.translation.height
                }.onEnded { _ in
                    lastDragValue = 0
                    dragOffset = 0
                }).overlay(Rectangle().fill(RetroTheme.primary.opacity(0.1)).frame(height: 24).overlay(Rectangle().stroke(RetroTheme.primary.opacity(0.5), lineWidth: 1)).allowsHitTesting(false))
            }
            if target == .time { VStack { Spacer(); HStack { Spacer(); Button(action: { if showManualInput { onSync(value) }; withAnimation(.spring()) { showManualInput.toggle() } }) { Image(systemName: showManualInput ? "timer" : "slider.horizontal.3").font(.system(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary).padding(12).background(Color.black.opacity(0.9)).clipShape(Circle()).overlay(Circle().stroke(RetroTheme.dim, lineWidth: 1)).shadow(radius: 4) }.padding(15).disabled(isRecording).opacity(isRecording ? 0.3 : 1.0) } } }
        }.frame(width: 320, height: 280)
    }
}

// --- 4. RETRO JOB ROW (Uendret) ---
struct RetroJobRow: View {
    let job: WeldGroup; let isActive: Bool; var body: some View { HStack { VStack(alignment: .leading, spacing: 4) { HStack(spacing: 8) { Text(job.name).font(RetroTheme.font(size: 16, weight: .bold)).foregroundColor(isActive ? Color.green : RetroTheme.primary); if isActive { Text("ACTIVE JOB").font(RetroTheme.font(size: 8, weight: .heavy)).foregroundColor(.black).padding(.horizontal, 4).padding(.vertical, 2).background(Color.green) } }; Text("\(job.passes.count) passes").font(RetroTheme.font(size: 10)).foregroundColor(isActive ? Color.green.opacity(0.8) : RetroTheme.dim) }; Spacer(); Text(job.date, format: .dateTime.day().month()).font(RetroTheme.font(size: 12)).foregroundColor(isActive ? Color.green.opacity(0.8) : RetroTheme.dim); if isActive { Image(systemName: "record.circle").font(.system(size: 10)).foregroundColor(.green).blinkEffect() } }.padding(12).background(isActive ? Color.green.opacity(0.15) : Color.black.opacity(0.3)).overlay(Rectangle().stroke(isActive ? Color.green : RetroTheme.dim.opacity(0.5), lineWidth: isActive ? 2 : 1)).shadow(color: isActive ? Color.green.opacity(0.4) : .clear, radius: 8, x: 0, y: 0) }
}

// --- 5. EXTENDED INPUT VIEW (ARC ENERGY KNAPP & CLEAN LOOK) ---
struct ExtendedInputView: View {
    @Binding var process: WeldingProcess
    @Binding var diameter: Double
    @Binding var polarity: String
    @Binding var wireFeedSpeed: Double
    @Binding var isArcEnergy: Bool
    @Binding var actualInterpass: Double
    @Binding var gasType: String
    @Binding var passType: String
    @Binding var gasFlow: Double
    @Binding var transferMode: String
    @Binding var fillerMaterial: String
    let calculatedTravelSpeed: Double // (Brukes ikke visuelt lenger, men må være her for init)
    @Binding var focusedField: HeatInputView.InputTarget?
    
    // VISIBILITY SET
    let visibleFields: Set<WeldField>
    
    let passTypes = ["Root", "Fill", "Cap", "-"]
    let transferModes = ["Short", "Spray", "Pulse", "Globular", "CMT", "-"]
    
    enum TextFieldId {
        case filler
        case gas
    }
    @FocusState private var focusedText: TextFieldId?
    
    var body: some View {
        VStack(spacing: 15) {
            
            // Topp: Prosessnavn + ARC ENERGY Knapp
            HStack(alignment: .center) {
                // Venstre: Prosessnavn
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROSESS")
                        .font(RetroTheme.font(size: 10))
                        .foregroundColor(RetroTheme.dim)
                    Text(process.name)
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Høyre: ARC ENERGY Knapp
                // Grønn = Aktiv (isArcEnergy = true) -> K=1.0
                // Tom = Inaktiv (isArcEnergy = false) -> K=Prosessverdi
                Button(action: {
                    Haptics.selection()
                    withAnimation {
                        isArcEnergy.toggle()
                    }
                }) {
                    Text("ARC ENERGY")
                        .font(RetroTheme.font(size: 12, weight: .bold))
                        .foregroundColor(isArcEnergy ? .black : RetroTheme.primary) // Sort tekst på grønn bakgrunn
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(isArcEnergy ? RetroTheme.primary : Color.clear) // Grønn bakgrunn når aktiv
                        .overlay(
                            Rectangle().stroke(RetroTheme.primary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().background(RetroTheme.dim)
            
            // GRID LAYOUT (2 Kolonner)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                
                // 1. Pass Type
                if visibleFields.contains(.passType) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TYPE").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                        HStack(spacing: 0) {
                            ForEach(passTypes, id: \.self) { type in
                                Button(action: { passType = type }) { Text(type.prefix(1)).font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(passType == type ? .black : RetroTheme.primary).frame(height: 44).frame(maxWidth: .infinity).background(passType == type ? RetroTheme.primary : Color.black) }.buttonStyle(.plain)
                                if type != passTypes.last { Rectangle().fill(RetroTheme.primary).frame(width: 1, height: 44) }
                            }
                        }.overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }
                
                // 2. Transfer Mode
                if visibleFields.contains(.transfer) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRANSFER")
                            .font(RetroTheme.font(size: 10))
                            .foregroundColor(RetroTheme.dim)
                        
                        RetroDropdown2( // <--- Endret til RetroDropdown2
                            title: "TRANSFER",
                            selection: transferMode,
                            options: transferModes,
                            onSelect: { transferMode = $0 },
                            itemText: { $0 }
                            // itemDetail trenger vi ikke sende med her
                        )
                    }
                    .zIndex(90) // Denne må fortsatt være her!
                }
                
                // 3. Filler Metal
                if visibleFields.contains(.filler) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FILLER METAL").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                        TextField("Ex: 316L", text: $fillerMaterial, onEditingChanged: { editing in
                            if editing { withAnimation { focusedField = nil } }
                        })
                        .focused($focusedText, equals: .filler)
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(.horizontal, 8)
                        .frame(height: 44)
                        .background(Color.black)
                        .overlay(Rectangle().stroke(focusedText == .filler ? RetroTheme.primary : RetroTheme.dim, lineWidth: focusedText == .filler ? 2 : 1))
                    }
                }
                
                // 4. Diameter
                if visibleFields.contains(.diameter) {
                    SelectableInput(label: "DIAMETER (mm)", value: diameter, isActive: focusedField == .diameter, isAnyFocused: focusedField != nil, precision: 1, width: nil) {
                        focusedField = .diameter
                    }
                }
                
                // 5. Polarity
                if visibleFields.contains(.polarity) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("POLARITET").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                        HStack(spacing: 0) {
                            ForEach(["DC+", "DC-", "AC"], id: \.self) { pol in
                                Button(action: { polarity = pol }) { Text(pol).font(RetroTheme.font(size: 9, weight: .bold)).foregroundColor(polarity == pol ? .black : RetroTheme.primary).frame(height: 44).frame(maxWidth: .infinity).background(polarity == pol ? RetroTheme.primary : Color.black) }.buttonStyle(.plain)
                                if pol != "AC" { Rectangle().fill(RetroTheme.primary).frame(width: 1, height: 44) }
                            }
                        }.overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }
                
                // 6. WFS
                if visibleFields.contains(.wfs) {
                    SelectableInput(label: "WFS (m/min)", value: wireFeedSpeed, isActive: focusedField == .wfs, isAnyFocused: focusedField != nil, precision: 1, width: nil) {
                        focusedField = .wfs
                    }
                }
                
                // 7. Gas Type
                if visibleFields.contains(.gas) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GAS TYPE").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                        TextField("Ex: Mison 18", text: $gasType, onEditingChanged: { editing in
                            if editing { withAnimation { focusedField = nil } }
                        })
                        .focused($focusedText, equals: .gas)
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(.horizontal, 8)
                        .frame(height: 44)
                        .background(Color.black)
                        .overlay(Rectangle().stroke(focusedText == .gas ? RetroTheme.primary : RetroTheme.dim, lineWidth: focusedText == .gas ? 2 : 1))
                    }
                }
                
                // 8. Gas Flow
                if visibleFields.contains(.flow) {
                    SelectableInput(label: "FLOW (l/min)", value: gasFlow, isActive: focusedField == .gasFlow, isAnyFocused: focusedField != nil, precision: 0, width: nil) {
                        focusedField = .gasFlow
                    }
                }
                
                // 9. Interpass
                if visibleFields.contains(.interpass) {
                    SelectableInput(label: "INTERPASS (°C)", value: actualInterpass, isActive: focusedField == .interpass, isAnyFocused: focusedField != nil, precision: 0, width: nil) {
                        focusedField = .interpass
                    }
                }
            }
        }
        .padding(.top, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            focusedText = nil
            if focusedField != nil {
                withAnimation { focusedField = nil }
                Haptics.selection()
            }
        }
    }
}
// --- 6. NY GJENBRUKBAR SELECTABLE INPUT STRUCT ---
struct SelectableInput: View {
    let label: String
    let value: Double
    let isActive: Bool
    let isAnyFocused: Bool
    let precision: Int
    var width: CGFloat? = nil
    let action: () -> Void
    
    var activeColor: Color {
        return (isActive || !isAnyFocused) ? RetroTheme.primary : RetroTheme.dim
    }
    
    var body: some View {
        Button(action: {
            // NY LINJE: Tving tastaturet ned før vi åpner hjulet
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            withAnimation(.spring(response: 0.3)) {
                action()
                Haptics.selection()
            }
        }) {
            VStack(spacing: 0) {
                Text(String(format: "%.\(precision)f", value))
                    .font(RetroTheme.font(size: 24, weight: .bold))
                    .foregroundColor(activeColor)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .overlay(
                        Rectangle()
                            .stroke(activeColor, lineWidth: isActive ? 2 : 1)
                    )
                
                Text(label)
                    .font(RetroTheme.font(size: 10, weight: isActive ? .bold : .regular))
                    .foregroundColor(activeColor)
                    .padding(4)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : nil)
    }
}
