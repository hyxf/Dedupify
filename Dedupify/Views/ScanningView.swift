//
//  ScanningView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct ScanningView: View {
    @EnvironmentObject var appState: AppState
    var namespace: Namespace.ID
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                // Core Orb
                Circle()
                    .fill(RadialGradient(colors: [.blue.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: 140))
                    .frame(width: 280, height: 280)
                    .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                
                // Spinner
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.blue, .cyan.opacity(0.1)]), center: .center),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(rotation))
                
                VStack(spacing: 8) {
                    Text("\(appState.scannedFolderCount)")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.white)
                    Text("Folders")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Text(appState.scanProgress)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 400)
                    .lineLimit(1)
                
                Button(action: { appState.stopScan() }) {
                    Text("Stop Scanning")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 60)
        }
    }
}
