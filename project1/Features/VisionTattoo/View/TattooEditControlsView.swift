//
//  TattooEditControlsView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 02/06/25.
//

import SwiftUI

struct TattooEditControlsView: View {
    @Binding var activeMode: EditMode?
    @Binding var tattooOpacity: Double
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                // Single edit button that activates all gestures
                Button(action: {
                    if activeMode == .wrap {
                        activeMode = .move
                    } else {
                        activeMode = activeMode == nil ? .move : nil
                    }
                }) {
                    HStack {
                        Image(systemName: "hand.tap")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(activeMode == nil ? "Edit" : "Done")
                            .font(.caption)
                    }
                    .padding(10)
                    .background(activeMode != nil && activeMode != .wrap ? Color.blue : Color.white)
                    .foregroundColor(activeMode != nil && activeMode != .wrap ? .white : .black)
                    .cornerRadius(5)
                }
                
                // Opacity button
                Button(action: {
                    if activeMode == .wrap {
                        activeMode = .opacity
                    } else {
                        activeMode = activeMode == .opacity ? nil : .opacity
                    }
                }) {
                    Image(systemName: "circle.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(activeMode == .opacity ? Color.blue : Color.white)
                        .foregroundColor(activeMode == .opacity ? .white : .black)
                        .cornerRadius(5)
                }
                
                // Wrap button
                Button(action: {
                    activeMode = activeMode == .wrap ? nil : .wrap
                }) {
                    Image(systemName: "network")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(activeMode == .wrap ? Color.blue : Color.white)
                        .foregroundColor(activeMode == .wrap ? .white : .black)
                        .cornerRadius(5)
                }
            }
            
            // Show opacity slider only when opacity mode is active
            if activeMode == .opacity {
                VStack(spacing: 5) {
                    Text("Tattoo Opacity: \(Int(tattooOpacity * 100))%")
                        .font(.caption)
                    Slider(value: $tattooOpacity, in: 0...1, step: 0.01)
                        .frame(width: 200)
                }
                .padding(.vertical, 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

#Preview {
    TattooEditControlsView(activeMode: .constant(.move), tattooOpacity: .constant(1.0))
} 
