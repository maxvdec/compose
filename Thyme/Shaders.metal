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
    float3 normals [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float3 worldPosition;
    float3 worldNormal;
};

struct Uniforms {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
    float3 cameraPosition;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    
    float4 worldPos = uniforms.model * float4(in.position, 1.0);
    out.worldPosition = worldPos.xyz;
    
    float4x4 mvp = uniforms.projection * uniforms.view * uniforms.model;
    out.position = mvp * float4(in.position, 1.0);
    
    float3x3 normalMatrix = float3x3(uniforms.model[0].xyz, uniforms.model[1].xyz, uniforms.model[2].xyz);
    out.worldNormal = normalize(normalMatrix * in.normals);
    
    out.color = in.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant Uniforms& uniforms [[buffer(1)]]) {
    float3 normal = normalize(in.worldNormal);
    
    float3 viewDir = normalize(uniforms.cameraPosition - in.worldPosition);
    
    float3 viewRight = normalize(cross(float3(0, 1, 0), viewDir));
    float3 viewUp = cross(viewDir, viewRight);
    
    // Main key light (camera direction + slight offset up and right)
    float3 keyLightDir = normalize(viewDir + viewUp * 0.3 + viewRight * 0.2);
    float keyLight = max(0.0, dot(normal, keyLightDir));
    
    // Fill light (camera direction + offset left and slightly up)
    float3 fillLightDir = normalize(viewDir + viewUp * 0.1 - viewRight * 0.4);
    float fillLight = max(0.0, dot(normal, fillLightDir));
    
    // Back light (opposite to camera with slight up offset for rim)
    float3 backLightDir = normalize(-viewDir + viewUp * 0.2);
    float backLight = max(0.0, dot(normal, backLightDir));
    
    // Bottom light (camera direction + downward offset)
    float3 bottomLightDir = normalize(viewDir - viewUp * 0.5);
    float bottomLight = max(0.0, dot(normal, bottomLightDir));
    
    // Direct camera light (ensures front faces are always lit)
    float cameraLight = max(0.0, dot(normal, viewDir));
    
    float totalLight = 0 +
                      keyLight * 0.6 +
                      fillLight * 0.4 +
                      backLight * 0.2 +
                      bottomLight * 0.2 +
                      cameraLight * 0.4;
    
    totalLight = min(1.0, totalLight);
    
    float4 litColor = in.color * totalLight;
    litColor.a = in.color.a;
    
    return litColor;
}
