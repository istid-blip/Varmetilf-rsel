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
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 1. METADATA SECTION (Isolert for ytelse)
                        JobMetadataEditor(job: job)
                        
                        // 2. PASSES LIST SECTION (Isolert for ytelse)
                        JobPassesList(job: job)
                    }
                    .padding()
                }
            }
        }
        .crtScreen() // Sørg for at denne ikke re-kalkuleres unødig
        .navigationBarBackButtonHidden(true)
    }
}

// --- SUBVIEW 1: SKJEMA FOR REDIGERING ---
// Ved å legge dette i en egen View-struct, unngår vi at resten av siden må tegnes på nytt når man skriver.
struct JobMetadataEditor: View {
    @Bindable var job: WeldGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JOB METADATA")
                .font(RetroTheme.font(size: 12))
                .foregroundColor(RetroTheme.dim)
            
            VStack(spacing: 12) {
                // Bruker optimalisert RetroTextField
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
    // Vi trenger strengt tatt bare lese passes her.
    // Ved å ikke bruke @Bindable på hele jobben, reduserer vi risikoen for unødvendige oppdateringer.
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
                // Sortering bør skje i viewet for å unngå database-kall i loopen
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
            // Siden 'job' er en klasse (WeldGroup), kan vi mutere arrayet direkte
            if let index = job.passes.firstIndex(of: pass) {
                job.passes.remove(at: index)
            }
            modelContext.delete(pass)
        }
    }
}

// --- OPTIMALISERT TEKSTFELT ---
// Denne bufrer teksten lokalt og skriver kun til databasen når man er ferdig.
struct RetroTextField: View {
    let title: String
    @Binding var text: String // Koblingen til databasen
    
    @State private var localText: String = "" // Lokal midlertidig tekst
    @FocusState private var isFocused: Bool // Holder styr på om feltet er aktivt
    
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
                // 1. Når viewet vises, hent verdi fra databasen
                .onAppear {
                    localText = text
                }
                // 2. Når feltet mister fokus, lagre til databasen
                .onChange(of: isFocused) { oldValue, newValue in
                    if !newValue {
                        text = localText
                    }
                }
                // 3. Hvis man trykker "Enter", lagre til databasen
                .onSubmit {
                    text = localText
                }
        }
    }
}

