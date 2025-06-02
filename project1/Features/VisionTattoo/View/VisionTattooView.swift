//
//  VisionTattooView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 02/06/25.
//
import SwiftUI
import PhotosUI // Import PhotosUI
import UIKit // Import UIKit for UIImage
import Vision // Import Vision framework
import CoreImage
import CoreImage.CIFilterBuiltins



struct VisionTattooView : View {
    @ObservedObject var arManager = ARManager.shared
    
    @State private var selectedTattooName: String?
    @State private var bodyUIImage: UIImage?
    @State private var tattooUIImage: UIImage?
    
    @State private var selectedBodyImageItem: PhotosPickerItem?
    @State private var showingTattooPicker = false
    @State private var blendedResult: CIImage?
    @State private var blendedUIImage: UIImage?
    @State private var finalBlendedImage: UIImage?
    
    // State for tattoo transformations
    @State private var tattooPosition: CGPoint = .zero
    @State private var tattooScale: CGFloat = 1.0
    @State private var tattooRotation: Angle = .zero
    @State private var tattooOpacity: Double = 1.0
    
    // State for active editing mode
    @State private var activeMode: EditMode? = nil
    @State private var lastDragPosition: CGPoint = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Angle = .zero
    @State private var baseScale: CGFloat = 1.0
    @State private var controlPoints: [CGPoint] = []
    @State private var selectedPoint: Int? = nil
    
    private func calculateTranslation(from value: DragGesture.Value) -> CGPoint {
        let rotation = -tattooRotation.radians
        let dx = value.location.x - lastDragPosition.x
        let dy = value.location.y - lastDragPosition.y
        
        // Apply rotation matrix to the translation
        let rotatedDx = dx * Foundation.cos(rotation) - dy * Foundation.sin(rotation)
        let rotatedDy = dx * Foundation.sin(rotation) + dy * Foundation.cos(rotation)
        
        // Adjust translation based on scale
        let scaleFactor = 1.0 / tattooScale
        return CGPoint(
            x: rotatedDx * scaleFactor,
            y: rotatedDy * scaleFactor
        )
    }
    
    private func setupControlPoints() {
        if let image = tattooUIImage {
            let size = image.size
            // Calculate the corners of the tattoo image, taking into account the scale and rotation
            let halfWidth = (size.width * tattooScale) / 2
            let halfHeight = (size.height * tattooScale) / 2
            
            // Calculate rotated corners
            let rotation = tattooRotation.radians
            let cos = cos(rotation)
            let sin = sin(rotation)
            
            // Calculate the corners with rotation
            let corners = [
                CGPoint(x: -halfWidth, y: -halfHeight),  // Top Left
                CGPoint(x: halfWidth, y: -halfHeight),   // Top Right
                CGPoint(x: halfWidth, y: halfHeight),    // Bottom Right
                CGPoint(x: -halfWidth, y: halfHeight)    // Bottom Left
            ]
            
            // Apply rotation and translation to each corner
            controlPoints = corners.map { corner in
                let rotatedX = corner.x * cos - corner.y * sin
                let rotatedY = corner.x * sin + corner.y * cos
                return CGPoint(
                    x: tattooPosition.x + rotatedX,
                    y: tattooPosition.y + rotatedY
                )
            }
        }
    }
    
