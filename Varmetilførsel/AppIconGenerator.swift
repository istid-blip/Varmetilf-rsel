//
//  AppIconGenerator.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 02/02/2026.
//

import SwiftUI

// Denne visningen er KUN for å eksportere ikonet ditt
struct AppIconGenerator: View {
    let size: CGFloat = 1024 // App Store standard størrelse
    
    var body: some View {
        ZStack {
            // 1. Bakgrunn (Fyller hele firkanten)
            RetroTheme.background
                .ignoresSafeArea()
            
            // 2. Rammen (Trukket litt inn så den ikke klippes av iOS-masken)
            // Safe zone er ca 16-20% inn.
            RoundedRectangle(cornerRadius: size * 0.18)
                .stroke(RetroTheme.primary, lineWidth: size * 0.04)
                .padding(size * 0.12) // Viktig padding for app-ikoner
            
            // 3. Innholdet: Q + Cursor
            HStack(alignment: .bottom, spacing: size * 0.05) {
                
                Text("Q")
                    .font(.system(size: size * 0.5, weight: .bold, design: .monospaced))
                    .foregroundColor(RetroTheme.primary)
                    .baselineOffset(size * 0.04)
                
                Rectangle()
                    .fill(RetroTheme.primary)
                    .frame(width: size * 0.10, height: size * 0.16)
                    .offset(y: -(size * 0.09))
            }
            // Glow-effekt
            .shadow(color: RetroTheme.primary.opacity(0.8), radius: size * 0.04)
        }
        .frame(width: size, height: size)
    }
}

// VIKTIG: Dette gir deg bildet du skal lagre
#Preview("Export This Icon", traits: .fixedLayout(width: 1024, height: 1024)) {
    AppIconGenerator()
}
