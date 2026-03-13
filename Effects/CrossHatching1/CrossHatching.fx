// Pixel shader input structure
struct PS_INPUT
{
    float4 Position : POSITION;
    float2 Texture  : TEXCOORD0;
};

// Pixel shader output structure
struct PS_OUTPUT
{
    float4 Color : COLOR0;
};

// Global variables
sampler2D Texture0 : register(s0);

float fScale;
float fLineWidth;
float fBlackThreshold;

float luminance(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

// Ligne périodique centrée sur 0.5 (comme ton original)
// width_t : largeur exprimée dans l'espace de t (pas l'espace p)
// aa_t    : AA exprimé dans l'espace de t
float line1D(float t, float width_t, float aa_t)
{
    float v = frac(t);
    float d = abs(v - 0.5);
    return 1.0 - smoothstep(width_t - aa_t, width_t + aa_t, d);
}

// Gradients (normes) pour égaliser l'épaisseur en espace p
static const float G_VH  = 1.0;        // t = x ou y
static const float G_D   = 2.2360679;  // sqrt(5) pour t = x ± 2y
static const float AA_BASE = 0.001;    // AA DX9 de base (dans t)

float hatchDiagA(float2 p)
{
    return line1D(p.x - 2.0 * p.y, fLineWidth * G_D, AA_BASE * G_D);
}
float hatchDiagB(float2 p)
{
    return line1D(p.x + 2.0 * p.y, fLineWidth * G_D, AA_BASE * G_D);
}

// V/H : fréquence x2 MAIS alignée sur les mêmes positions que le cas fréquence x1.
// Avec le centrage à 0.5, il faut t = 2x + 0.5 (sinon décalage de 0.25).
// Gradient = 2 (donc G = 2.0) pour l'égalité d'épaisseur en espace p.
float hatchVert(float2 p)
{
    return line1D(p.x * 2.0 + 0.5, fLineWidth * 2.0, AA_BASE * 2.0);
}
float hatchHorz(float2 p)
{
    return line1D(p.y * 2.0 + 0.5, fLineWidth * 2.0, AA_BASE * 2.0);
}

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

    float4 src = tex2D(Texture0, In.Texture);
    float lum = saturate(luminance(src.rgb));

    // Noir profond protégé (outline)
    if (lum <= fBlackThreshold)
    {
        Out.Color = float4(0, 0, 0, src.a);
        return Out;
    }

    float mask = computeHatching(In.Texture, lum);

    // Noir & blanc : papier blanc + encre noire
    float3 bw = lerp(float3(1,1,1), float3(0,0,0), mask);

    Out.Color = float4(bw, src.a);
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