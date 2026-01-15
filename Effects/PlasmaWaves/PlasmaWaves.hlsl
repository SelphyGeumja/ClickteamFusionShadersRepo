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
    float fOffsetX;
    float fOffsetY;

    float fWarp;
    float _pad0;
    float _pad1;
    float _pad2;
};

float rand1(float2 n)
{
    return frac(sin(n.x * 12.9898 + n.y * 4.1414) * 43758.5453);
}

float noise1(float2 p)
{
    float2 ip = floor(p);
    float2 u = frac(p);
    u = u * u * (3.0 - 2.0 * u);

    float a = rand1(ip);
    float b = rand1(ip + float2(1.0, 0.0));
    float c = rand1(ip + float2(0.0, 1.0));
    float d = rand1(ip + float2(1.0, 1.0));

    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

float heightField(float2 uv, float t)
{
    float speed = 6.0;

    float topright    = sin(t * (speed + 1.0) - sin(length(uv - float2(1.0, 1.0))) * 53.0);
    float topleft     = sin(t * (speed + 1.0) - sin(length(uv - float2(0.0, 1.0))) * 37.0);
    float bottomright = sin(t * (speed)       - sin(length(uv - float2(1.0, 0.0))) * 61.0);
    float bottomleft  = sin(t * (speed + 2.0) - sin(length(uv - float2(0.0, 0.0))) * 47.0);

    float horizontalWaves = sin(t * (speed + 2.0) - sin(uv.y) * 47.0);

    float temp = horizontalWaves + bottomleft * 0.4 + bottomright * 0.2 + topleft * 0.6 + topright * 0.3;

    float b = smoothstep(-2.5, 5.0, temp);
    return b * 3.0;
}

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float2 uv = In.texCoord;

    uv = uv * fZoom + float2(fOffsetX, fOffsetY);

    if (fWarp != 0.0)
    {
        float n = noise1(uv * 6.0 + float2(fProgress, fProgress));
        float2 w = (n - 0.5) * fWarp;
        uv += w;
    }

    float t = fProgress;

    float waveHeight = 0.4 + heightField(uv, t);

    float3 color = float3(waveHeight * 0.3, waveHeight * 0.5, waveHeight);

    Out.Color = float4(color * In.Tint.rgb, In.Tint.a);
    return Out;
}

PS_OUTPUT ps_main_pm(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float2 uv = In.texCoord;

    uv = uv * fZoom + float2(fOffsetX, fOffsetY);

    if (fWarp != 0.0)
    {
        float n = noise1(uv * 6.0 + float2(fProgress, fProgress));
        float2 w = (n - 0.5) * fWarp;
        uv += w;
    }

    float t = fProgress;

    float waveHeight = 0.4 + heightField(uv, t);

    float3 color = float3(waveHeight * 0.3, waveHeight * 0.5, waveHeight);

    float a = In.Tint.a;
    Out.Color = float4(color * In.Tint.rgb * a, a);
    return Out;
}
