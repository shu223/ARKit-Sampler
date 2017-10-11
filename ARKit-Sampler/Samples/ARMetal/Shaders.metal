//
//  SampleShaders.metal
//  ARMetal
//
//  Created by Shuichi Tsutsumi on 2017/09/01.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct ColorInOut
{
    float4 position [[position]];
    float2 texCoords;
};

vertex ColorInOut vertexShader(const device float4* positions [[ buffer(0) ]],
                               const device float2* texCoords [[ buffer(1) ]],
                               const uint           vid       [[ vertex_id ]])
{
    ColorInOut out;
    out.position = positions[vid];
    out.texCoords = texCoords[vid];
    return out;
}

// based on: https://www.shadertoy.com/view/MsX3DN
fragment float4 fragmentShader(ColorInOut       in               [[ stage_in ]],
                               constant float   &time            [[ buffer(0) ]],
                               texture2d<float> snapshot_texture [[ texture(0) ]],
                               texture2d<float> camera_texture   [[ texture(1) ]])
{
    constexpr sampler colorSampler;

    float4 color = snapshot_texture.sample(colorSampler, in.texCoords);
    
    if (color.r == 0.0 && color.g == 0.0 && color.b == 0.0)
    {
        float2 uv = in.texCoords;
        float duration = 2;
        float x_offset = sin(uv.y * 20.0 + time) / duration;
        x_offset *= 0.1;
        uv.x += x_offset;

        color = camera_texture.sample(colorSampler, uv);
        float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
        color = float4(gray);
    }
    
    return color;
}
