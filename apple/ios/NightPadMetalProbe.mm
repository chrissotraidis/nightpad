#import "NightPadMetalProbe.h"

#import <Metal/Metal.h>

#include <vector>

static NSString *Fail(NSString *message) {
  return message;
}

NSString *NightPadRunMetalProbe(void) {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  if (device == nil) {
    return Fail(@"Metal device unavailable");
  }
  id<MTLCommandQueue> queue = [device newCommandQueue];
  if (queue == nil) {
    return Fail(@"Metal command queue unavailable");
  }

  NSString *source =
      @"#include <metal_stdlib>\n"
       "using namespace metal;\n"
       "kernel void nightpad_fixture(device uint *result [[buffer(0)]],\n"
       "                             texture2d<float, access::write> output [[texture(0)]],\n"
       "                             uint2 id [[thread_position_in_grid]]) {\n"
       "  float4 color = float4(float(id.x) / 31.0, float(id.y) / 31.0, 0.25, 1.0);\n"
       "  output.write(color, id);\n"
       "  if (id.x == 13 && id.y == 7) result[0] = 0x4e503732u;\n"
       "}\n";
  NSError *error = nil;
  id<MTLLibrary> library = [device newLibraryWithSource:source options:nil error:&error];
  if (library == nil) {
    return Fail([NSString stringWithFormat:@"MSL compile failed: %@", error.localizedDescription]);
  }
  id<MTLFunction> function = [library newFunctionWithName:@"nightpad_fixture"];
  id<MTLComputePipelineState> pipeline = function
      ? [device newComputePipelineStateWithFunction:function error:&error]
      : nil;
  if (pipeline == nil) {
    return Fail([NSString stringWithFormat:@"compute pipeline failed: %@", error.localizedDescription]);
  }

  MTLTextureDescriptor *descriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                          width:32
                                                         height:32
                                                      mipmapped:NO];
  descriptor.usage = MTLTextureUsageShaderWrite;
  descriptor.storageMode = MTLStorageModeShared;
  id<MTLTexture> output = [device newTextureWithDescriptor:descriptor];
  id<MTLBuffer> result = [device newBufferWithLength:sizeof(uint32_t)
                                             options:MTLResourceStorageModeShared];
  if (output == nil || result == nil) {
    return Fail(@"Metal resources unavailable");
  }

  id<MTLCommandBuffer> command = [queue commandBuffer];
  id<MTLComputeCommandEncoder> encoder = [command computeCommandEncoder];
  [encoder setComputePipelineState:pipeline];
  [encoder setTexture:output atIndex:0];
  [encoder setBuffer:result offset:0 atIndex:0];
  [encoder dispatchThreads:MTLSizeMake(32, 32, 1)
      threadsPerThreadgroup:MTLSizeMake(8, 8, 1)];
  [encoder endEncoding];
  [command commit];
  [command waitUntilCompleted];
  if (command.status != MTLCommandBufferStatusCompleted) {
    return Fail([NSString stringWithFormat:@"Metal command failed: %@", command.error.localizedDescription]);
  }
  uint32_t *sentinel = (uint32_t *)result.contents;
  if (sentinel[0] != 0x4e503732u) {
    return Fail([NSString stringWithFormat:@"readback sentinel mismatch: 0x%08x", sentinel[0]]);
  }

  std::vector<uint8_t> pixels(32 * 32 * 4);
  [output getBytes:pixels.data()
       bytesPerRow:32 * 4
        fromRegion:MTLRegionMake2D(0, 0, 32, 32)
       mipmapLevel:0];
  if (pixels[(7 * 32 + 13) * 4 + 2] != 64) {
    return Fail(@"texture readback color mismatch");
  }
  return nil;
}

