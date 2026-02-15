//
//  NoResultsView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct NoResultsView: View {
    @EnvironmentObject var appState: AppState
    var namespace: Namespace.ID
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.6), lineWidth: 4)
                    .frame(width: 280, height: 280)
                    .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                
                VStack(spacing: 16) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.green)
                    
                    Text("All Clean")
                        .font(.title2)
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("No Duplicates Found")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)
                
                Text("Your folders are organized and clutter-free.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
                
                Button(action: { appState.reset() }) {
                    Text("Start Over")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 60)
        }
    }
}
