//
//  HeatInpuLogo.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 02/02/2026.
//
import SwiftUI

struct HeatInputLogo: View {
    var body: some View {
        ZStack {
            // Bakgrunn
            RetroTheme.background
            
            // Selve logo-linjen (Pulsen)
            Path { path in
                let w = 200.0
                let h = 200.0
                let midY = h / 2
                
                // Start
                path.move(to: CGPoint(x: 20, y: midY))
                // Første knekk
                path.addLine(to: CGPoint(x: w * 0.3, y: midY))
                // Toppen av pulsen (Heat spike)
                path.addLine(to: CGPoint(x: w * 0.5, y: midY - 60))
                // Bunnen av pulsen
                path.addLine(to: CGPoint(x: w * 0.7, y: midY + 40))
                // Tilbake til normalen
                path.addLine(to: CGPoint(x: w * 0.8, y: midY))
                // Slutt
                path.addLine(to: CGPoint(x: w - 20, y: midY))
            }
            .stroke(RetroTheme.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            .shadow(color: RetroTheme.primary.opacity(0.8), radius: 10) // "Phosphor Glow" effekt
        }
        .frame(width: 200, height: 200)
    }
}
struct HeatInputLogoQ: View {
    // Lar deg overstyre størrelsen hvis du vil bruke den som et lite ikon
    var size: CGFloat = 200
    
    var body: some View {
        ZStack {
            // 1. Bakgrunnen (Sort CRT-skjerm)
            RetroTheme.background
            
            // 2. Rammen (Terminal-vinduet)
            RoundedRectangle(cornerRadius: size * 0.2)
                .stroke(RetroTheme.primary, lineWidth: size * 0.03)
                .padding(size * 0.05)
            
            // 3. Innholdet: Q + Cursor
            HStack(alignment: .bottom, spacing: size * 0.05) {
                
                // Q for Heat (Energi)
                Text("Q")
                    .font(.system(size: size * 0.6, weight: .bold, design: .monospaced))
                    .foregroundColor(RetroTheme.primary)
                
                // Cursor for Input (En solid blokk)
                Rectangle()
                    .fill(RetroTheme.primary)
                    .frame(width: size * 0.12, height: size * 0.15)
                    .offset(y: -(size * 0.12)) // Løfter cursoren litt opp fra bunnlinjen
            }
            // 4. Den viktige "Phosphor Glow"-effekten
            .shadow(color: RetroTheme.primary.opacity(0.8), radius: size * 0.05)
        }
        .frame(width: size, height: size)
        // Klipper innholdet så det holder seg innenfor rammen hvis du skalerer ned
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}
struct HeatInputWireframeLogo: View {
    // Juster størrelsen her ved bruk
    var size: CGFloat = 200
    
    var body: some View {
        ZStack {
            // 1. Sort bakgrunn
            RetroTheme.background
            
            // 2. Selve gnisten (Lynet)
            Path { path in
                let w = size
                let h = size
                
                // Vi tegner en skarp, kantete lyn-form
                // Start oppe til høyre
                path.move(to: CGPoint(x: w * 0.65, y: h * 0.15))
                
                // Første hogg ned mot venstre
                path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.50))
                
                // Et lite hakk inn mot høyre (for å lage "sagblad"-effekten)
                path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.50))
                
                // Selve spissen som treffer materialet
                path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.85))
                
                // -- Retur oppover --
                
                // Lang linje opp mot høyre
                path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.40))
                
                // Et lite hakk inn mot venstre
                path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.40))
                
                // Lukker formen tilbake til start
                path.closeSubpath()
            }
            .stroke(RetroTheme.primary, style: StrokeStyle(lineWidth: size * 0.02, lineCap: .round, lineJoin: .miter))
            .shadow(color: RetroTheme.primary.opacity(0.8), radius: size * 0.04) // Glød
            
            // 3. Materialet (Linjen under som gnisten treffer)
            Path { path in
                let w = size
                let h = size
                
                // En horisontal linje i bunnen
                path.move(to: CGPoint(x: w * 0.2, y: h * 0.90))
                path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.90))
                
                // Kanskje et par små "gnister" (prikker) der den treffer?
                // (Valgfritt, men gir liv)
                path.move(to: CGPoint(x: w * 0.35, y: h * 0.82))
                path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.81))
                
                path.move(to: CGPoint(x: w * 0.45, y: h * 0.80))
                path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.79))
            }
            .stroke(RetroTheme.primary, style: StrokeStyle(lineWidth: size * 0.02, lineCap: .round))
            .shadow(color: RetroTheme.primary.opacity(0.6), radius: size * 0.03)
        }
        .frame(width: size, height: size)
    }
}
