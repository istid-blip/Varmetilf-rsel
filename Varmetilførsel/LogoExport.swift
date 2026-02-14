//
//  Untitled.swift
//  Varmetilførsel
//
//  Created by Frode Halrynjo on 02/02/2026.
//
import SwiftUI

struct IconExportView: View {
    @State private var generatedIcon: Image?
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("App Icon Preview")
                .font(RetroTheme.font(size: 24, weight: .bold))
                .foregroundColor(RetroTheme.primary)
            
            // 1. Visning på skjermen (nedskalert så den får plass)
            AppIconGenerator()
                .frame(width: 300, height: 300) // Bare for visning
                .clipShape(RoundedRectangle(cornerRadius: 60))
                .overlay(
                    RoundedRectangle(cornerRadius: 60)
                        .stroke(RetroTheme.dim, lineWidth: 2)
                )
            
            Text("Dette er en forhåndsvisning.\nDet faktiske ikonet eksporteres i 1024x1024.")
                .font(RetroTheme.font(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding()
            
            // 2. Del-knappen
            // Krever iOS 16+
            if let icon = renderIcon() {
                ShareLink(item: icon, preview: SharePreview("HeatInput Icon", image: icon)) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Send til Mac (AirDrop)")
                    }
                    .font(RetroTheme.font(size: 18, weight: .bold))
                    .padding()
                    .background(RetroTheme.primary)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RetroTheme.background)
    }

    // Hjelpefunksjon som lager bildet
    @MainActor
    private func renderIcon() -> Image? {
        let renderer = ImageRenderer(content: AppIconGenerator())
        renderer.scale = 1.0 // Viktig: 1.0 sikrer nøyaktig 1024x1024 piksler
        
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

#Preview {
    IconExportView()
}
