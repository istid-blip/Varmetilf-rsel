//
//  JobDetailView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct JobDetailView: View {
    @Bindable var job: WeldGroup
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    // Hjelpefunksjon som lagrer filen til disk og returnerer URL-en
    func generateExportFile() -> URL {
        let csvContent = job.generateCSV()
        let safeName = job.name.replacingOccurrences(of: " ", with: "_")
        let dateString = job.date.formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
        let fileName = "\(safeName)_\(dateString).csv"
        let tempDir = FileManager.default.temporaryDirectory
        let fileUrl = tempDir.appendingPathComponent(fileName)
        try? csvContent.write(to: fileUrl, atomically: true, encoding: .utf8)
        return fileUrl
    }
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button(action: { dismiss() }) { HStack(spacing: 5) { Text("< BACK") }.font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary).padding(8).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1)) }
                    Spacer()
                    Text("JOB_EDITOR_V1").font(RetroTheme.font(size: 16, weight: .heavy)).foregroundColor(RetroTheme.primary)
                    Spacer()
                    let fileUrl = generateExportFile()
                    ShareLink(item: fileUrl) { HStack(spacing: 5) { Text("EXPORT"); Image(systemName: "square.and.arrow.up") }.font(RetroTheme.font(size: 12, weight: .bold)).foregroundColor(RetroTheme.primary).padding(8).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1)) }
                }.padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        JobMetadataEditor(job: job)
                        JobPassesList(job: job)
                    }.padding()
                }
            }
        }.crtScreen().navigationBarBackButtonHidden(true)
    }
}

// METADATA
struct JobMetadataEditor: View {
    @Bindable var job: WeldGroup
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JOB METADATA").font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim)
            VStack(spacing: 12) {
                RetroTextField(title: "JOB NAME", text: $job.name)
                RetroTextField(title: "WPQR / REF", text: $job.wpqrNumber)
                HStack(spacing: 10) { RetroTextField(title: "PREHEAT (°C)", text: $job.preheatTemp); RetroTextField(title: "MAX INTERPASS (°C)", text: $job.interpassTemp) }
                RetroTextField(title: "NOTES", text: $job.notes)
            }.padding().overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
        }
    }
}

// LISTE
struct JobPassesList: View {
    let job: WeldGroup; @Environment(\.modelContext) var modelContext
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LOGGED PASSES (\(job.passes.count))").font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim); Spacer()
                if !job.passes.isEmpty { let avg = job.passes.compactMap { $0.heatInput }.reduce(0, +) / Double(job.passes.count); Text("AVG: \(String(format: "%.2f", avg)) kJ/mm").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.primary) }
            }
            if job.passes.isEmpty { Text("NO PASSES RECORDED").font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.dim).padding().frame(maxWidth: .infinity).overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1)) }
            else { let sorted = job.passes.sorted(by: { $0.timestamp < $1.timestamp }); ForEach(sorted) { pass in DetailedPassRow(pass: pass, onDelete: { deletePass(pass) }) } }
        }
    }
    func deletePass(_ pass: SavedCalculation) { withAnimation { if let index = job.passes.firstIndex(of: pass) { job.passes.remove(at: index) }; modelContext.delete(pass) } }
}

// RAD (Utvidet)
struct DetailedPassRow: View {
    let pass: SavedCalculation; var onDelete: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text(pass.name).font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary)
                    if let type = pass.passType, type != "-" { Text("(\(type))").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim) }
                }
                Spacer()
                Text(pass.timestamp.formatted(date: .omitted, time: .shortened)).font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                Button(action: onDelete) { Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.red.opacity(0.7)).padding(6).background(Color.red.opacity(0.1)).clipShape(Circle()) }
            }
            Divider().background(RetroTheme.dim.opacity(0.3))
            
            // Hoveddata
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 8) {
                    ParamValue(label: "U", value: String(format: "%.1f V", pass.voltage ?? 0))
                    ParamValue(label: "I", value: String(format: "%.0f A", pass.amperage ?? 0))
                    ParamValue(label: "t", value: String(format: "%.0f s", pass.travelTime ?? 0))
                    ParamValue(label: "L", value: String(format: "%.0f mm", pass.weldLength ?? 0))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.2f", pass.heatInput)).font(RetroTheme.font(size: 18, weight: .heavy)).foregroundColor(RetroTheme.primary)
                    Text(pass.isArcEnergy ? "kJ/mm (AE)" : "kJ/mm").font(RetroTheme.font(size: 8)).foregroundColor(RetroTheme.dim)
                }
            }
            
            // Utvidet data
            if hasExtendedData(pass) {
                Divider().background(RetroTheme.dim.opacity(0.2))
                VStack(spacing: 6) {
                    HStack(spacing: 12) {
                        HStack(spacing: 2) {
                            Text(pass.processName)
                            if let mode = pass.transferMode, mode != "-", mode != "Short" { Text("(\(mode))").foregroundColor(RetroTheme.dim) } // Vis mode hvis ikke default
                        }.font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.primary.opacity(0.8))
                        
                        if let gas = pass.gasType, !gas.isEmpty { Text(gas).font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim) }
                        if let flow = pass.gasFlow, flow > 0 { Text("\(String(format: "%.0f", flow)) l/min").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim) }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        // Linje 2: Filler, Dia, Speed, Interpass
                        if let filler = pass.fillerMaterial, !filler.isEmpty { ExtValue(icon: "fuelpump.fill", text: filler) } // Bruker fuelpump symbol for filler wire inntil videre
                        if let dia = pass.fillerDiameter, dia > 0 { ExtValue(icon: "circle.circle", text: "Ø\(String(format: "%.1f", dia))") }
                        if let speed = pass.savedTravelSpeed, speed > 0 { ExtValue(icon: "speedometer", text: "\(String(format: "%.0f", speed)) mm/m") }
                        if let ip = pass.actualInterpass, ip > 0 { ExtValue(icon: "thermometer", text: "\(String(format: "%.0f", ip))°C") }
                    }
                }
            }
        }.padding(12).background(Color.black.opacity(0.5)).overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
    }
    
    func ParamValue(label: String, value: String) -> some View { HStack(spacing: 2) { Text(label + ":").foregroundColor(RetroTheme.dim); Text(value).foregroundColor(RetroTheme.primary) }.font(RetroTheme.font(size: 10)) }
    func ExtValue(icon: String, text: String) -> some View { HStack(spacing: 2) { Image(systemName: icon).font(.system(size: 8)); Text(text) }.font(RetroTheme.font(size: 9)).foregroundColor(RetroTheme.dim).padding(2).overlay(RoundedRectangle(cornerRadius: 2).stroke(RetroTheme.dim.opacity(0.3), lineWidth: 1)) }
    func hasExtendedData(_ p: SavedCalculation) -> Bool {
        return (p.fillerDiameter ?? 0) > 0 || (p.wireFeedSpeed ?? 0) > 0 || (p.actualInterpass ?? 0) > 0 || (p.gasType != nil) || (p.gasFlow ?? 0) > 0 || (p.fillerMaterial != nil)
    }
}

