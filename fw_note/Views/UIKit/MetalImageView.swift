//
//  MetalImageView.swift
//  fw_note
//
//  Created by Fung Wing on 24/3/2025.
//

import SwiftUI
import MetalKit

struct MetalImageView: UIViewRepresentable {
    let imagePath: String
    let targetSize: CGSize

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }

        let metalView = MTKView(frame: .zero, device: device)
        metalView.delegate = context.coordinator
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        metalView.clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0) // Non-black clear color for debugging
        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.loadImage(path: imagePath, size: targetSize)
        uiView.setNeedsDisplay() // Trigger a redraw
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject, MTKViewDelegate {
        private var device: MTLDevice?
        private var commandQueue: MTLCommandQueue?
        private var texture: MTLTexture?
        private var pipelineState: MTLRenderPipelineState?

        override init() {
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()

            // Initialize a basic pipeline state
            if let device = self.device {
                let pipelineDescriptor = MTLRenderPipelineDescriptor()
                pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                pipelineDescriptor.vertexFunction = device.makeDefaultLibrary()?.makeFunction(name: "vertex_main")
                pipelineDescriptor.fragmentFunction = device.makeDefaultLibrary()?.makeFunction(name: "fragment_main")

                do {
                    pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                } catch {
                    print("Failed to create pipeline state: \(error)")
                }
            }
        }

        func loadImage(path: String, size: CGSize) {
            guard let device = self.device,
                  let cgImage = UIImage(contentsOfFile: path)?.cgImage else {
                print("Failed to load image at path: \(path)")
                return
            }

            let loader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [
                .SRGB: false,
                .generateMipmaps: true
            ]

            do {
                texture = try loader.newTexture(cgImage: cgImage, options: options)
            } catch {
                print("Failed to create texture: \(error)")
            }
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let texture = texture,
                  let commandQueue = commandQueue,
                  let pipelineState = pipelineState else {
                return
            }

            let commandBuffer = commandQueue.makeCommandBuffer()
            let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.setRenderPipelineState(pipelineState)
            encoder?.setFragmentTexture(texture, index: 0)

            // Draw a full-screen quad (2 triangles)
            encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

            encoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle view size changes here
        }
    }
}
