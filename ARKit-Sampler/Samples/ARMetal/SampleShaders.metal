//
//  SampleShaders.metal
//  ARMetal
//
//  Created by Shuichi Tsutsumi on 2017/09/01.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct MyNodeBuffer {
    float4x4 modelViewProjectionTransform;
};

struct MyVertexInput {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct SimpleVertex
{
    float4 position [[position]];
    float2 texCoords;
};

vertex SimpleVertex myVertex(MyVertexInput in [[stage_in]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant MyNodeBuffer& scn_node [[buffer(1)]])
{
    SimpleVertex vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    vert.texCoords = in.texCoords;
    
    return vert;
}

vertex SimpleVertex textureRendererVertex(const device float4* positions           [[ buffer(0) ]],
                                          const device float2* texture_coordinates [[ buffer(1) ]],
                                          const uint           vid                 [[ vertex_id ]])
{
    SimpleVertex vert;
    vert.position = positions[vid];
    vert.texCoords = texture_coordinates[vid];
    return vert;
}

//fragment half4 myFragment(SimpleVertex in [[stage_in]],
//                          texture2d<float, access::sample> diffuseTexture [[texture(0)]])
//{
//    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
//    float4 color = diffuseTexture.sample(sampler2d, in.texCoords);
//    return half4(color);
//}

// http://glslsandbox.com/e#37017.0

constant float2 offset = float2(0.5,0.5);

float2 hash(float2 uv, float time);
float voronoi(float2 v, float time);

float2 hash(float2 uv, float time)
{
    uv    += sin(uv.yx * 123.5678 + time/2.);
    return (sin(uv)/2. + 1.0);
}

float voronoi(float2 v, float time)//via iq
{
    float2 lattice     = floor(v);
    float2 field     = fract(v);
    
    float result = 8.0;
    for(float j = -1.; j <= 1.; j++)
    {
        for(float i = -1.; i <= 1.; i++)
        {
            float2 position    = float2(i, j);
            float2 weight    = position - field + (hash(lattice + position, time));
            
            result        = min(dot(weight, weight), result);
        }
    }
    return sqrt(result);
}


fragment half4 voronoiFragment(SimpleVertex in [[stage_in]],
                               constant float &time [[buffer(0)]]
                               )
{
    float scale     = 8.;
    float2 position = float2(in.texCoords.x - offset.x, in.texCoords.y - offset.y);
    position    = position * scale;
    
    half4 result    = half4(0.);
    
    result        += voronoi(position, time);
    
    return result;
    
}

// http://glslsandbox.com/e#36858.0
//fragment half4 myFragment1(SimpleVertex in [[stage_in]],
//                           constant float &time [[buffer(0)]],
//                           texture2d<float> texture [[ texture(0) ]])
//{
//    float2 uv = in.texCoords * 4;
//
//    constexpr sampler defaultSampler;
//    float4 color;
////    color = texture.sample(defaultSampler, in.texCoords) + in.color;
//    color = texture.sample(defaultSampler, in.texCoords);
//
//    float i0=1.2;
//    float i1=0.95;
//    float i2=1.5;
//    float2 i4=float2(0.0,0.0);
//    for(int s=0;s<4;s++)
//    {
//        float2 r;
//        r=float2(cos(uv.y*i0-i4.y+time/i1),sin(uv.x*i0+i4.x+time/i1))/i2;
//        r+=float2(-r.y,r.x)*0.2;
//        uv.xy+=r;
//
//        i0*=1.93;
//        i1*=1.25;
//        i2*=1.7;
//        i4+=r.xy*1.0+0.5*time*i1;
//    }
//    float r=sin(uv.x-time)*0.5+0.5;
//    float b=sin(uv.y+time)*0.5+0.5;
//    float g=sin((sqrt(uv.x*uv.x+uv.y*uv.y)+time))*0.5+0.5;
//    half3 c=half3(r,g,b);
////    return half4(c,1.0);
//    return half4(color.r, color.g, color.b, 1.0);
//}

fragment float4 myFragment1(SimpleVertex in [[stage_in]],
                            constant float &time [[buffer(0)]],
                            texture2d<float>  snapshot_texture     [[ texture(0) ]],
                            texture2d<float>  camera_texture   [[ texture(1) ]])
{
    constexpr sampler colorSampler;

    float4 color = snapshot_texture.sample(colorSampler, in.texCoords);
    
    if (color.r == 0.0 && color.g == 0.0 && color.b == 0.0)
    {
        // https://www.shadertoy.com/view/MsX3DN
        float2 uv = in.texCoords;
        // Flip that shit, cause shadertool be all "yolo opengl"
        //uv.y = -1.0 - uv.y;
        // Modify that X coordinate by the sin of y to oscillate back and forth up in this.
//        uv.x += sin(uv.y * 5.0 + time) / 10.0;
        float duration = 2;
        float x_offset = sin(uv.y * 20.0 + time) / duration;   // uv.yにかける係数が大きいほど、変化がy方向に対して細かくなる
        x_offset *= 0.1;    // 影響を弱める。1.0でx軸方向に100%歪む
        uv.x += x_offset;

        // fract(x)    x-floor(x)を返す
//        float2 new_uv = float2(pos.x, fract (pos.y - (position.time / 82.0)));
//        float2 new_uv = float2(in.texCoords.x, in.texCoords.y); // これでそのまんま出る
//        float2 new_uv = float2(in.texCoords.x, in.texCoords.y - 0.1 * fract(time / 2));

//        float3 normal = tex2D3.sample(colorSampler, new_uv).rgb;
//        normal.xy = normal.xy * 0.05;
//        float2 val = fract(pos + normal.xy);
//
//        color.rgb = tex2D2.sample(colorSampler, val).rgb;

        color = camera_texture.sample(colorSampler, uv);
        float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
        color = float4(gray);
    }
    
    return color;
}
