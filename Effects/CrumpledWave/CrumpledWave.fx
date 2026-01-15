float fProgress;
int   FlipY;

float4 Main(float2 uv : TEXCOORD0) : COLOR0
{
    float2 p = uv * 2.0 - 1.0;

    // inversion optionnelle (0 ou 1)
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

    return float4(col, 1.0);
}

technique tech_main
{
    pass P0
    {
        PixelShader = compile ps_2_0 Main();
    }
}
