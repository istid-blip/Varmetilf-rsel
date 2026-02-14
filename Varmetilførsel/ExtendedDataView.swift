//
//  ExtendedDataView.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 20/01/2026.
//

import SwiftUI

struct ExtendedDataView: View {
    @Binding var isPresented: Bool
    
    // Vi henter de samme dataene her
    @AppStorage("ext_wirefeed") private var extWireFeed: String = ""
    @AppStorage("ext_interpass") private var extInterpass: String = ""
    @AppStorage("ext_gasflow") private var extGasFlow: String = ""
    @AppStorage("ext_stickout") private var extStickout: String = ""
    @AppStorage("ext_polarity") private var extPolarity: String = "DC+"
    @AppStorage("ext_note") private var extNote: String = ""
    
    var body: some View {
        ZStack {
            // 1. Bakgrunn
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 2. Header
                HStack {
                    Text("ISO 15609-1 DATA")
                        .font(RetroTheme.font(size: 18, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                    Spacer()
                    Button("CLOSE") {
                        isPresented = false
                        Haptics.selection()
                    }
                    .font(RetroTheme.font(size: 12, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                    .padding(8)
                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Seksjon 1: Tråd og Varme
                        HStack(spacing: 15) {
                            RetroTextFieldWithLabel(label: "Wire Feed Speed", unit: "m/min", text: $extWireFeed)
                            RetroTextFieldWithLabel(label: "Interpass Temp", unit: "°C", text: $extInterpass)
                        }
                        
                        // Seksjon 2: Gass og Utstikk
                        HStack(spacing: 15) {
                            RetroTextFieldWithLabel(label: "Gas Flow", unit: "l/min", text: $extGasFlow)
                            RetroTextFieldWithLabel(label: "Stick-out", unit: "mm", text: $extStickout)
                        }
                        
                        // Seksjon 3: Polaritet
                        VStack(alignment: .leading, spacing: 4) {
                            Text("POLARITY".uppercased())
                                .font(RetroTheme.font(size: 10, weight: .bold))
                                .foregroundColor(RetroTheme.dim)
                            
                            HStack(spacing: 0) {
                                ForEach(["DC+", "DC-", "AC"], id: \.self) { pol in
                                    Button(action: { extPolarity = pol; Haptics.selection() }) {
                                        Text(pol)
                                            .font(RetroTheme.font(size: 14, weight: .bold))
                                            .foregroundColor(extPolarity == pol ? .black : RetroTheme.primary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 40)
                                            .background(extPolarity == pol ? RetroTheme.primary : Color.black)
                                            .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Seksjon 4: Merknader
                        VStack(alignment: .leading, spacing: 4) {
                            Text("REMARKS / CONSUMABLES".uppercased())
                                .font(RetroTheme.font(size: 10, weight: .bold))
                                    .foregroundColor(RetroTheme.dim)
                            
                            TextField("Type details here...", text: $extNote)
                                .font(RetroTheme.font(size: 14))
                                .foregroundColor(RetroTheme.primary)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
        }
        .crtScreen()
        .presentationDetents([.medium, .large])
    }
}

// --- HJELPER: RETRO TEXT FIELD (Flyttet hit) ---
struct RetroTextFieldWithLabel: View {
    let label: String
    let unit: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .decimalPad
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(RetroTheme.font(size: 10, weight: .bold))
                .foregroundColor(RetroTheme.dim)
            
            HStack {
                TextField("0.0", text: $text)
                    .font(RetroTheme.font(size: 16, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                    .keyboardType(keyboardType)
                    
                
                Text(unit)
                    .font(RetroTheme.font(size: 12))
                    .foregroundColor(RetroTheme.dim)
            }
            .padding(10)
            .background(Color.black.opacity(0.3))
            .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
        }
    }
}
