//
//  ResultsFoundView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct ResultsFoundView: View {
    @EnvironmentObject var appState: AppState
    var namespace: Namespace.ID
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.5), lineWidth: 4)
                    .frame(width: 280, height: 280)
                    .background(Circle().fill(Color.orange.opacity(0.05)))
                    .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                
                VStack(spacing: 8) {
                    Text("\(ByteCountFormatter.string(fromByteCount: appState.totalDuplicateSize, countStyle: .file))")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Potential Waste")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                Text("Scan Completed")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundColor(.primary)
                
                Text("We found duplicates in \(appState.scannedFolderCount) folders.")
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Button(action: { appState.reset() }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation {
                            appState.scanState = .completed
                        }
                    }) {
                        Text("Review Duplicates")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 60)
        }
    }
}
