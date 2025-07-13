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
    // Adjustable light intensities
    constexpr float cameraLightIntensity = 0.7;
    constexpr float backLightIntensity = 0.2;  // stronger rim/back light
    constexpr float ambient = 0.4;              // raise ambient for less black shadows
    constexpr float bottomShadowStrength = 0.1; // reduce bottom shadow darkness

    float3 normal = normalize(in.worldNormal);
    float3 viewDir = normalize(uniforms.cameraPosition - in.worldPosition);
    
    float3 viewRight = normalize(cross(float3(0, 1, 0), viewDir));
    float3 viewUp = cross(viewDir, viewRight);
    
    float3 keyLightDir = viewDir;
    float keyLight = max(0.0, dot(normal, keyLightDir));
    
    float3 fillLightDir = normalize(-viewDir + viewUp * 0.3);
    float fillLight = max(0.0, dot(normal, fillLightDir));
    
    float3 backLightDir = normalize(-viewDir + viewUp * 0.6);
    float backLight = max(0.0, dot(normal, backLightDir));
    
    float3 bottomLightDir = float3(0.0, -1.0, 0.0);
    float bottomLight = dot(normal, bottomLightDir);
    bottomLight = bottomLight > 0.0 ? 0.0 : bottomLight;
    
    float totalLight = ambient +
                       keyLight * cameraLightIntensity +
                       fillLight * 0.25 +
                       backLight * backLightIntensity;
    
    totalLight += bottomLight * bottomShadowStrength;
    
    totalLight = clamp(totalLight, 0.3, 1.0);
    
    float4 litColor = in.color * totalLight;
    litColor.a = in.color.a;
    return litColor;
}

