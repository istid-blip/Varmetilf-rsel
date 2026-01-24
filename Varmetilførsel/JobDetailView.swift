//
//  JobDetailView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//
import SwiftUI
import SwiftData

struct JobDetailView: View {
    @Bindable var job: WeldGroup
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- HEADER ---
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) {
                            Text("< BACK")
                        }
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(8)
                        .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    Text("JOB_EDITOR_V1")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    
                    Spacer()
                    
                    // EKSPORT-KNAPP MED NYE DATA
                    ShareLink(item: job.generateCSV(), preview: SharePreview(job.name)) {
                        HStack(spacing: 5) {
                            Text("EXPORT")
                            Image(systemName: "square.and.arrow.up")
                        }
                        .font(RetroTheme.font(size: 12, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(8)
                        .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 1. METADATA SECTION
                        JobMetadataEditor(job: job)
                        
                        // 2. PASSES LIST SECTION
                        JobPassesList(job: job)
                    }
                    .padding()
                }
            }
        }
        .crtScreen()
        .navigationBarBackButtonHidden(true)
    }
}

// --- SUBVIEW 1: SKJEMA FOR REDIGERING ---
struct JobMetadataEditor: View {
    @Bindable var job: WeldGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JOB METADATA")
                .font(RetroTheme.font(size: 12))
                .foregroundColor(RetroTheme.dim)
            
            VStack(spacing: 12) {
                RetroTextField(title: "JOB NAME", text: $job.name)
                RetroTextField(title: "WPQR / REF", text: $job.wpqrNumber)
                
                HStack(spacing: 10) {
                    RetroTextField(title: "PREHEAT (°C)", text: $job.preheatTemp)
                    RetroTextField(title: "INTERPASS (°C)", text: $job.interpassTemp)
                }
                
                RetroTextField(title: "NOTES", text: $job.notes)
            }
            .padding()
            .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
        }
    }
}

// --- SUBVIEW 2: LISTE OVER SVEISER ---
struct JobPassesList: View {
    let job: WeldGroup
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LOGGED PASSES (\(job.passes.count))")
                    .font(RetroTheme.font(size: 12))
                    .foregroundColor(RetroTheme.dim)
                Spacer()
                if !job.passes.isEmpty {
                    // Bruker 'heatInput' fra modellen
                    let avg = job.passes.compactMap { $0.heatInput }.reduce(0, +) / Double(job.passes.count)
                    Text("AVG: \(String(format: "%.2f", avg)) kJ/mm")
                        .font(RetroTheme.font(size: 10))
                        .foregroundColor(RetroTheme.primary)
                }
            }
            
            if job.passes.isEmpty {
                Text("NO PASSES RECORDED")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.dim)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
            } else {
                let sortedPasses = job.passes.sorted(by: { $0.timestamp < $1.timestamp })
                
                ForEach(sortedPasses) { pass in
                    DetailedPassRow(pass: pass, onDelete: {
                        deletePass(pass)
                    })
                }
            }
        }
    }
    
    func deletePass(_ pass: SavedCalculation) {
        withAnimation {
            if let index = job.passes.firstIndex(of: pass) {
                job.passes.remove(at: index)
            }
            modelContext.delete(pass)
        }
    }
}

