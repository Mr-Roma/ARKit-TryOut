//
//  CustomARView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 29/05/25.
//


import ARKit
import Combine
import SwiftUI
import RealityKit
import UIKit // Import UIKit for UIImage

class CustomARView: ARView {
    private var bodyAnchor: ARBodyAnchor?
    private var bodyIndicator: ModelEntity?
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    dynamic required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This is the init that we will actually use
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
        
        subscribeToActionStream()
        setupARSession()
        addTapGesture()
        addPinchGesture()
        addRotationGesture()
        addPanGesture()
        
        // Set up session delegate
        session.delegate = self
    }
    
    private var cancellables: Set<AnyCancellable> = []
    private var selectedColor: Color = .blue // Default color
    private var selectedEntity: ModelEntity? = nil
    var onCapture: ((UIImage) -> Void)?
    
    // Gesture recognizer
    private func addPinchGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        self.addGestureRecognizer(pinchGesture)
    }
    
    private func addRotationGesture() {
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        self.addGestureRecognizer(rotationGesture)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let entity = selectedEntity else { return }
        
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            entity.scale *= SIMD3<Float>(repeating: scale)
            gesture.scale = 1.0
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let entity = selectedEntity else { return }
        
        if gesture.state == .changed {
            // Rotate around Y-axis (up/down)
            let rotation = simd_quatf(angle: Float(gesture.rotation), axis: SIMD3<Float>(0, 1, 0))
            entity.orientation = rotation * entity.orientation
            
            // Reset the gesture rotation
            gesture.rotation = 0
        }
    }
    
    // Add pan gesture for Z-axis rotation
    private func addPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let entity = selectedEntity else { return }
        
        if gesture.state == .changed {
            let translation = gesture.translation(in: self)
            let rotationAngle = Float(translation.x) * 0.01 // Adjust sensitivity as needed
            
            // Rotate around Z-axis
            let rotation = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 0, 1))
            entity.orientation = rotation * entity.orientation
            
            // Reset the gesture translation
            gesture.setTranslation(.zero, in: self)
        }
    }
    
    func setupARSession() {
        let configuration = ARBodyTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        
        session.run(configuration)
    }
    
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        
        // First check if we tapped on an existing entity
        if let entity = entity(at: location) as? ModelEntity {
            selectedEntity = entity
            return
        }
        
        // Get the currently selected tattoo image from ARManager
        guard let tattooImage = ARManager.shared.selectedTattooImage else {
            print("No tattoo image selected.")
            return
        }
        
        // Get the body anchor if available
        if let bodyAnchor = session.currentFrame?.anchors.first(where: { $0 is ARBodyAnchor }) as? ARBodyAnchor {
            // Get the position of the body part we want to place the tattoo on
            let bodyPosition = bodyAnchor.transform.translation
            
            // Create a ray from the tap location
            let ray = raycast(from: location, allowing: .estimatedPlane, alignment: .any)
            if let result = ray.first {
                // Use the hit position for more accurate placement
                placeTattooAt(position: result.worldTransform.translation, image: tattooImage)
            } else {
                // Fallback to body position if raycast fails
                placeTattooAt(position: bodyPosition, image: tattooImage)
            }
        } else {
            // Fallback to placing in front of camera if no body is detected
            placeTattooInFrontOfCamera(image: tattooImage)
        }
    }
    
    func raycastToPlane(from screenPoint: CGPoint) -> ARRaycastResult? {
        let results = raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .horizontal)
        return results.first
    }
    
    func placeBlockAt(position: SIMD3<Float>, color: Color) {
        let block = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: UIColor(color), isMetallic: false)
        let entity = ModelEntity(mesh: block, materials: [material])
        
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        
        scene.addAnchor(anchor)
        selectedEntity = entity
    }
    
    func placeBlockInFrontOfCamera(color: Color) {
        let cameraTransform = cameraTransform
        let forwardDirection = -cameraTransform.matrix.columns.2
        let position = cameraTransform.translation + normalize(SIMD3<Float>(forwardDirection.x, forwardDirection.y, forwardDirection.z)) * 0.7
        
        placeBlockAt(position: position, color: color)
    }
    
    // New function to place a tattoo using UIImage
    func placeTattooAt(position: SIMD3<Float>, image: UIImage) {
        // Remove any existing tattoos
        scene.anchors.removeAll()
        
        // Create a plane for the tattoo (adjust size as needed)
        let plane = MeshResource.generatePlane(width: 0.2, height: 0.2) // Adjust size
        
        // Create material with the tattoo image
        let textureOptions = TextureResource.CreateOptions(semantic: .color)
        if let texture = try? TextureResource.generate(from: image.cgImage!, options: textureOptions) {
            var material = UnlitMaterial() // Use UnlitMaterial for transparency
            material.baseColor = MaterialColorParameter.texture(texture) // Correct way to assign texture
            // Transparency is handled by the texture's alpha channel with UnlitMaterial
            
            let entity = ModelEntity(mesh: plane, materials: [material])
            
            // Create anchor and add entity
            let anchor = AnchorEntity(world: position)
            
            // Add an offset to make the tattoo float above the surface
            entity.position = SIMD3<Float>(0, 0.1, 0) // 10cm up from the surface
            
            anchor.addChild(entity)
            scene.addAnchor(anchor)
            selectedEntity = entity
        }
    }
    
    // New function to place a tattoo in front of camera using UIImage
    func placeTattooInFrontOfCamera(image: UIImage) {
        let cameraTransform = cameraTransform
        let forwardDirection = -cameraTransform.matrix.columns.2
        let position = cameraTransform.translation + normalize(SIMD3<Float>(forwardDirection.x, forwardDirection.y, forwardDirection.z)) * 0.7
        
        placeTattooAt(position: position, image: image)
    }
    
    func subscribeToActionStream() {
        ARManager.shared
            .actionStream
            .sink { [weak self] action in
                switch action {
                    case .placeBlock(let color):
                        self?.selectedColor = color
                        
                    case .removeAllAnchors:
                        self?.scene.anchors.removeAll()
                        self?.selectedEntity = nil
                        
                    case .captureScreenshot:
                        self?.captureScreenshot()
                        
                    case .placeTattoo: // Handle the updated case
                        // Placement is now triggered by tap gesture using selected image from ARManager
                        break // No action needed here anymore
                }
            }
            .store(in: &cancellables)
    }
    
    private func captureScreenshot() {
        self.snapshot(saveToHDR: false) { image in
            if let image = image {
                self.onCapture?(image)
            }
        }
    }
    
    private func createBodyIndicator() -> ModelEntity {
        // Create a small sphere to indicate body detection
        let sphere = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: .green, isMetallic: false)
        let entity = ModelEntity(mesh: sphere, materials: [material])
        return entity
    }
    
    private func updateBodyIndicator(with anchor: ARBodyAnchor) {
        if bodyIndicator == nil {
            bodyIndicator = createBodyIndicator()
            scene.addAnchor(AnchorEntity(world: anchor.transform.translation))
            scene.anchors.first?.addChild(bodyIndicator!)
        }
        
        // Update position to follow the body
        if let indicator = bodyIndicator {
            scene.anchors.first?.position = anchor.transform.translation
        }
    }
    
    private func removeBodyIndicator() {
        if let indicator = bodyIndicator {
            indicator.removeFromParent()
            bodyIndicator = nil
        }
    }
}

// MARK: - ARSessionDelegate
extension CustomARView: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Check for body anchor updates
        if let bodyAnchor = anchors.first(where: { $0 is ARBodyAnchor }) as? ARBodyAnchor {
            self.bodyAnchor = bodyAnchor
            updateBodyIndicator(with: bodyAnchor)
        } else {
            removeBodyIndicator()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        removeBodyIndicator()
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        removeBodyIndicator()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Session interruption ended, but we don't need to do anything special here
        // as the session will automatically resume tracking
    }
}

// Extension to make working with transforms easier
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
