//
//  HeatInputView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI
import SwiftData
import Combine

// --- 1. SVEISEPROSESS MODELL ---
struct WeldingProcess: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let awsCode: String
    let kFactor: Double
    let defaultVoltage: String
    let defaultAmperage: String
    
    static let allProcesses: [WeldingProcess] = [
        WeldingProcess(name: "Arc energy", code: "Arc", awsCode: "-", kFactor: 1.0, defaultVoltage: "0.0", defaultAmperage: "0"),
        WeldingProcess(name: "Submerged arc welding", code: "121", awsCode: "SAW", kFactor: 1.0, defaultVoltage: "30.0", defaultAmperage: "500"),
        WeldingProcess(name: "MMA / Covered electrode", code: "111", awsCode: "SMAW", kFactor: 0.8, defaultVoltage: "23.0", defaultAmperage: "120"),
        WeldingProcess(name: "MIG welding", code: "131", awsCode: "GMAW", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "200"),
        WeldingProcess(name: "MAG welding", code: "135", awsCode: "GMAW", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "200"),
        WeldingProcess(name: "FCAW No Gas", code: "114", awsCode: "FCAW-S", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "180"),
        WeldingProcess(name: "FCAW Active Gas", code: "136", awsCode: "FCAW-G", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "220"),
        WeldingProcess(name: "FCAW Inert Gas", code: "137", awsCode: "FCAW-G", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "220"),
        WeldingProcess(name: "MCAW Active Gas", code: "138", awsCode: "GMAW-C", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "240"),
        WeldingProcess(name: "MCAW Inert Gas", code: "139", awsCode: "GMAW-C", kFactor: 0.8, defaultVoltage: "25.0", defaultAmperage: "240"),
        WeldingProcess(name: "TIG welding", code: "141", awsCode: "GTAW", kFactor: 0.6, defaultVoltage: "14.0", defaultAmperage: "110"),
        WeldingProcess(name: "Plasma arc welding", code: "15", awsCode: "PAW", kFactor: 0.6, defaultVoltage: "25.0", defaultAmperage: "150")
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
    
    // NYTT: Lagt til interpass i enum
    enum InputTarget: String, Identifiable {
        case voltage, amperage, time, length
        case diameter, wfs
        case interpass // <--- NY
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
    @AppStorage("hidden_process_codes") private var hiddenProcessCodes: String = ""
    
    // STORAGE FOR NYE FELTER (Husker gass, men nullstiller interpass)
    @AppStorage("heat_gas_type") private var extGasType: String = ""
    @State private var extActualInterpass: Double = 0.0
    @State private var extPassType: String = "Fill" // Default
    
    @State private var currentJobName: String = ""
    
    // STOPWATCH STORAGE
    @AppStorage("stopwatch_is_running") private var isTimerRunning: Bool = false
    @AppStorage("stopwatch_start_timestamp") private var timerStartTimestamp: Double = 0.0
    @AppStorage("stopwatch_accumulated_time") private var timerAccumulatedTime: Double = 0.0
    
    // --- FELTER FOR EXTENDED DATA ---
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
        return WeldingProcess.allProcesses.filter { process in
            !hidden.contains(process.code)
        }
    }
    
    var currentProcess: WeldingProcess {
        WeldingProcess.allProcesses.first(where: { $0.name == selectedProcessName }) ?? WeldingProcess.allProcesses.first!
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
                // 1. BAKGRUNN (LAG 0)
                RetroTheme.background.ignoresSafeArea()
                
                // 2. KLIKK-FANGER (LAG 1)
                if focusedField != nil {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { focusedField = nil }
                        }
                        .zIndex(1)
                }
                
                ZStack {
                    VStack(spacing: 0) {
                        
                        // --- GRUPPE 1: TOPPEN (HEADER) ---
                        Group {
                            // Header
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
                            }
                            .padding()
                            
                            // Prosessvelger og resultat
                            VStack(spacing: 25) {
                                HStack(alignment: .top, spacing: 0) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("PROCESS").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                        RetroDropdown(title: "PROCESS", selection: currentProcess, options: availableProcesses, onSelect: { selectProcess($0) }, itemText: { $0.name }, itemDetail: { process in process.code == "Arc" ? "ISO/TR 18491" : "ISO 4063: \(process.code)"})
                                            .frame(maxWidth: .infinity)
                                    }
                                    Spacer(minLength: 20)
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text("CURRENT PASS (kJ/mm)").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                        Text(String(format: "%.2f", heatInput)).font(RetroTheme.font(size: 36, weight: .black)).foregroundColor(RetroTheme.primary).shadow(color: RetroTheme.primary.opacity(0.5), radius: 5)
                                        if activeJobID != nil { Text("• ACTIVE JOB").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(RetroTheme.primary).blinkEffect() }
                                    }.frame(minWidth: 160, alignment: .trailing)
                                }.padding(.horizontal)
                            }
                        }
                        .zIndex(10) // Ligger over input-boksen
                        
                        
                        // --- GRUPPE 2: INPUT BOKS ---
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
                                        if currentProcess.code != "Arc" {
                                            VStack(spacing: 0) {
                                                Text("k-factor").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                                Text(String(format: "%.1f", extIsArcEnergy ? 1.0 : efficiency))
                                                    .font(RetroTheme.font(size: 20, weight: .bold))
                                                    .foregroundColor(RetroTheme.primary)
                                                    .padding(8)
                                                Text(extIsArcEnergy ? "No k-factor" : "ISO 17671").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                            }
                                            Text("×").font(RetroTheme.font(size: 20)).foregroundColor(RetroTheme.dim)
                                        }
                                        
                                        VStack(spacing: 4) {
                                            HStack(alignment: .bottom, spacing: 6) {
                                                SelectableInput(label: "Voltage (V)", value: voltageStr.toDouble, target: .voltage, currentFocus: focusedField, precision: 1) { focusedField = .voltage }
                                                Text("×").foregroundColor(RetroTheme.dim)
                                                SelectableInput(label: "Current (A)", value: amperageStr.toDouble, target: .amperage, currentFocus: focusedField, precision: 0) { focusedField = .amperage }
                                            }
                                            Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                            HStack(alignment: .top, spacing: 4) {
                                                SelectableInput(label: "Length (mm)", value: lengthStr.toDouble, target: .length, currentFocus: focusedField, precision: 0) { focusedField = .length }
                                                Text("/").font(RetroTheme.font(size: 16)).foregroundColor(RetroTheme.dim).padding(.top, 10)
                                                SelectableInput(label: "time (s)", value: timeStr.toDouble, target: .time, currentFocus: focusedField, precision: 0) { focusedField = .time }
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
                        .onTapGesture {
                            if focusedField != nil {
                                withAnimation { focusedField = nil }
                            }
                        }
                        .zIndex(5)
                        
                        
                        // --- GRUPPE 3: BUNNEN ---
                        Group {
                            HStack(spacing: 15) {
                                // KNAPP 1: NEW JOB
                                Button(action: {
                                    if activeJobID != nil {
                                        tempJobName = currentJobName
                                        withAnimation {
                                            isNamingJob = true
                                            isJobNameFocused = true
                                        }
                                    } else {
                                        startNewSession()
                                    }
                                }) {
                                    VStack(spacing: 2) {
                                        Text("NEW JOB")
                                            .font(RetroTheme.font(size: 12, weight: .bold))
                                        Text(activeJobID != nil ? "FINISH" : "RESET")
                                            .font(RetroTheme.font(size: 8))
                                    }
                                    .foregroundColor(RetroTheme.primary)
                                    .frame(width: 80, height: 50)
                                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                }
                                
                                // KNAPP 2: LOG PASS
                                Button(action: logPass) {
                                    HStack {
                                        HStack(spacing: 4) {
                                            Text("LOG PASS")
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                                .layoutPriority(0)
                                            Text("#\(passCounter)")
                                                .layoutPriority(1)
                                        }
                                        .font(RetroTheme.font(size: 20, weight: .heavy))
                                        Spacer()
                                        Image(systemName: "arrow.right.to.line")
                                    }
                                    .padding()
                                    .foregroundColor(.black)
                                    .background(heatInput > 0 ? RetroTheme.primary : RetroTheme.dim)
                                }
                                .disabled(heatInput == 0 || isNamingJob)
                                
                                // KNAPP 3: DATA+
                                if enableExtendedData {
                                    Button(action: {
                                        showExtendedDrawer = true
                                    }) {
                                        VStack(spacing: 2) {
                                            Image(systemName: "pencil.and.list.clipboard")
                                                .font(RetroTheme.font(size: 16, weight: .bold))
                                            Text("DATA+")
                                                .font(RetroTheme.font(size: 8))
                                        }
                                        .foregroundColor(RetroTheme.primary)
                                        .frame(width: 60, height: 50)
                                        .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                    }
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }.padding(.horizontal).padding(.top, 25)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    if jobHistory.isEmpty {
                                        RetroGuideView(isDetailed: false).frame(maxWidth: .infinity, alignment: .leading)
                                    } else {
                                        Text("> JOB HISTORY").font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary).padding(.top, 10)
                                        LazyVStack(spacing: 12) {
                                            ForEach(jobHistory) { job in
                                                NavigationLink(destination: JobDetailView(job: job)) {
                                                    RetroJobRow(job: job, isActive: job.id == activeJobID)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, focusedField != nil ? 320 : 20)
                                .animation(.easeOut(duration: 0.3), value: focusedField != nil)
                            }
                        }
                        .zIndex(5)
                        
                    }.frame(height: geometry.size.height)
                }
                .offset(x: showSettings ? 300 : 0)
                .opacity(showSettings ? 0 : 1)
                .zIndex(2)
                
                // SETTINGS VIEW
                if showSettings {
                    SettingsView(showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(3)
                }

                // DATA+ DRAWER
                RetroModalDrawer(isPresented: $showExtendedDrawer, title: "DATA +", fromTop: true) {
                    ExtendedInputView(
                        process: Binding(get: { currentProcess }, set: { selectProcess($0) }),
                        diameter: $extDiameter,
                        polarity: $extPolarity,
                        wireFeedSpeed: $extWireFeed,
                        isArcEnergy: $extIsArcEnergy,
                        // NYE BINDINGS:
                        actualInterpass: $extActualInterpass,
                        gasType: $extGasType,
                        passType: $extPassType,
                        
                        calculatedTravelSpeed: calculatedSpeed,
                        focusedField: $focusedField
                    )
                }
                .zIndex(200)
                
                // UNIFIED DRAWER
                if let target = focusedField {
                    VStack {
                        Spacer()
                        UnifiedInputDrawer(target: target, value: binding(for: target), range: range(for: target), step: step(for: target), isRecording: $isTimerRunning, onReset: resetStopwatch, onToggle: toggleStopwatch, onSync: { newValue in timerAccumulatedTime = newValue }).padding(.bottom, 50)
                    }.id("DrawerContainer").transition(.move(edge: .bottom))
                    .zIndex(300)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .onAppear { restoreActiveJob() }
        .crtScreen()
        .onReceive(uiUpdateTimer) { _ in
            if isTimerRunning {
                let total = timerAccumulatedTime + (Date().timeIntervalSince1970 - timerStartTimestamp)
                if total >= 999 {
                    timeStr = "999"
                    isTimerRunning = false
                    Haptics.play(.heavy)
                } else {
                    timeStr = String(format: "%.0f", total)
                }
            }
        }
        .onChange(of: enableExtendedData) { _, newValue in
            if !newValue {
                withAnimation { extIsArcEnergy = false }
            }
        }
    }
    
    // --- HJELPEFUNKSJONER ---
    func toggleStopwatch() {
        if isTimerRunning { timerAccumulatedTime += (Date().timeIntervalSince1970 - timerStartTimestamp); isTimerRunning = false; Haptics.play(.medium) }
        else { timerStartTimestamp = Date().timeIntervalSince1970; isTimerRunning = true; Haptics.play(.heavy) }
    }
    func resetStopwatch() { isTimerRunning = false; timerAccumulatedTime = 0; timerStartTimestamp = 0; timeStr = "0"; Haptics.play(.medium) }
    
    func logPass() {
        if isTimerRunning { timerAccumulatedTime += (Date().timeIntervalSince1970 - timerStartTimestamp); timeStr = String(format: "%.0f", timerAccumulatedTime); isTimerRunning = false }
        
        let job: WeldGroup
        if let id = activeJobID, let existingJob = jobHistory.first(where: { $0.id == id }) { job = existingJob }
        else { job = WeldGroup(name: currentJobName.isEmpty ? "Job \(Date().formatted(.dateTime.day().month().hour().minute()))" : currentJobName); modelContext.insert(job); activeJobID = job.id }
        
        let newPass = SavedCalculation(
            name: "Pass #\(passCounter)",
            voltage: voltageStr.toDouble,
            amperage: amperageStr.toDouble,
            travelTime: timeStr.toDouble,
            weldLength: lengthStr.toDouble,
            heatInput: heatInput,
            processName: selectedProcessName,
            kFactorUsed: extIsArcEnergy ? 1.0 : efficiency,
            fillerDiameter: enableExtendedData ? extDiameter : nil,
            polarity: enableExtendedData ? extPolarity : nil,
            wireFeedSpeed: enableExtendedData ? extWireFeed : nil,
            isArcEnergy: enableExtendedData ? extIsArcEnergy : false,
            // NYE FELTER
            actualInterpass: enableExtendedData ? extActualInterpass : nil,
            gasType: enableExtendedData ? extGasType : nil,
            passType: enableExtendedData ? extPassType : nil
        )
        
        newPass.group = job; passCounter += 1; job.date = Date(); try? modelContext.save(); UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        resetStopwatch()
    }
    
    @ViewBuilder func SelectableInput(label: String, value: Double, target: InputTarget, currentFocus: InputTarget?, precision: Int, action: @escaping () -> Void) -> some View {
        let isSelected = (currentFocus == target)
        Button(action: { withAnimation(.spring(response: 0.3)) { action(); Haptics.selection() } }) {
            VStack(spacing: 0) {
                Text(String(format: "%.\(precision)f", value)).font(RetroTheme.font(size: 24, weight: .bold)).foregroundColor(currentFocus != nil && !isSelected ? RetroTheme.dim : RetroTheme.primary).padding(.vertical, 4).frame(minWidth: 80).background(Color.black).overlay(Rectangle().stroke(currentFocus != nil && !isSelected ? RetroTheme.dim : RetroTheme.primary, lineWidth: isSelected ? 2 : 1))
                Text(label).font(RetroTheme.font(size: 10, weight: isSelected ? .bold : .regular)).foregroundColor(isSelected ? RetroTheme.primary : RetroTheme.dim).padding(4).frame(minWidth: 80)
            }
        }.buttonStyle(PlainButtonStyle())
    }
    
    func binding(for field: InputTarget) -> Binding<Double> {
        switch field {
        case .voltage: return Binding(get: { voltageStr.toDouble }, set: { voltageStr = String(format: "%.1f", $0) })
        case .amperage: return Binding(get: { amperageStr.toDouble }, set: { amperageStr = String(format: "%.0f", $0) })
        case .time: return Binding(get: { timeStr.toDouble }, set: { timeStr = String(format: "%.0f", $0) })
        case .length: return Binding(get: { lengthStr.toDouble }, set: { lengthStr = String(format: "%.0f", $0) })
        case .diameter: return $extDiameter
        case .wfs: return $extWireFeed
        case .interpass: return $extActualInterpass // NY
        }
    }
    
    func range(for field: InputTarget) -> ClosedRange<Double> {
        switch field {
        case .voltage: return 0...100
        case .amperage: return 0...1000
        case .time: return 0...3600
        case .length: return 0...10000
        case .diameter: return 0...6.0
        case .wfs: return 0...30.0
        case .interpass: return 0...500.0 // NY
        }
    }
    
    func step(for field: InputTarget) -> Double {
        switch field {
        case .voltage: return 0.1
        case .diameter: return 0.1
        case .wfs: return 0.1
        default: return 1.0 // Interpass, Ampere, Tid, Lengde = 1.0
        }
    }
    
    func selectProcess(_ p: WeldingProcess) {
        selectedProcessName = p.name;
        efficiency = p.kFactor;
        voltageStr = p.defaultVoltage;
        amperageStr = p.defaultAmperage;
        
        if p.code == "Arc" { extIsArcEnergy = true } else { extIsArcEnergy = false }
        
        Haptics.selection()
    }
    func restoreActiveJob() { if let id = activeJobID, let j = jobHistory.first(where: { $0.id == id }) { currentJobName = j.name; passCounter = j.passes.count + 1 } else { activeJobID = nil; passCounter = 1 } }
    
    func startNewSession() {
        activeJobID = nil; passCounter = 1; currentJobName = "";
        extDiameter = 0.0; extPolarity = "DC+"; extWireFeed = 0.0; extIsArcEnergy = false;
        // Resetter interpass og type, men beholder gass
        extActualInterpass = 0.0
        extPassType = "Fill"
        
        Haptics.play(.medium)
    }
    func finalizeAndSaveJob() { withAnimation { isNamingJob = false }; startNewSession(); UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// --- 3. UNIFIED DRAWER ---
struct UnifiedInputDrawer: View {
    let target: HeatInputView.InputTarget
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    @Binding var isRecording: Bool
    var onReset: () -> Void
    var onToggle: () -> Void
    var onSync: (Double) -> Void
    
    @State private var pulseAmount: CGFloat = 1.0
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    @State private var showManualInput: Bool = false
    
    private let visibleTicks = 6
    private func calculateOpacity(yPos: CGFloat, height: CGFloat) -> Double {
        let dist = abs((height/2) - yPos)
        return dist > (height/2-10) ? 0 : 1 - Double(dist/(height/2-10))
    }
    
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
                            VStack(spacing: 2) {
                                if isRecording { Text(String(format: "%02d", Int(min(value, 999)))).font(.system(size: 50, weight: .black, design: .monospaced)).foregroundColor(.white).contentTransition(.numericText(value: value)); Text("SEC").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.8))
                                } else { Image(systemName: "play.fill").font(.title).foregroundColor(RetroTheme.primary); Text("START").font(RetroTheme.font(size: 14, weight: .black)).foregroundColor(RetroTheme.primary) }
                            }
                        }.scaleEffect(isRecording ? pulseAmount : 1.0)
                    }.buttonStyle(PlainButtonStyle())
                    Button(action: onReset) { HStack { Image(systemName: "arrow.counterclockwise"); Text("RESET") }.font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(RetroTheme.dim).padding(.vertical, 8).padding(.horizontal, 16).overlay(RoundedRectangle(cornerRadius: 6).stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1)) }.opacity(value > 0 && !isRecording ? 1.0 : 0.2).disabled(isRecording || value == 0)
                }.transition(.opacity).onChange(of: isRecording) { _, newValue in if newValue { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulseAmount = 1.06 } } else { withAnimation(.spring()) { pulseAmount = 1.0 } } }
            } else {
                GeometryReader { geo in
                    let midY = geo.size.height / 2
                    ZStack {
                        ForEach(-visibleTicks...visibleTicks, id: \.self) { i in
                            let index = round(value / step) + Double(i)
                            let yPos = midY + (CGFloat(index) - CGFloat(value / step)) * 20
                            HStack { Rectangle().fill(RetroTheme.primary).frame(width: Int(index) % 5 == 0 ? 80 : 40, height: 2) }.position(x: geo.size.width / 2, y: yPos).opacity(calculateOpacity(yPos: yPos, height: geo.size.height))
                        }
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 12)).contentShape(Rectangle()).gesture(DragGesture().onChanged { g in
                    let delta = g.translation.height - lastDragValue; dragOffset += delta; let steps = Int(dragOffset / 12)
                    if steps != 0 {
                        let newValue = value - Double(steps) * step * (abs(delta) > 10 ? 5.0 : 1.0)
                        if target == .time && newValue > 999 { if value < 999 { value = 999; Haptics.play(.heavy) } else { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
                        } else if range.contains(newValue) { value = (newValue * 100).rounded() / 100; Haptics.selection()
                        } else { if value > range.lowerBound { value = range.lowerBound; Haptics.play(.heavy) } }
                        dragOffset -= Double(steps) * 12
                    }
                    lastDragValue = g.translation.height
                }.onEnded { _ in lastDragValue = 0; dragOffset = 0 }).overlay(Rectangle().fill(RetroTheme.primary.opacity(0.1)).frame(height: 24).overlay(Rectangle().stroke(RetroTheme.primary.opacity(0.5), lineWidth: 1)).allowsHitTesting(false))
            }
            if target == .time { VStack { Spacer(); HStack { Spacer(); Button(action: { if showManualInput { onSync(value) }; withAnimation(.spring()) { showManualInput.toggle() } }) { Image(systemName: showManualInput ? "timer" : "slider.horizontal.3").font(.system(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary).padding(12).background(Color.black.opacity(0.9)).clipShape(Circle()).overlay(Circle().stroke(RetroTheme.dim, lineWidth: 1)).shadow(radius: 4) }.padding(15).disabled(isRecording).opacity(isRecording ? 0.3 : 1.0) } } }
        }.frame(width: 320, height: 280)
    }
}