// --- NY UTVIDET RAD-VISNING ---
// Denne erstatter RetroHistoryRow for å vise de nye datafeltene
struct DetailedPassRow: View {
    let pass: SavedCalculation
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // HEADER: Navn, Tid og Sletteknapp
            HStack {
                Text(pass.name)
                    .font(RetroTheme.font(size: 14, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                
                Spacer()
                
                Text(pass.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(RetroTheme.dim)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Divider().background(RetroTheme.dim.opacity(0.3))
            
            // HOVEDDATA (U, I, t, L -> Resultat)
            HStack(alignment: .center, spacing: 12) {
                // Parametere
                HStack(spacing: 8) {
                    ParamValue(label: "U", value: String(format: "%.1f V", pass.voltage ?? 0))
                    ParamValue(label: "I", value: String(format: "%.0f A", pass.amperage ?? 0))
                    ParamValue(label: "t", value: String(format: "%.0f s", pass.travelTime ?? 0))
                    ParamValue(label: "L", value: String(format: "%.0f mm", pass.weldLength ?? 0))
                }
                
                Spacer()
                
                // Resultat (Stort)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.2f", pass.heatInput))
                        .font(RetroTheme.font(size: 18, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    Text(pass.isArcEnergy ? "kJ/mm (AE)" : "kJ/mm")
                        .font(RetroTheme.font(size: 8))
                        .foregroundColor(RetroTheme.dim)
                }
            }
            
            // UTVITDET DATA (Prosess, Ø, Pol, WFS) - Vises kun hvis data finnes
            if hasExtendedData(pass) {
                Divider().background(RetroTheme.dim.opacity(0.2))
                
                HStack(spacing: 12) {
                    // Prosess + k-faktor
                    HStack(spacing: 2) {
                        Text(pass.processName)
                        if !pass.isArcEnergy {
                            Text("(k=\(String(format: "%.1f", pass.kFactorUsed)))")
                                .foregroundColor(RetroTheme.dim)
                        }
                    }
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(RetroTheme.primary.opacity(0.8))
                    
                    Spacer()
                    
                    // Ø / Pol / WFS
                    HStack(spacing: 8) {
                        if let dia = pass.fillerDiameter, dia > 0 {
                            ExtValue(icon: "circle.circle", text: "Ø\(String(format: "%.1f", dia))")
                        }
                        if let pol = pass.polarity, !pol.isEmpty {
                            ExtValue(icon: "bolt.horizontal", text: pol)
                        }
                        if let wfs = pass.wireFeedSpeed, wfs > 0 {
                            ExtValue(icon: "gauge", text: "\(String(format: "%.1f", wfs)) m/min")
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.5))
        .overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
    }
    
    // Hjelper for hovedparametre
    func ParamValue(label: String, value: String) -> some View {
        HStack(spacing: 2) {
            Text(label + ":")
                .foregroundColor(RetroTheme.dim)
            Text(value)
                .foregroundColor(RetroTheme.primary)
        }
        .font(RetroTheme.font(size: 10))
    }
    
    // Hjelper for utvidet data
    func ExtValue(icon: String, text: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 8))
            Text(text)
        }
        .font(RetroTheme.font(size: 9))
        .foregroundColor(RetroTheme.dim)
        .padding(2)
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(RetroTheme.dim.opacity(0.3), lineWidth: 1))
    }
    
    func hasExtendedData(_ p: SavedCalculation) -> Bool {
        return (p.fillerDiameter ?? 0) > 0 || (p.wireFeedSpeed ?? 0) > 0 || (p.polarity != nil)
    }
}

// --- OPTIMALISERT TEKSTFELT ---
struct RetroTextField: View {
    let title: String
    @Binding var text: String
    
    @State private var localText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(RetroTheme.font(size: 9))
                .foregroundColor(RetroTheme.primary)
            
            TextField("", text: $localText)
                .font(RetroTheme.font(size: 14))
                .foregroundColor(RetroTheme.primary)
                .padding(8)
                .background(Color.black)
                .overlay(Rectangle().stroke(isFocused ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1))
                .focused($isFocused)
                .onAppear {
                    localText = text
                }
                .onChange(of: isFocused) { oldValue, newValue in
                    if !newValue {
                        text = localText
                    }
                }
                .onSubmit {
                    text = localText
                }
        }
    }
}

// --- UTVIDELSE FOR CSV GENERERING ---
extension WeldGroup {
    func generateCSV() -> String {
        var csv = ""
        
        // 1. Header Info (Metadata)
        csv += "JOB REPORT;Varmetilforsel App\n"
        csv += "Name;\"\(self.name)\"\n"
        csv += "Date;\"\(self.date.formatted(date: .numeric, time: .omitted))\"\n"
        csv += "WPQR;\"\(self.wpqrNumber)\"\n"
        csv += "Notes;\"\(self.notes)\"\n"
        csv += "\n"
        
        // 2. Kolonneoverskrifter (Oppdatert med nye felt)
        csv += "Pass;Process;Voltage (V);Amperage (A);Time (s);Length (mm);Energy (kJ/mm);k-Factor;Diameter (mm);Polarity;WFS (m/min);Timestamp\n"
        
        // 3. Data
        let sortedPasses = self.passes.sorted(by: { $0.timestamp < $1.timestamp })
        
        for pass in sortedPasses {
            // Hent verdier trygt
            let v = pass.voltage ?? 0
            let a = pass.amperage ?? 0
            let t = pass.travelTime ?? 0
            let l = pass.weldLength ?? 0
            let h = pass.heatInput // Bruker lagret verdi
            let time = pass.timestamp.formatted(date: .omitted, time: .shortened)
            
            // Utvidede felt (håndterer tomme verdier)
            let proc = pass.processName
            // Hvis Arc Energy, vis "AE" eller 1.0, ellers k-faktoren
            let kVal = pass.isArcEnergy ? "1.0 (AE)" : format(pass.kFactorUsed)
            
            let dia = pass.fillerDiameter != nil && pass.fillerDiameter! > 0 ? format(pass.fillerDiameter!) : ""
            let pol = pass.polarity ?? ""
            let wfs = pass.wireFeedSpeed != nil && pass.wireFeedSpeed! > 0 ? format(pass.wireFeedSpeed!) : ""
            
            let row = "\(pass.name);\(proc);\(format(v));\(format(a));\(format(t));\(format(l));\(format(h));\(kVal);\(dia);\(pol);\(wfs);\(time)\n"
            csv += row
        }
        
        return csv
    }
    
    private func format(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}
