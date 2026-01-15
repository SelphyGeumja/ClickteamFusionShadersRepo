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
sampler2D Texture0 : register(s1);

float fProgress;
float fZoom;
float fOffsetX;
float fOffsetY;
float fWarp;

float N21(float2 p)
{
    return frac(sin(p.x * 110.0 + (8.21 - p.y) * 331.0) * 1218.0);
}

float Noise2D(float2 uv)
{
    float2 st = frac(uv);
    float2 id = floor(uv);
    st = st * st * (3.0 - 2.0 * st);

    float c = lerp(
        lerp(N21(id), N21(id + float2(1.0, 0.0)), st.x),
        lerp(N21(id + float2(0.0, 1.0)), N21(id + float2(1.0, 1.0)), st.x),
        st.y
    );
    return c;
}

float fbm(float2 uv)
{
    float c = 0.0;
    c += Noise2D(uv) * 0.5;
    c += Noise2D(uv * 2.0) * 0.25;
    return c / (1.0 - 1.0 / 16.0);
}

float3 fbm3(float2 uv)
{
    float3 color;

    float f1 = fbm(uv);
    color = lerp(float3(0.1, 0.0, 0.0), float3(0.9, 0.1, 0.1), 2.5 * f1);

    float f2 = fbm(2.4 * f1 + uv + 0.15 * sin(fProgress) * float2(7.0, -8.0));
    color = lerp(color, float3(0.6, 0.5, 0.1), 1.5 * f2);

    float f3 = fbm(3.5 * f2 + uv - 0.15 * cos(1.5 * fProgress) * float2(4.0, 3.0));
    color = lerp(color, float3(0.1, 0.35, 0.45), f3);

    return color;
}

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float2 uv = In.Texture;

    // Same parameter logic as your example shader
    uv = uv * fZoom + float2(fOffsetX, fOffsetY);

    // Optional extra warp (like your example)
    if (fWarp != 0.0)
    {
        float n = Noise2D(uv * 4.0 + float2(fProgress, fProgress));
        uv += (n - 0.5) * fWarp;
    }

    float3 c = fbm3(float2(5.0, 5.0) * uv + sin(0.3 * fProgress) * 0.5);

    c.r *= 0.825;
    c.g *= 0.825;

    Out.Color = float4(c * 2.5, 1.0);
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