    private func applyWarping() {
        guard let tattooImage = tattooUIImage else { return }
        
        let context = CIContext()
        let ciImage = CIImage(image: tattooImage)!
        
        // Create perspective transform filter
        let filter = CIFilter.perspectiveTransform()
        filter.inputImage = ciImage
        
        // Get the original image size
        let imageSize = tattooImage.size
        
        // Calculate the center point of the control points
        let centerX = (controlPoints[0].x + controlPoints[1].x + controlPoints[2].x + controlPoints[3].x) / 4
        let centerY = (controlPoints[0].y + controlPoints[1].y + controlPoints[2].y + controlPoints[3].y) / 4
        
        // Calculate the original corners (before warping)
        let halfWidth = (imageSize.width * tattooScale) / 2
        let halfHeight = (imageSize.height * tattooScale) / 2
        let originalCorners = [
            CGPoint(x: centerX - halfWidth, y: centerY - halfHeight),
            CGPoint(x: centerX + halfWidth, y: centerY - halfHeight),
            CGPoint(x: centerX + halfWidth, y: centerY + halfHeight),
            CGPoint(x: centerX - halfWidth, y: centerY + halfHeight)
        ]
        
        // Calculate the maximum allowed displacement (20% of the image size)
        let maxDisplacement = min(imageSize.width, imageSize.height) * 0.2
        
        // Calculate smoothed control points with limited displacement
        let smoothedPoints = zip(controlPoints, originalCorners).map { current, original in
            let dx = current.x - original.x
            let dy = current.y - original.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance > maxDisplacement {
                let scale = maxDisplacement / distance
                return CGPoint(
                    x: original.x + dx * scale,
                    y: original.y + dy * scale
                )
            }
            return current
        }
        
        // Convert to CIVector with relative coordinates
        let topLeft = CIVector(x: (smoothedPoints[0].x - centerX + halfWidth) / (imageSize.width * tattooScale) * imageSize.width,
                             y: (smoothedPoints[0].y - centerY + halfHeight) / (imageSize.height * tattooScale) * imageSize.height)
        let topRight = CIVector(x: (smoothedPoints[1].x - centerX + halfWidth) / (imageSize.width * tattooScale) * imageSize.width,
                              y: (smoothedPoints[1].y - centerY + halfHeight) / (imageSize.height * tattooScale) * imageSize.height)
        let bottomRight = CIVector(x: (smoothedPoints[2].x - centerX + halfWidth) / (imageSize.width * tattooScale) * imageSize.width,
                                 y: (smoothedPoints[2].y - centerY + halfHeight) / (imageSize.height * tattooScale) * imageSize.height)
        let bottomLeft = CIVector(x: (smoothedPoints[3].x - centerX + halfWidth) / (imageSize.width * tattooScale) * imageSize.width,
                                y: (smoothedPoints[3].y - centerY + halfHeight) / (imageSize.height * tattooScale) * imageSize.height)
        
        // Set the perspective transform points
        filter.setValue(topLeft, forKey: "inputTopLeft")
        filter.setValue(topRight, forKey: "inputTopRight")
        filter.setValue(bottomRight, forKey: "inputBottomRight")
        filter.setValue(bottomLeft, forKey: "inputBottomLeft")
        
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            // Create a new image with the same size as the original
            let newImage = UIImage(cgImage: cgImage)
            let renderer = UIGraphicsImageRenderer(size: imageSize)
            let finalImage = renderer.image { context in
                // Draw the warped image at the center
                newImage.draw(in: CGRect(origin: .zero, size: imageSize))
            }
            tattooUIImage = finalImage
        }
    }
    
    var body: some View {
        VStack {
            
            if bodyUIImage != nil {
                ZStack() {
                    if let finalImage = finalBlendedImage {
                        Image(uiImage: finalImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 500, height: 500)
                    } else {
                        Image(uiImage: bodyUIImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 500, height: 500)
                           
                        
                        if tattooUIImage != nil {
                            ZStack {
                                Image(uiImage: tattooUIImage!)
                                    .resizable()
                                    .scaledToFit()
                                    .position(tattooPosition)
                                    .scaleEffect(tattooScale)
                                    .rotationEffect(tattooRotation)
                                    .opacity(tattooOpacity)
                                
                                if activeMode == .wrap {
                                    ForEach(0..<controlPoints.count, id: \.self) { index in
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 15, height: 15)
                                            .position(controlPoints[index])
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        controlPoints[index] = value.location
                                                        applyWarping()
                                                    }
                                            )
                                    }
                                }
                            }
                            .onChange(of: tattooPosition) { _ in
                                if activeMode == .wrap {
                                    setupControlPoints()
                                }
                            }
                            .onChange(of: tattooScale) { _ in
                                if activeMode == .wrap {
                                    setupControlPoints()
                                }
                            }
                            .onChange(of: tattooRotation) { _ in
                                if activeMode == .wrap {
                                    setupControlPoints()
                                }
                            }
                            .onChange(of: activeMode) { newMode in
                                if newMode == .wrap {
                                    setupControlPoints()
                                }
                            }
                            .gesture(
                                SimultaneousGesture(
                                    SimultaneousGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if activeMode != nil && activeMode != .wrap {
                                                    if lastDragPosition == .zero {
                                                        lastDragPosition = value.location
                                                    }
                                                    let translation = calculateTranslation(from: value)
                                                    tattooPosition = CGPoint(
                                                        x: tattooPosition.x + translation.x,
                                                        y: tattooPosition.y + translation.y
                                                    )
                                                    lastDragPosition = value.location
                                                }
                                            }
                                            .onEnded { _ in
                                                lastDragPosition = .zero
                                            },
                                        MagnificationGesture()
                                            .onChanged { value in
                                                if activeMode != nil && activeMode != .wrap {
                                                    if lastScale == 1.0 {
                                                        lastScale = value
                                                    }
                                                    let newScale = tattooScale * (value / lastScale)
                                                    tattooScale = min(max(newScale, 0.1), 5.0)
                                                    lastScale = value
                                                }
                                            }
                                            .onEnded { _ in
                                                lastScale = 1.0
                                            }
                                    ),
                                    RotationGesture()
                                        .onChanged { value in
                                            if activeMode != nil && activeMode != .wrap {
                                                if lastRotation == .zero {
                                                    lastRotation = tattooRotation
                                                }
                                                tattooRotation = lastRotation + value
                                            }
                                        }
                                        .onEnded { _ in
                                            lastRotation = tattooRotation
                                        }
                                )
                            )
                        }
                    }
                    
            
                }
                .gesture(
                    SimultaneousGesture(
                        SimultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if activeMode != nil {
                                        if lastDragPosition == .zero {
                                            lastDragPosition = value.location
                                        }
                                        let translation = calculateTranslation(from: value)
                                        tattooPosition = CGPoint(
                                            x: tattooPosition.x + translation.x,
                                            y: tattooPosition.y + translation.y
                                        )
                                        lastDragPosition = value.location
                                    }
                                }
                                .onEnded { _ in
                                    lastDragPosition = .zero
                                },
                            MagnificationGesture()
                                .onChanged { value in
                                    if activeMode != nil {
                                        if lastScale == 1.0 {
                                            lastScale = value
                                        }
                                        let newScale = tattooScale * (value / lastScale)
                                        tattooScale = min(max(newScale, 0.1), 5.0)
                                        lastScale = value
                                    }
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        ),
                        RotationGesture()
                            .onChanged { value in
                                if activeMode != nil {
                                    if lastRotation == .zero {
                                        lastRotation = tattooRotation
                                    }
                                    tattooRotation = lastRotation + value
                                }
                            }
                            .onEnded { _ in
                                lastRotation = tattooRotation
                            }
                    )
                )

                
            }
            
            Spacer()
            
            TattooEditControlsView(activeMode: $activeMode, tattooOpacity: $tattooOpacity)
            
            HStack {
                Button(action: {showingTattooPicker.toggle()}){
                    Text("Choose Tattoo")
                }
                .sheet(isPresented: $showingTattooPicker, content:  {
                    ShowingTattooView(activeMode: $activeMode)
                })
                .onChange(of: arManager.selectedTattooImage) { newImage in
                    tattooUIImage = newImage
                    // Reset transformations
                    tattooPosition = CGPoint(x: 250, y: 250) // Center of the 500x500 frame
                    tattooScale = 1.0
                    tattooRotation = .zero
                    setupControlPoints()
                }
                // PhotosPicker for inputting the body image
                PhotosPicker(selection: $selectedBodyImageItem, matching: .images) {
                    Text("Input Body Image")
                }
                .onChange(of: selectedBodyImageItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                bodyUIImage = uiImage
                                if tattooUIImage != nil {
                                    
                                }
                                if activeMode == .opacity {
                                    selectedTattooName = nil
                                }
                            }
                        } else {
                            selectedTattooName = nil
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    finalBlendedImage = TattooImageUtils.shared.performBlending(
                        bodyImage: bodyUIImage,
                        tattooImage: tattooUIImage
                    )
                }) {
                    Text("Process Blend")
                }
                .padding(10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(5)
            }
        }
        .navigationTitle("Vision Tattoo")
    }
}

#Preview {
    VisionTattooView()
}
