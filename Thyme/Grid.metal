//
//  Grid.metal
//  Thyme
//
//  Created by Max Van den Eynde on 13/7/25.
//

#include <metal_stdlib>
using namespace metal;

struct GridOut {
    float4 position [[position]];
    float2 screenPos;
};

struct GridUniforms {
    float4x4 invViewProjection;  // inverse of view*proj
    float3   cameraPos;          // world-space camera position
    float    gridSpacing;        // e.g. 1.0
    float    fadeStart;          // distance at which grid is fully opaque
    float    fadeEnd;            // distance at which grid is fully faded
};

// Vertex: emit full-screen quad
vertex GridOut grid_vertex(uint vid [[vertex_id]],
                          constant GridUniforms& u [[buffer(0)]])
{
    float2 ndc = float2((vid & 1) ? +1 : -1,
                       (vid & 2) ? +1 : -1);

    GridOut out;
    out.position = float4(ndc, 0, 1);
    out.screenPos = ndc;
    
    return out;
}

// Helper function to compute grid lines
float grid(float2 pos, float spacing) {
    float2 grid = abs(fract(pos / spacing - 0.5) - 0.5) / fwidth(pos / spacing);
    float line = min(grid.x, grid.y);
    return 1.0 - min(line, 1.0);
}

// Fragment: intersect with y=0, draw grid
fragment float4 grid_fragment(GridOut in [[stage_in]],
                             constant GridUniforms& u [[buffer(0)]])
{
    // Convert screen position to world space
    float4 nearWorld = u.invViewProjection * float4(in.screenPos, -1, 1);
    float4 farWorld = u.invViewProjection * float4(in.screenPos, 1, 1);
    
    nearWorld /= nearWorld.w;
    farWorld /= farWorld.w;
    
    // Calculate ray direction
    float3 rayDir = normalize(farWorld.xyz - nearWorld.xyz);
    float3 rayOrigin = nearWorld.xyz;
    
    // Ray-plane intersection with y=0 plane
    // If ray is parallel to plane, discard
    if (abs(rayDir.y) < 0.0001) {
        discard_fragment();
    }
    
    // Calculate intersection
    float t = -rayOrigin.y / rayDir.y;
    
    // If intersection is behind the near plane, discard
    if (t < 0.0) {
        discard_fragment();
    }
    
    // Calculate world position on the grid plane
    float3 worldPos = rayOrigin + t * rayDir;
    float2 gridPos = worldPos.xz;
    
    // Distance from camera for fading
    float distance = length(worldPos - u.cameraPos);
    
    // Compute fade factor
    float fade = 1.0 - smoothstep(u.fadeStart, u.fadeEnd, distance);
    if (fade <= 0.01) {
        discard_fragment();
    }
    
    // Calculate grid lines
    float gridLine = grid(gridPos, u.gridSpacing);
    
    // Add larger grid lines
    float gridLine10 = grid(gridPos, u.gridSpacing * 10.0) * 0.7;
    
    // Combine grids
    float finalGrid = max(gridLine * 0.4, gridLine10);
    
    // Add main axes
    float2 axisDistance = abs(gridPos) / fwidth(gridPos);
    float xAxis = 1.0 - min(axisDistance.y / 1.5, 1.0);
    float zAxis = 1.0 - min(axisDistance.x / 1.5, 1.0);
    
    // Apply fade
    finalGrid *= fade;
    xAxis *= fade;
    zAxis *= fade;
    
    // Color the grid
    float3 color = float3(0.5, 0.5, 0.5) * finalGrid;
    
    // Color axes
    if (xAxis > 0.01) {
        color = mix(color, float3(1.0, 0.3, 0.3), xAxis);
    }
    if (zAxis > 0.01) {
        color = mix(color, float3(0.3, 0.3, 1.0), zAxis);
    }
    
    float alpha = max(finalGrid, max(xAxis, zAxis));
    
    if (alpha < 0.01) {
        discard_fragment();
    }
    
    return float4(color, alpha);
}
