struct PS_INPUT
{
    float4 Tint     : COLOR0;
    float2 texCoord : TEXCOORD0;
    float4 Position : SV_POSITION;
};

struct PS_OUTPUT
{
    float4 Color : SV_TARGET;
};

Texture2D<float4> Texture0 : register(t1);
sampler Texture0Sampler : register(s1);

cbuffer PS_VARIABLES : register(b0)
{
    float fProgress;
    float fZoom;
    float _pad0;
    float _pad1;
};

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

    float2 uv = In.texCoord;
    float2 p = (uv - 0.5) * 2.0;
    p *= (7.0 * fZoom);

    float time = fProgress;
    float w = sin(time * 0.2);

    float4 k;
    k.xy = p + w;

    float a = 1.0;

    float3x3 M = float3x3(
        -2.0, -1.0,  2.0,
         3.0, -2.0,  1.0,
         1.0,  2.0,  2.0
    );

    [unroll]
    for (int i = 0; i < 3; i++)
    {
        float3 v = float3(k.x, k.y, w);
        v = mul3(v, M) * 0.3;

        k.x = v.x;
        k.y = v.y;
        w   = v.z;

        float3 f = frac(float3(k.x, k.y, w));
        float3 d = 0.5 - f;
        a = min(a, length(d));
    }

    float intensity = pow(a, 7.0) * 25.0;
    float4 col = float4(intensity, intensity + 0.35, intensity + 0.5, 1.0);

    Out.Color = float4(col.rgb * In.Tint.rgb, In.Tint.a);
    return Out;
}

PS_OUTPUT ps_main_pm(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float2 uv = In.texCoord;
    float2 p = (uv - 0.5) * 2.0;
    p *= (7.0 * fZoom);

    float time = fProgress;
    float w = sin(time * 0.2);

    float4 k;
    k.xy = p + w;

    float a = 1.0;

    float3x3 M = float3x3(
        -2.0, -1.0,  2.0,
         3.0, -2.0,  1.0,
         1.0,  2.0,  2.0
    );

    [unroll]
    for (int i = 0; i < 3; i++)
    {
        float3 v = float3(k.x, k.y, w);
        v = mul3(v, M) * 0.3;

        k.x = v.x;
        k.y = v.y;
        w   = v.z;

        float3 f = frac(float3(k.x, k.y, w));
        float3 d = 0.5 - f;
        a = min(a, length(d));
    }

    float intensity = pow(a, 7.0) * 25.0;
    float4 col = float4(intensity, intensity + 0.35, intensity + 0.5, 1.0);

    float aOut = In.Tint.a;
    Out.Color = float4(col.rgb * In.Tint.rgb * aOut, aOut);
    return Out;
}
