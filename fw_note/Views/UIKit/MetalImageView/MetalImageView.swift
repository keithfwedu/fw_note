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
        metalView.isPaused = false // Continuous redrawing for animations
        metalView.isOpaque = true // Prevent transparency to reduce blending overhead
        metalView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0) // Optimize clearing by removing alpha channel
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
        return Coordinator(targetSize: targetSize)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        private var device: MTLDevice?
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var textures: [MTLTexture] = []
        private var currentFrameIndex = 0
        private var frameDurations: [Double] = []
        private var timer: CADisplayLink?
        private var currentFrameStartTime: CFTimeInterval = 0.0
        private var elapsedTime: CFTimeInterval = 0.0
        private let targetSize: CGSize

        init(targetSize: CGSize) {
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()
            self.targetSize = targetSize

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

        func loadImage(path: String) {
            guard let device = self.device,
                  let cgImage = UIImage(contentsOfFile: path)?.cgImage else {
                print("Failed to load image at path: \(path)")
                return
            }

            let loader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [
                .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                .textureStorageMode: MTLStorageMode.private.rawValue
            ]

            do {
                textures = [try loader.newTexture(cgImage: cgImage, options: options)]
                timer?.invalidate()
            } catch {
                print("Failed to load texture: \(error)")
            }
        }

        func loadGIF(path: String) {
            guard let device = self.device,
                  let gifFrames = GIFDecoder.decodeGIF(from: path) else {
                print("Failed to load GIF frames")
                return
            }

            let loader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [.SRGB: false]

            self.textures = gifFrames.compactMap { (image, _) in
                guard let cgImage = image.cgImage else { return nil }
                return try? loader.newTexture(cgImage: cgImage, options: options)
            }

            self.frameDurations = gifFrames.map { $0.1 }
            startPlayback()
        }

        private func startPlayback() {
            guard !textures.isEmpty, !frameDurations.isEmpty else { return }

            timer?.invalidate()
            currentFrameIndex = 0
            currentFrameStartTime = CACurrentMediaTime()
            timer = CADisplayLink(target: self, selector: #selector(updateFrame))
            timer?.add(to: .main, forMode: .default)
        }

        @objc private func updateFrame() {
            guard !textures.isEmpty, !frameDurations.isEmpty else { return }

            let currentTime = CACurrentMediaTime()
            elapsedTime = currentTime - currentFrameStartTime

            let currentFrameDuration = frameDurations[currentFrameIndex]

            if elapsedTime >= currentFrameDuration {
                currentFrameIndex = (currentFrameIndex + 1) % textures.count
                currentFrameStartTime = currentTime
                elapsedTime = 0.0
            }
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

        func releaseResources() {
            textures.removeAll() // Clear texture references
            frameDurations.removeAll() // Remove frame duration data
            timer?.invalidate() // Stop timer to prevent unnecessary updates
            commandQueue = nil // Release Metal command queue
            pipelineState = nil // Release render pipeline state
        }
    }
}

    

 


       


  
