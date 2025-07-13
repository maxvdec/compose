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
    
    float3 cameraDir = normalize(uniforms.cameraPosition - in.worldPosition);
    
    float3 keyLightDir = normalize(cameraDir + float3(0.3, 0.5, 0.2));
    float keyLight = max(0.0, dot(normal, keyLightDir));
    
    float3 fillLightDir = normalize(cameraDir + float3(-0.5, 0.2, 0.3));
    float fillLight = max(0.0, dot(normal, fillLightDir)) * 0.4;
    
    float3 rimLightDir = normalize(cameraDir + float3(0.0, 0.0, -1.0));
    float rimLight = max(0.0, dot(normal, rimLightDir)) * 0.3;
    
    float cameraLight = max(0.2, dot(normal, cameraDir)) * 0.6;
    
    float ambient = 0.3;
    
    float totalLight = ambient + keyLight * 0.8 + fillLight + rimLight + cameraLight;
    totalLight = min(1.0, totalLight);
    
    float4 litColor = in.color * totalLight;
    litColor.a = in.color.a;
    
    return litColor;
}
