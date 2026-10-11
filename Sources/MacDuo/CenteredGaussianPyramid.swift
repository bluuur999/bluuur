// Modified for bluuur 2.0.2: preserve the image centre at every blur level.
import Metal

struct CenteredGaussianPyramid {
    private let pipeline: MTLRenderPipelineState

    init(device: MTLDevice, library: MTLLibrary) throws {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "depthVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "pyramidFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func encode(texture: MTLTexture, commands: MTLCommandBuffer) -> Bool {
        for level in 1..<texture.mipmapLevelCount {
            guard let source = texture.makeTextureView(pixelFormat: texture.pixelFormat,
                textureType: .type2D, levels: (level - 1)..<level, slices: 0..<1) else { return false }
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = texture
            pass.colorAttachments[0].level = level
            pass.colorAttachments[0].loadAction = .dontCare
            pass.colorAttachments[0].storeAction = .store
            guard let encoder = commands.makeRenderCommandEncoder(descriptor: pass) else { return false }
            var size = SIMD2<Float>(Float(max(1, texture.width >> level)), Float(max(1, texture.height >> level)))
            encoder.setRenderPipelineState(pipeline)
            encoder.setFragmentTexture(source, index: 0)
            encoder.setFragmentBytes(&size, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        }
        return true
    }
}