// --- 4. RETRO JOB ROW ---
struct RetroJobRow: View {
    let job: WeldGroup
    let isActive: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) { Text(job.name).font(RetroTheme.font(size: 16, weight: .bold)).foregroundColor(isActive ? Color.green : RetroTheme.primary); if isActive { Text("ACTIVE JOB").font(RetroTheme.font(size: 8, weight: .heavy)).foregroundColor(.black).padding(.horizontal, 4).padding(.vertical, 2).background(Color.green) } }
                Text("\(job.passes.count) passes").font(RetroTheme.font(size: 10)).foregroundColor(isActive ? Color.green.opacity(0.8) : RetroTheme.dim)
            }
            Spacer()
            Text(job.date, format: .dateTime.day().month()).font(RetroTheme.font(size: 12)).foregroundColor(isActive ? Color.green.opacity(0.8) : RetroTheme.dim)
            if isActive { Image(systemName: "record.circle").font(.system(size: 10)).foregroundColor(.green).blinkEffect() }
        }.padding(12).background(isActive ? Color.green.opacity(0.15) : Color.black.opacity(0.3)).overlay(Rectangle().stroke(isActive ? Color.green : RetroTheme.dim.opacity(0.5), lineWidth: isActive ? 2 : 1)).shadow(color: isActive ? Color.green.opacity(0.4) : .clear, radius: 8, x: 0, y: 0)
    }
}

