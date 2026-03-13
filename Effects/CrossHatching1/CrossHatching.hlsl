struct PS_INPUT
{
    float4 Tint      : COLOR0;
    float2 texCoord  : TEXCOORD0;
    float4 Position  : SV_POSITION;
};

struct PS_OUTPUT
{
    float4 Color : SV_TARGET;
};

Texture2D Texture0 : register(t0);
SamplerState Texture0Sampler : register(s0);

cbuffer PS_VARIABLES : register(b0)
{
    float fScale;
    float fLineWidth;
    float fBlackThreshold;
    float padding;
};

float luminance(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

// width_t est une largeur dans l'espace de t.
// Pour que l'épaisseur soit identique en espace p, on passe width_t = fLineWidth * |grad(t)|.
// Le AA est piloté par fwidth(t) (déjà dans l'espace de t).
float line1D(float t, float width_t)
{
    float v = frac(t);
    float d = abs(v - 0.5);

    float aa = fwidth(t);
    return 1.0 - smoothstep(width_t - aa, width_t + aa, d);
}

// Normes de gradient pour égaliser l'épaisseur en espace p
static const float G_D = 2.2360679; // sqrt(5) pour t = x ± 2y

float hatchDiagA(float2 p) { return line1D(p.x - 2.0 * p.y, fLineWidth * G_D); }
float hatchDiagB(float2 p) { return line1D(p.x + 2.0 * p.y, fLineWidth * G_D); }

// V/H : fréquence x2 alignée (2x + 0.5), gradient = 2.0
float hatchVert (float2 p) { return line1D(p.x * 2.0 + 0.5, fLineWidth * 2.0); }
float hatchHorz (float2 p) { return line1D(p.y * 2.0 + 0.5, fLineWidth * 2.0); }

float computeHatching(float2 uv, float lum)
{
    float inv = 1.0 - lum;
    float2 p = uv * fScale;

    float h = 0.0;
    h += step(0.10, inv) * hatchDiagA(p);
    h += step(0.20, inv) * hatchDiagB(p);
    h += step(0.35, inv) * hatchVert(p);
    h += step(0.55, inv) * hatchHorz(p);

    return saturate(h);
}

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float4 src = Texture0.Sample(Texture0Sampler, In.texCoord);
    float lum = saturate(luminance(src.rgb));

    float alpha = src.a * In.Tint.a;

    // Noir profond protégé (outline)
    if (lum <= fBlackThreshold)
    {
        Out.Color = float4(0.0, 0.0, 0.0, alpha);
        return Out;
    }

    float mask = computeHatching(In.texCoord, lum);

    float3 bw = lerp(1.0.xxx, 0.0.xxx, mask);

    // prémultiplié
    Out.Color = float4(bw * alpha, alpha);
    return Out;
}

PS_OUTPUT ps_main_pm(in PS_INPUT In)
{
    return ps_main(In);
}