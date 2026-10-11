// Offscreen regression: synthetic stripes only; no screen recording.
import Foundation
import Metal
import simd
@main
struct MetalSymmetryCheck {
static func main() throws {
let device = MTLCreateSystemDefaultDevice()!
let queue = device.makeCommandQueue()!
let w = 2940, h = 1912, pad = 240
let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: w + 2*pad, height: h + 2*pad, mipmapped: true)
desc.usage = [.shaderRead, .shaderWrite, .renderTarget]
desc.storageMode = .shared
let picture = device.makeTexture(descriptor: desc)!
var pixels = [UInt8](repeating: 0, count: desc.width*desc.height*4)
for y in 0..<desc.height {
    for x in 0..<desc.width {
        let inside = x >= pad && x < pad+w && y >= pad && y < pad+h
        let distance = min(x-pad, pad+w-1-x)
        let value: UInt8 = inside ? (distance % 64 < 32 ? 255 : 0) : 0
        let at=(y*desc.width+x)*4
        pixels[at]=value; pixels[at+1]=value; pixels[at+2]=value; pixels[at+3]=255
    }
}
picture.replace(region: MTLRegionMake2D(0, 0, desc.width, desc.height), mipmapLevel: 0, withBytes: pixels, bytesPerRow: desc.width*4)
let commands = queue.makeCommandBuffer()!
let library = try device.makeLibrary(source: DepthShaders.source, options: nil)
let pyramid = try CenteredGaussianPyramid(device: device, library: library)
let built = pyramid.encode(texture: picture, commands: commands)
commands.commit(); commands.waitUntilCompleted()
precondition(built && commands.status == .completed)
print("Pyramid GPU \((commands.gpuEndTime - commands.gpuStartTime) * 1000) ms")
let pipelineDesc = MTLRenderPipelineDescriptor()
pipelineDesc.vertexFunction = library.makeFunction(name: "depthVertex")
pipelineDesc.fragmentFunction = library.makeFunction(name: "depthFragment")
pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
let pipeline = try device.makeRenderPipelineState(descriptor: pipelineDesc)
struct Uniforms { var c0,c1,c2,screen,padded,shape,light: SIMD4<Float> }
let outputDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: w, height: h, mipmapped: false)
outputDesc.storageMode = .shared; outputDesc.usage = [.renderTarget]
let output = device.makeTexture(descriptor: outputDesc)!
for strength: Float in [0, 0.1, 0.4, 1] {
    var uniforms = Uniforms(c0: SIMD4(1,0,0,0), c1: SIMD4(0,1,0,0), c2: SIMD4(0,0,1,0), screen: SIMD4(Float(w)/2,Float(h)/2,-120,-120), padded: SIMD4(Float(desc.width)/2,Float(desc.height)/2,320,strength), shape: SIMD4(1,0,2,Float(picture.mipmapLevelCount-1)), light: SIMD4(0,0,1,0))
    let cmd = queue.makeCommandBuffer()!
    let pass = MTLRenderPassDescriptor(); pass.colorAttachments[0].texture = output; pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
    let encoder=cmd.makeRenderCommandEncoder(descriptor: pass)!
    encoder.setRenderPipelineState(pipeline); encoder.setFragmentTexture(picture,index: 0); encoder.setFragmentBytes(&uniforms,length: MemoryLayout<Uniforms>.stride,index: 0); encoder.drawPrimitives(type: .triangle,vertexStart: 0,vertexCount: 3); encoder.endEncoding(); cmd.commit(); cmd.waitUntilCompleted()
    precondition(cmd.status == .completed)
    var bytes=[UInt8](repeating: 0,count: w*h*4)
    output.getBytes(&bytes, bytesPerRow: w*4, from: MTLRegionMake2D(0,0,w,h), mipmapLevel: 0)
    var sum=0, maximum=0
    for x in 0..<w/2 { let difference=abs(Int(bytes[(h/2*w+x)*4])-Int(bytes[(h/2*w+w-1-x)*4])); sum+=difference;maximum=max(maximum,difference) }
    for y in stride(from: 0, to: h/2, by: 32) {
        for x in stride(from: 0, to: w, by: 32) {
            maximum = max(maximum, abs(Int(bytes[(y*w+x)*4]) - Int(bytes[((h-1-y)*w+x)*4])))
        }
    }
    if strength == 1 {
        let interior = (w/3..<2*w/3).map { Int(bytes[(h/2*w+$0)*4]) }
        precondition(interior.max()! - interior.min()! < 8, "strong blur leaves the test stripes sharp")
    }
    precondition(maximum <= 2, "blur loses horizontal symmetry")
    print("GPU \((cmd.gpuEndTime - cmd.gpuStartTime) * 1000) ms")
    print("strength \(strength): mean left/right difference \(Double(sum)/Double(w/2)), max \(maximum), edges \(bytes[(h/2*w+120)*4]) / \(bytes[(h/2*w+w-1-120)*4])")
}

}
}
