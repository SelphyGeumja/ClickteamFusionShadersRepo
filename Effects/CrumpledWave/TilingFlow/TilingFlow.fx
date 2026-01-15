// =====================
// Clickteam FX (DX9 / ps_2_0)
// =====================

struct PS_INPUT
{
    float4 Position : POSITION;
    float2 Texture  : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4 Color : COLOR0;
};

sampler2D Texture0 : register(s1); // déclaré comme dans l'exemple (non utilisé ici)

float fProgress;

static const float TAU = 6.28318530718;
static const float inten = 0.005;
static const float MAX_ITER_INV = 0.2; // 1.0 / 5.0

float2 shadertoy_mod(float2 x, float2 y)
{
    // mod(x,y) = x - y*floor(x/y)
    return x - y * floor(x / y);
}

float iter_step(float2 p, float2 i, float c, float time, int n)
{
    float t = time * (1.0 - (3.5 / (float)(n + 1)));
    i = p + float2(cos(t - i.x) + sin(t + i.y),
                   sin(t - i.y) + cos(t + i.x));

    float sx = sin(i.x + t) / inten;
    float cy = cos(i.y + t) / inten;

    // éviter division instable (sans branch lourd)
    float2 denom = float2(sx, cy);
    denom = denom + (denom == 0.0) * 1e-6;

    float2 v = float2(p.x / denom.x, p.y / denom.y);
    c += 1.0 / length(v);

    return c;
}

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float time = fProgress * 0.5 + 23.0;

    // Clickteam fournit déjà des UV 0-1
    float2 uv = In.Texture;

    float2 p = shadertoy_mod(uv * TAU, TAU.xx) - 250.0;
    float2 i = p;

    float c = 1.0;

    // MAX_ITER = 5 : déroulé pour compat ps_2_0
    c = iter_step(p, i, c, time, 0); // n=0
    i = p + float2(cos(time * (1.0 - 3.5 / 1.0) - i.x) + sin(time * (1.0 - 3.5 / 1.0) + i.y),
                   sin(time * (1.0 - 3.5 / 1.0) - i.y) + cos(time * (1.0 - 3.5 / 1.0) + i.x)); // recalage i
    c = iter_step(p, i, c, time, 1);
    i = p + float2(cos(time * (1.0 - 3.5 / 2.0) - i.x) + sin(time * (1.0 - 3.5 / 2.0) + i.y),
                   sin(time * (1.0 - 3.5 / 2.0) - i.y) + cos(time * (1.0 - 3.5 / 2.0) + i.x));
    c = iter_step(p, i, c, time, 2);
    i = p + float2(cos(time * (1.0 - 3.5 / 3.0) - i.x) + sin(time * (1.0 - 3.5 / 3.0) + i.y),
                   sin(time * (1.0 - 3.5 / 3.0) - i.y) + cos(time * (1.0 - 3.5 / 3.0) + i.x));
    c = iter_step(p, i, c, time, 3);
    i = p + float2(cos(time * (1.0 - 3.5 / 4.0) - i.x) + sin(time * (1.0 - 3.5 / 4.0) + i.y),
                   sin(time * (1.0 - 3.5 / 4.0) - i.y) + cos(time * (1.0 - 3.5 / 4.0) + i.x));
    c = iter_step(p, i, c, time, 4);

    c *= MAX_ITER_INV;
    c = 1.17 - pow(c, 1.4);

    float3 colour = pow(abs(c).xxx, 8.0);
    colour = saturate(colour + float3(0.0, 0.35, 0.5));

    Out.Color = float4(colour, 1.0);
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
