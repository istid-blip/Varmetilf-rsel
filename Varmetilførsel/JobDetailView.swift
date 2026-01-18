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
                    
                    // 👇 NY EKSPORT-KNAPP HER
                    // ShareLink er innebygd i SwiftUI (iOS 16+) og håndterer eksport perfekt
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
                    let avg = job.passes.compactMap { $0.calculatedHeat }.reduce(0, +) / Double(job.passes.count)
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
                    RetroHistoryRow(item: pass, onDelete: {
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

// 👇 NYTT: UTVIDELSE FOR CSV GENERERING
// Dette lager en tekststreng som Excel og Numbers forstår.
extension WeldGroup {
    func generateCSV() -> String {
        var csv = ""
        
        // 1. Header Info (Metadata om jobben)
        csv += "JOB REPORT;Varmetilforsel App\n"
        csv += "Name;\"\(self.name)\"\n"
        csv += "Date;\"\(self.date.formatted(date: .numeric, time: .omitted))\"\n"
        csv += "WPQR;\"\(self.wpqrNumber)\"\n"
        csv += "Notes;\"\(self.notes)\"\n"
        csv += "\n" // Tom linje for luft
        
        // 2. Kolonneoverskrifter
        // Bruker semikolon (;) som separator da det ofte fungerer best i Norge pga komma i desimaltall
        csv += "Pass;Voltage (V);Amperage (A);Time (s);Length (mm);Heat Input (kJ/mm);Timestamp\n"
        
        // 3. Data (Sortert på tid)
        let sortedPasses = self.passes.sorted(by: { $0.timestamp < $1.timestamp })
        
        for pass in sortedPasses {
            let v = pass.voltage ?? 0
            let a = pass.amperage ?? 0
            let t = pass.travelTime ?? 0
            let l = pass.weldLength ?? 0
            let h = pass.calculatedHeat ?? 0
            let time = pass.timestamp.formatted(date: .omitted, time: .shortened)
            
            // Erstatter punktum med komma hvis vi vil være snille med norsk Excel,
            // men standard CSV bruker punktum for desimaler.
            // Her bruker jeg String(format) som følger telefonens språkinnstillinger (norsk = komma).
            let row = "\(pass.name);\(format(v));\(format(a));\(format(t));\(format(l));\(format(h));\(time)\n"
            csv += row
        }
        
        return csv
    }
    
    // Hjelpefunksjon for å formattere tall pent
    private func format(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}