// TEXT FIELD
struct RetroTextField: View {
    let title: String; @Binding var text: String; @State private var localText: String = ""; @FocusState private var isFocused: Bool
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(title).font(RetroTheme.font(size: 9)).foregroundColor(RetroTheme.primary); TextField("", text: $localText).font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.primary).padding(8).background(Color.black).overlay(Rectangle().stroke(isFocused ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1)).focused($isFocused).onAppear { localText = text }.onChange(of: isFocused) { _, newValue in if !newValue { text = localText } }.onSubmit { text = localText } } }
}

// EXPORT EXTENSION
extension WeldGroup {
    func generateCSV() -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current; formatter.numberStyle = .decimal; formatter.maximumFractionDigits = 2; formatter.minimumFractionDigits = 2; formatter.usesGroupingSeparator = false
        let decimalSep = formatter.decimalSeparator ?? "."; let colSep = (decimalSep == ",") ? ";" : ","
        var csv = ""
        
        csv += "JOB REPORT\(colSep)Varmetilforsel App\n"
        csv += "Name\(colSep)\"\(self.name)\"\n"
        csv += "Date\(colSep)\"\(self.date.formatted(date: .numeric, time: .omitted))\"\n"
        csv += "WPQR\(colSep)\"\(self.wpqrNumber)\"\n"
        csv += "Preheat Temp\(colSep)\"\(self.preheatTemp) °C\"\n"
        csv += "Max Interpass\(colSep)\"\(self.interpassTemp) °C\"\n"
        csv += "Notes\(colSep)\"\(self.notes)\"\n\n"
        
        // OPPDATERT HEADER:
        let headers = [
            "Pass", "Type", "Process", "Transfer", "Filler Mat", "Gas Type", "Flow (l/min)", "Voltage (V)", "Amperage (A)", "Time (s)",
            "Length (mm)", "Energy (kJ/mm)", "k-Factor", "Travel Spd (mm/min)", "Interpass (°C)", "Diameter (mm)",
            "Polarity", "WFS (m/min)", "Timestamp"
        ]
        csv += headers.joined(separator: colSep) + "\n"
        
        let sortedPasses = self.passes.sorted(by: { $0.timestamp < $1.timestamp })
        for pass in sortedPasses {
            func fmt(_ val: Double?) -> String { guard let v = val, v > 0 else { return "" }; return formatter.string(from: NSNumber(value: v)) ?? "" }
            let heatVal = formatter.string(from: NSNumber(value: pass.heatInput)) ?? "0\(decimalSep)00"
            let timeStamp = pass.timestamp.formatted(date: .omitted, time: .shortened)
            let kVal = pass.isArcEnergy ? "1\(decimalSep)0 (AE)" : (formatter.string(from: NSNumber(value: pass.kFactorUsed)) ?? "")
            
            let row = [
                pass.name,
                pass.passType ?? "-",
                pass.processName,
                pass.transferMode ?? "-",      // Ny
                pass.fillerMaterial ?? "-",    // Ny
                pass.gasType ?? "-",
                fmt(pass.gasFlow),             // Ny
                fmt(pass.voltage),
                fmt(pass.amperage),
                fmt(pass.travelTime),
                fmt(pass.weldLength),
                heatVal,
                kVal,
                fmt(pass.savedTravelSpeed),    // Ny (lagret speed)
                fmt(pass.actualInterpass),
                fmt(pass.fillerDiameter),
                pass.polarity ?? "",
                fmt(pass.wireFeedSpeed),
                timeStamp
            ].joined(separator: colSep)
            csv += row + "\n"
        }
        return csv
    }
}
