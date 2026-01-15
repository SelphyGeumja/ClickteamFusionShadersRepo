// =====================
// Clickteam HLSL (DX11) - for FXC
// =====================

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

// Ressources déclarées comme dans l'exemple (non utilisées ici)
Texture2D<float4> Texture0       : register(t1);
sampler           Texture0Sampler: register(s1);

cbuffer PS_VARIABLES : register(b0)
{
    float fProgress;
    float _pad0;
    float _pad1;
    float _pad2;
};

static const float TAU = 6.28318530718;
static const float inten = 0.005;

float2 shadertoy_mod(float2 x, float2 y)
{
    return x - y * floor(x / y);
}

float safe_div(float a, float b)
{
    // évite NaN/Inf sans branch coûteux
    return a / (b + (b == 0.0) * 1e-6);
}

float iter_accum(float2 p, float2 i, float c, float time, float n1)
{
    // n1 = (n+1) sous forme float
    float t = time * (1.0 - (3.5 / n1));
    i = p + float2(cos(t - i.x) + sin(t + i.y),
                   sin(t - i.y) + cos(t + i.x));

    float sx = sin(i.x + t) / inten;
    float cy = cos(i.y + t) / inten;

    float2 v = float2(safe_div(p.x, sx), safe_div(p.y, cy));
    c += 1.0 / length(v);

    return c;
}

float3 shader_colour(float2 uv, float time)
{
    float2 p = shadertoy_mod(uv * TAU, TAU.xx) - 250.0;
    float2 i = p;

    float c = 1.0;

    // MAX_ITER = 5 (déroulé)
    c = iter_accum(p, i, c, time, 1.0);
    c = iter_accum(p, i, c, time, 2.0);
    c = iter_accum(p, i, c, time, 3.0);
    c = iter_accum(p, i, c, time, 4.0);
    c = iter_accum(p, i, c, time, 5.0);

    c *= 0.2;
    c = 1.17 - pow(c, 1.4);

    float3 colour = pow(abs(c).xxx, 8.0);
    return saturate(colour + float3(0.0, 0.35, 0.5));
}

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float time = fProgress * 0.5 + 23.0;
    float2 uv = In.texCoord;

    float3 colour = shader_colour(uv, time);

    // modulation par Tint (comme l'exemple validé)
    Out.Color = float4(colour * In.Tint.rgb, In.Tint.a);
    return Out;
}

PS_OUTPUT ps_main_pm(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float time = fProgress * 0.5 + 23.0;
    float2 uv = In.texCoord;

    float3 colour = shader_colour(uv, time);

    float a = In.Tint.a;
    Out.Color = float4(colour * In.Tint.rgb * a, a);
    return Out;
}
