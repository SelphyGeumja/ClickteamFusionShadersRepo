struct PS_INPUT
{
    float4 Position : POSITION;
    float2 Texture  : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4 Color : COLOR0;
};

sampler2D Texture0 : register(s1);

float fProgress;
float fZoom;

float2 mul2(float2 v, float2x2 m)
{
    return float2(v.x*m[0][0] + v.y*m[1][0],
                  v.x*m[0][1] + v.y*m[1][1]);
}

float3 mul3(float3 v, float3x3 m)
{
    return float3(
        v.x*m[0][0] + v.y*m[1][0] + v.z*m[2][0],
        v.x*m[0][1] + v.y*m[1][1] + v.z*m[2][1],
        v.x*m[0][2] + v.y*m[1][2] + v.z*m[2][2]
    );
}

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    // Shadertoy: p / iResolution.y * 7
    // Here: use UV, emulate square aspect by using Y as reference
    float2 uv = In.Texture;
    float2 p = (uv - 0.5) * 2.0;
    p *= (7.0 * fZoom);

    // Shadertoy: sin(k=iDate*.2).w
    // We don't have iDate, so we use fProgress as time
    float time = fProgress;
    float w = sin(time * 0.2);

    float4 k;
    k.xy = p + w;

    float a = 1.0;

    // Matrix from Shadertoy:
    // mat3(-2,-1,2, 3,-2,1, 1,2,2) * 0.3
    float3x3 M = float3x3(
        -2.0, -1.0,  2.0,
         3.0, -2.0,  1.0,
         1.0,  2.0,  2.0
    );

    // Equivalent of:
    // a = min(a, length(0.5 - fract(k.xyw *= M * 0.3)));
    // repeated 3 times

    [unroll]
    for (int i = 0; i < 3; i++)
    {
        float3 v = float3(k.x, k.y, w);
        v = mul3(v, M) * 0.3;

        // write back
        k.x = v.x;
        k.y = v.y;
        w   = v.z;

        float3 f = frac(float3(k.x, k.y, w));
        float3 d = 0.5 - f;
        a = min(a, length(d));
    }

    float intensity = pow(a, 7.0) * 25.0;
    Out.Color = float4(intensity, intensity + 0.35, intensity + 0.5, 1.0);

    return Out;
}

technique tech_main
{
    pass P0
    {
        VertexShader = NULL;
        PixelShader  = compile ps_2_0 ps_main();
    }
}
