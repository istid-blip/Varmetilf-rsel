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
    @State private var isWidthExpanded = false
    
    var body: some View {
        Button(action: {
            if isExpanded {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isWidthExpanded = false
                    isExpanded = false
                }
            } else {
                Haptics.play(.light)
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = true
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.15)) {
                    isWidthExpanded = true
                }
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
                    dropdownOverlay(geo: geo)
                }
            }
        )
        .zIndex(isExpanded ? 100 : 1)
    }

    @ViewBuilder
        private func dropdownOverlay(geo: GeometryProxy) -> some View {
            ZStack(alignment: .topLeading) {
                // KLIKK-FANGER
                Color.black.opacity(0.001)
                    .frame(width: 4000, height: 4000)
                    .contentShape(Rectangle())
                    .offset(x: -1000, y: -1000)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isWidthExpanded = false
                            isExpanded = false
                        }
                    }

                // SELVE MENY-LISTEN
                VStack(alignment: .leading, spacing: 0) { // La til alignment: .leading her
                    ForEach(options) { option in
                        RetroDropdownRow(
                            option: option,
                            selection: selection,
                            itemText: itemText,
                            itemDetail: itemDetail,
                            onSelect: {
                                onSelect(option)
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isWidthExpanded = false
                                    isExpanded = false
                                }
                            }
                        )
                    }
                }
                .background(Color.black)
                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1.5))
                // 1. Hindre at den går ut av skjermen:
                // Vi setter en max bredde som er skjermbredde minus avstanden fra venstre side
                .frame(width: isWidthExpanded ? nil : geo.size.width, alignment: .leading)
                .frame(minWidth: geo.size.width)
                .frame(maxWidth: UIScreen.main.bounds.width - geo.frame(in: .global).minX - 40, alignment: .leading)
                .offset(y: geo.size.height + 5)
                .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 10)
            }
        }
    }

    struct RetroDropdownRow<T: Equatable>: View {
        let option: T
        let selection: T
        let itemText: (T) -> String
        let itemDetail: ((T) -> String)?
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemText(option))
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(option == selection ? Color.black : RetroTheme.primary)
                        .lineLimit(1) // Kutter teksten hvis den er for lang for skjermen
                    
                    if let detail = itemDetail?(option) {
                        Text(detail)
                            .font(RetroTheme.font(size: 9))
                            .foregroundColor(option == selection ? Color.black.opacity(0.7) : RetroTheme.dim)
                            .lineLimit(1)
                    }
                }
                // 2. Fjerne hopping: Tvinger innholdet til venstre med en gang
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(option == selection ? RetroTheme.primary : Color.black)
            }
            .buttonStyle(PlainButtonStyle()) // Sikrer at knappen ikke får standard blå-effekt
            .overlay(
                Rectangle().frame(height: 1).foregroundColor(RetroTheme.dim.opacity(0.3)),
                alignment: .bottom
            )
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
                context.fill(Path(rect), with: .color(.black.opacity(0.05)))
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
struct RetroModalDrawer<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    var fromTop: Bool = false
    var showHeader: Bool = true       // NY: Kan skjule header
    var fixedHeight: CGFloat? = nil   // NY: Kan sette fast høyde
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack(alignment: fromTop ? .top : .bottom) {
            
            // 1. BAKGRUNN (Klikk-fanger)
            if isPresented {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
            }
            
            // 2. SELVE SKUFFEN
            if isPresented {
                VStack(spacing: 0) {
                    // HEADER (Vis kun hvis showHeader er true)
                    if showHeader {
                        HStack {
                            Text(title)
                                .font(RetroTheme.font(size: 12, weight: .bold))
                                .foregroundColor(RetroTheme.dim)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(RetroTheme.dim, lineWidth: 1))
                            }
                        }
                        .padding(16)
                    } else {
                        // Litt luft i toppen hvis header mangler
                        Color.clear.frame(height: 16)
                    }
                    
                    // INNHOLD
                    content
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .frame(width: 320)
                .frame(height: fixedHeight) // Setter høyden her hvis den er definert
                .background(Color.black)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RetroTheme.dim, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 10)
                .padding(fromTop ? .top : .bottom, 50)
                .transition(.move(edge: fromTop ? .top : .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

// --- STANDARD RETRO TOGGLE COMPONENT ---
struct RetroToggle: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    var isSubToggle: Bool = false // Nyhet: Kan gjøres mindre
    
    var body: some View {
        HStack {
            Text(title)
                .font(RetroTheme.font(size: isSubToggle ? 14 : 18, weight: isSubToggle ? .bold : .bold)) // Litt mindre tekst hvis sub-toggle
                .foregroundColor(RetroTheme.primary)

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 0).stroke(RetroTheme.primary, lineWidth: 1).background(Color.black.opacity(0.01)).frame(width: isSubToggle ? 40 : 60, height: isSubToggle ? 24 : 32)
                if isOn { RoundedRectangle(cornerRadius: 0).fill(RetroTheme.primary.opacity(0.1)).frame(width: isSubToggle ? 40 : 60, height: isSubToggle ? 24 : 32) }
                RoundedRectangle(cornerRadius: 0).fill(isOn ? RetroTheme.primary : RetroTheme.dim).frame(width: isSubToggle ? 16 : 24, height: isSubToggle ? 16 : 24).overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black, lineWidth: 2).opacity(0.3)).shadow(color: isOn ? RetroTheme.primary.opacity(0.8) : .clear, radius: 8).offset(x: isOn ? (isSubToggle ? 8 : 13) : (isSubToggle ? -8 : -13))
            }
            .onTapGesture { Haptics.selection(); withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) { isOn.toggle() } }
        }
        .contentShape(Rectangle())
        .onTapGesture { Haptics.selection(); withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isOn.toggle() } }
    }
}
