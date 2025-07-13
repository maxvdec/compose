//
//  Shaders.metal
//  Thyme
//
//  Created by Max Van den Eynde on 12/7/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    float4x4 mvp = uniforms.projection * uniforms.view * uniforms.model;
    out.position = mvp * float4(in.position, 1.0);
    out.color = in.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
