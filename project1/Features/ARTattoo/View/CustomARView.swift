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

class CustomARView: ARView {
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
    }
    
    private var cancellables: Set<AnyCancellable> = []
    private var selectedColor: Color = .blue // Default color
    private var selectedEntity: ModelEntity? = nil
    var onCapture: ((UIImage) -> Void)?
    private var selectedTattooImage: String? = "tattoo1"
    
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
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
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
        
        // If no entity was tapped, try to place a new one
        if let result = raycastToPlane(from: location) {
            if let tattooImage = selectedTattooImage {
                placeTattooAt(position: result.worldTransform.translation, imageName: tattooImage)
            } else {
                placeBlockAt(position: result.worldTransform.translation, color: selectedColor)
            }
        } else {
            if let tattooImage = selectedTattooImage {
                placeTattooInFrontOfCamera(imageName: tattooImage)
            } else {
                placeBlockInFrontOfCamera(color: selectedColor)
            }
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
    
    
    func placeTattooAt(position: SIMD3<Float>, imageName: String) {
        // Remove any existing tattoos
        scene.anchors.removeAll()
        
        // Create a plane for the tattoo
        let plane = MeshResource.generatePlane(width: 0.2, height: 0.2)
        
        // Create material with the tattoo image
        if let image = UIImage(named: imageName) {
            let textureOptions = TextureResource.CreateOptions(semantic: .color)
            if let texture = try? TextureResource.generate(from: image.cgImage!, options: textureOptions) {
                var material = SimpleMaterial()
                material.color = .init(tint: .white, texture: .init(texture))
                material.roughness = .init(floatLiteral: 0.5)
                material.metallic = .init(floatLiteral: 0.0)
                
                let entity = ModelEntity(mesh: plane, materials: [material])
                
                // Create anchor and add entity
                let anchor = AnchorEntity(world: position)
                
                // Set initial orientation to be horizontal and correct side up
                let horizontalRotation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
                entity.orientation = horizontalRotation
                
                anchor.addChild(entity)
                scene.addAnchor(anchor)
                selectedEntity = entity
            }
        }
    }
    
    func placeTattooInFrontOfCamera(imageName: String) {
        let cameraTransform = cameraTransform
        let forwardDirection = -cameraTransform.matrix.columns.2
        let position = cameraTransform.translation + normalize(SIMD3<Float>(forwardDirection.x, forwardDirection.y, forwardDirection.z)) * 0.7
        
        placeTattooAt(position: position, imageName: imageName)
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
                        
                    case .placeTattoo(let imageName):
                        self?.selectedTattooImage = imageName
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
}

// Extension to make working with transforms easier
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
