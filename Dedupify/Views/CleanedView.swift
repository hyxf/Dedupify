//
//  CleanedView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct CleanedView: View {
    @EnvironmentObject var appState: AppState
    var namespace: Namespace.ID
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow.opacity(0.8))
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("Cleanup Complete")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white)
                
                Text("You just recovered \(ByteCountFormatter.string(fromByteCount: appState.cleanedSize, countStyle: .file)) of space.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Items have been moved to the Trash.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                Button(action: { appState.reset() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 60)
        }
    }
}
