cbuffer PS_VARIABLES : register(b0)
{
    float fProgress;
    int   FlipY;
    float _pad0;
    float _pad1;
};

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

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float2 p = In.texCoord * 2.0 - 1.0;

    // inversion verticale optionnelle
    p.y *= lerp(1.0, -1.0, FlipY);

    float t = fProgress * 0.5;

    for (float i = 1.0; i < 8.0; i++)
    {
        p.y += 0.1 * sin(p.x * i * i + t)
                   * sin(p.y * i * i + t);
    }

    float3 col;
    col.r = p.y - 0.1;
    col.g = p.y + 0.3;
    col.b = p.y + 0.95;

    Out.Color = float4(col, 1.0) * In.Tint;
    return Out;
}

PS_OUTPUT ps_main_pm(in PS_INPUT In)
{
    PS_OUTPUT Out = ps_main(In);
    Out.Color.rgb *= Out.Color.a;
    return Out;
}