// --- 5. EXTENDED INPUT VIEW (OPPDATERT) ---
struct ExtendedInputView: View {
    @Binding var process: WeldingProcess
    @Binding var diameter: Double
    @Binding var polarity: String
    @Binding var wireFeedSpeed: Double
    @Binding var isArcEnergy: Bool
    
    // NYE BINDINGS
    @Binding var actualInterpass: Double
    @Binding var gasType: String
    @Binding var passType: String
    
    let calculatedTravelSpeed: Double
    @Binding var focusedField: HeatInputView.InputTarget?
    
    let passTypes = ["Root", "Fill", "Cap", "-"]
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. PROSESS & TYPE
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROSESS").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                    Text(process.name).font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                // PASS TYPE VELGER
                VStack(alignment: .leading, spacing: 6) {
                    Text("PASS TYPE").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                    HStack(spacing: 0) {
                        ForEach(passTypes, id: \.self) { type in
                            Button(action: { passType = type }) {
                                Text(type.prefix(1)) // R, F, C, -
                                    .font(RetroTheme.font(size: 10, weight: .bold))
                                    .foregroundColor(passType == type ? .black : RetroTheme.primary)
                                    .frame(height: 30).frame(maxWidth: .infinity)
                                    .background(passType == type ? RetroTheme.primary : Color.black)
                            }.buttonStyle(.plain)
                            if type != passTypes.last { Rectangle().fill(RetroTheme.primary).frame(width: 1, height: 30) }
                        }
                    }.overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                }
            }
            
            Divider().background(RetroTheme.dim)
            
            // 2. DIAMETER & POLARITET
            HStack(spacing: 16) {
                RetroInputBlock(label: "DIAMETER (Ø)", unit: "mm", value: diameter, isActive: focusedField == .diameter) { withAnimation { focusedField = .diameter } }
                VStack(alignment: .leading, spacing: 6) {
                    Text("POLARITET").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                    HStack(spacing: 0) {
                        ForEach(["DC+", "DC-", "AC"], id: \.self) { pol in
                            Button(action: { polarity = pol }) { Text(pol).font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(polarity == pol ? .black : RetroTheme.primary).frame(height: 30).frame(maxWidth: .infinity).background(polarity == pol ? RetroTheme.primary : Color.black) }.buttonStyle(.plain)
                            if pol != "AC" { Rectangle().fill(RetroTheme.primary).frame(width: 1, height: 30) }
                        }
                    }.overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                }
            }
            
            // 3. INTERPASS & GASS (NY)
            HStack(spacing: 16) {
                RetroInputBlock(label: "ACTUAL INTERPASS", unit: "°C", value: actualInterpass, isActive: focusedField == .interpass) {
                    withAnimation { focusedField = .interpass }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("GAS TYPE").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                    TextField("Ex: Mison 18", text: $gasType)
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(.horizontal, 8)
                        .frame(height: 44)
                        .background(Color.black)
                        .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                }
            }
            
            // 4. WFS & SPEED
            HStack(spacing: 16) {
                RetroInputBlock(label: "WFS", unit: "m/min", value: wireFeedSpeed, isActive: focusedField == .wfs) { withAnimation { focusedField = .wfs } }
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRAVEL SPEED").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                    HStack { Text(String(format: "%.1f", calculatedTravelSpeed)).font(RetroTheme.font(size: 18, weight: .bold)).foregroundColor(RetroTheme.primary); Text("mm/min").font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim) }.frame(height: 44).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10).overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
                }
            }
        }.padding(.top, 10)
    }
}

// Hjelpeblokk for inputs
struct RetroInputBlock: View {
    let label: String
    let unit: String
    var value: Double
    var isActive: Bool
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                HStack { Text(String(format: "%.1f", value)).font(RetroTheme.font(size: 18, weight: .bold)).foregroundColor(isActive ? .black : RetroTheme.primary); Spacer(); Text(unit).font(RetroTheme.font(size: 12)).foregroundColor(isActive ? .black : RetroTheme.dim) }.frame(height: 44).padding(.horizontal, 10).background(isActive ? RetroTheme.primary : Color.clear).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
            }
        }.buttonStyle(.plain)
    }
}
