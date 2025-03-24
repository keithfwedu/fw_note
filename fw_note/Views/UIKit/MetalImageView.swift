import SwiftUI
import MetalKit
import ImageIO

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
        metalView.isPaused = false // Ensure the view is continuously redrawn
        metalView.isOpaque = false // Allow transparency
        metalView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0) // Fully transparent background
        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        if imagePath.lowercased().hasSuffix(".gif") {
            context.coordinator.loadGIF(path: imagePath)
        } else {
            context.coordinator.loadImage(path: imagePath)
        }
        uiView.setNeedsDisplay() // Trigger redraw
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject, MTKViewDelegate {
        private var device: MTLDevice?
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var textures: [MTLTexture] = []
        private var currentFrameIndex = 0
        private var frameDurations: [Double] = []
        private var timer: CADisplayLink?

        override init() {
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()

            if let device = self.device {
                let pipelineDescriptor = MTLRenderPipelineDescriptor()
                pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // Support alpha transparency
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true // Enable blending
                pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

                pipelineDescriptor.vertexFunction = device.makeDefaultLibrary()?.makeFunction(name: "vertex_main")
                pipelineDescriptor.fragmentFunction = device.makeDefaultLibrary()?.makeFunction(name: "fragment_main")

                do {
                    pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                } catch {
                    print("Failed to create pipeline state: \(error)")
                }
            }
        }

        func loadImage(path: String) {
            guard let device = self.device,
                  let cgImage = UIImage(contentsOfFile: path)?.cgImage else {
                print("Failed to load image at path: \(path)")
                return
            }

            let loader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [
                .SRGB: false,
                .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                .textureStorageMode: MTLStorageMode.private.rawValue
            ]

            do {
                textures = [try loader.newTexture(cgImage: cgImage, options: options)]
                timer?.invalidate() // Stop any running GIF playback
            } catch {
                print("Failed to load texture: \(error)")
            }
        }
        
        func loadGIF(path: String) {
            guard let device = self.device,
                let gifFrames = GIFDecoder.decodeGIF(from: path)
            else {
                print("Failed to load GIF frames")
                return
            }

            let loader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [
                .SRGB: false
            ]

            self.textures = gifFrames.compactMap { (image, _) in
                guard let cgImage = image.cgImage else { return nil }
                return try? loader.newTexture(
                    cgImage: cgImage, options: options)
            }

            self.frameDurations = gifFrames.map { $0.1 }
            startPlayback()
        }
        
        
        private func startPlayback() {
            guard !textures.isEmpty, !frameDurations.isEmpty else { return }

            timer?.invalidate()  // Stop any previous timer
            timer = CADisplayLink(
                target: self, selector: #selector(updateFrame))
            timer?.add(to: .main, forMode: .default)
        }

        @objc private func updateFrame() {
            currentFrameIndex = (currentFrameIndex + 1) % textures.count
        }
        
        

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let texture = textures.isEmpty ? nil : textures[currentFrameIndex],
                  let commandQueue = commandQueue,
                  let pipelineState = pipelineState else {
                return
            }

            let commandBuffer = commandQueue.makeCommandBuffer()
            let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.setRenderPipelineState(pipelineState)
            encoder?.setFragmentTexture(texture, index: 0)

            encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

            encoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle view size changes
        }
    }
}


    

 


       


  
