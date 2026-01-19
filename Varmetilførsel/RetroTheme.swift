//
//  RetroTheme.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 18/01/2026.
//

import SwiftUI
import SwiftData

struct RetroTheme {
    // The Classic "Phosphor Green"
    static let primary = Color(red: 0.2, green: 1.0, blue: 0.3)
    // A dim version for placeholders
    static let dim = Color(red: 0.1, green: 0.4, blue: 0.1)
    // Deep black background
    static let background = Color.black
    
    // The standard terminal font
    static func font(size: CGFloat = 16, weight: Font.Weight = .medium) -> Font {
        return Font.system(size: size, weight: weight, design: .monospaced)
    }
} //Struct som tar for seg basiclayout

struct RetroDropdown<T: Identifiable & Equatable>: View {
    let title: String
    let selection: T
    let options: [T]
    let onSelect: (T) -> Void
    let itemText: (T) -> String
    let itemDetail: ((T) -> String)?
    
    @State private var isExpanded = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
            if isExpanded {
                Haptics.play(.light)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemText(selection))
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let detail = itemDetail?(selection) {
                        HStack {
                            Text(detail)
                                .font(RetroTheme.font(size: 9))
                            Spacer()
                            Text(isExpanded ? "▲" : "▼")
                                .font(RetroTheme.font(size: 10))
                        }
                        .foregroundColor(RetroTheme.dim)
                    }
                }
            }
            .padding(10)
            .background(Color.black)
            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1.5))
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(RetroTheme.primary)
        .overlay(
            GeometryReader { geo in
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(options) { option in
                            Button(action: {
                                onSelect(option)
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(itemText(option))
                                        .font(RetroTheme.font(size: 14))
                                        .foregroundColor(option == selection ? Color.black : RetroTheme.primary)
                                    
                                    Spacer()
                                    
                                    if let detail = itemDetail?(option) {
                                        Text(detail)
                                            .font(RetroTheme.font(size: 10))
                                            .foregroundColor(option == selection ? Color.black.opacity(0.8) : RetroTheme.dim)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 10)
                                .background(option == selection ? RetroTheme.primary : Color.black)
                            }
                            .overlay(
                                Rectangle().frame(height: 1).foregroundColor(RetroTheme.dim.opacity(0.3)),
                                alignment: .bottom
                            )
                        }
                    }
                    .background(Color.black)
                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1.5))
                    .frame(width: geo.size.width)
                    .offset(y: geo.size.height + 5)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)
                }
            }
        )
        .zIndex(isExpanded ? 100 : 1)
    }
} //Retrodropdown kan kanskje trimmes

struct RetroBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(RetroTheme.background)
            .overlay(
                Rectangle()
                    .stroke(RetroTheme.primary, lineWidth: 2)
            )
    }
} //Box eller felt

struct CRTOverlay: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // Force background black everywhere
            RetroTheme.background.ignoresSafeArea()
            
            content
            
            // The Scanlines (Optimized with Canvas and drawingGroup)
            Scanlines()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Let touches pass through
        }
    }
}//Scanlinjer1
struct Scanlines: View {
    var body: some View {
        Canvas { context, size in
            // Tegn en linje hver 4. piksel (2px linje, 2px mellomrom)
            for y in stride(from: 0, to: size.height, by: 4) {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 2)
                context.fill(Path(rect), with: .color(.black.opacity(0.15))) // Litt tydeligere scanlines (0.1 -> 0.15)
            }
        }
        // VIKTIG OPTIMALISERING: Cacher tegningen som et bilde på GPU.
        // Dette hindrer at CPU kjører på 100% når ting blinker på skjermen.
        .drawingGroup()
    }
}//Scanlinjer2


struct BlinkModifier: ViewModifier {
    @State private var isBlinking = false
    // Vi lytter til om appen er aktiv eller i bakgrunnen
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .opacity(isBlinking ? 1 : 0.3)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    startAnimation()
                } else {
                    // Stopp animasjonen for å spare strøm/CPU når appen er lukket
                    stopAnimation()
                }
            }
            .onAppear {
                if scenePhase == .active {
                    startAnimation()
                }
            }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isBlinking = true
        }
    }
    
    private func stopAnimation() {
        // Reset state uten animasjon
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isBlinking = true // Sett til synlig når den ikke blinker
        }
    }
}//Sakte blinkende tekst

struct RetroHistoryRow: View {
    let item: SavedCalculation
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Navn og Dato
                HStack {
                    Text(item.name)
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    
                    Spacer()
                    
                    Text(item.timestamp, format: .dateTime.day().month().hour().minute())
                        .font(RetroTheme.font(size: 10))
                        .foregroundColor(RetroTheme.dim)
                }
                
                // VISER DETALJENE HVIS DE FINNES
                if let v = item.voltage, let i = item.amperage, let t = item.travelTime, let l = item.weldLength {
                    HStack(spacing: 10) {
                        detailText(label: "U:", value: "\(v)V")
                        detailText(label: "I:", value: "\(Int(i))A")
                        detailText(label: "t:", value: "\(Int(t))s")
                        detailText(label: "L:", value: "\(Int(l))mm")
                    }
                }
            }
            
            Spacer()
            
            // Resultat
            VStack(alignment: .trailing) {
                Text(item.resultValue)
                    .font(RetroTheme.font(size: 18, weight: .heavy))
                    .foregroundColor(RetroTheme.primary)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(RetroTheme.dim)
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
        .background(Color.black.opacity(0.3))
    }
    
    // Hjelpefunksjon for små detaljer
    func detailText(label: String, value: String) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(RetroTheme.dim)
            Text(value)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(RetroTheme.primary)
        }
    }
} //Opptegning av historikken i JobDetailView




extension View {
    func retroStyle() -> some View {
        self.modifier(RetroBox())
    }
    
    func crtScreen() -> some View {
        self.modifier(CRTOverlay())
    }
    
    func blinkEffect() -> some View {
        self.modifier(BlinkModifier())
    }
}
