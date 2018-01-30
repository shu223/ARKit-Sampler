//
//  VerticalPlanesShader.metal
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/01/30.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//
//  Referene: http://glslsandbox.com/e#36858.0

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct VertexInput {
    float3 position  [[attribute(SCNVertexSemanticPosition)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct NodeBuffer {
    float4x4 modelViewProjectionTransform;
};

struct ColorInOut
{
    float4 position [[ position ]];
    float2 texCoords;
};

vertex ColorInOut scnVertexShader(VertexInput          in       [[ stage_in ]],
                                  constant NodeBuffer& scn_node [[ buffer(0) ]])
{
    ColorInOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.texCoords = in.texCoords;
    
    return out;
}

fragment half4 scnFragmentShader(ColorInOut in          [[ stage_in] ],
                                 constant   float& time [[ buffer(0) ]])
{
    float2 uv = in.texCoords * 4;
    
    float i0=1.2;
    float i1=0.95;
    float i2=1.5;
    float2 i4=float2(0.0,0.0);
    for(int s=0;s<4;s++)
    {
        float2 r;
        r=float2(cos(uv.y*i0-i4.y+time/i1),sin(uv.x*i0+i4.x+time/i1))/i2;
        r+=float2(-r.y,r.x)*0.2;
        uv.xy+=r;
        
        i0*=1.93;
        i1*=1.25;
        i2*=1.7;
        i4+=r.xy*1.0+0.5*time*i1;
    }
    float r=sin(uv.x-time)*0.5+0.5;
    float b=sin(uv.y+time)*0.5+0.5;
    float g=sin((sqrt(uv.x*uv.x+uv.y*uv.y)+time))*0.5+0.5;
    half3 c=half3(r,g,b);
    return half4(c,1.0);
}
