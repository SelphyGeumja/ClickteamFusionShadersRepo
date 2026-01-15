// =====================
// Clickteam FX (DX9 / ps_2_0)
// Caustics Noise Plane (Y fixed, no recursion)
// Params: fProgress, fZoom, fOffsetX, fOffsetY, fWarp
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

sampler2D Texture0 : register(s1);

float fProgress;
float fZoom;
float fOffsetX;
float fOffsetY;
float fWarp;

float3 mod289_3(float3 x) { return x - floor(x / 289.0) * 289.0; }
float4 mod289_4(float4 x) { return x - floor(x / 289.0) * 289.0; }
float4 permute(float4 x)  { return mod289_4((x * 34.0 + 1.0) * x); }
float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

// Simplex noise 3D returning float4(grad.xyz, value)
// grad is an approximation (good enough for domain warping)
float4 snoise(float3 v)
{
    const float2 C = float2(1.0/6.0, 1.0/3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);

    float3 i  = floor(v + dot(v, C.yyy));
    float3 x0 = v - i + dot(i, C.xxx);

    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + C.yyy;
    float3 x3 = x0 - D.yyy;

    i = mod289_3(i);
    float4 p = permute(permute(permute(
                i.z + float4(0.0, i1.z, i2.z, 1.0))
              + i.y + float4(0.0, i1.y, i2.y, 1.0))
              + i.x + float4(0.0, i1.x, i2.x, 1.0));

    float4 j = p - 49.0 * floor(p / 49.0);
    float4 x_ = floor(j / 7.0);
    float4 y_ = floor(j - 7.0 * x_);

    float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
    float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0) * 2.0 + 1.0;
    float4 s1 = floor(b1) * 2.0 + 1.0;
    float4 sh = -step(h, 0.0);

    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    float3 g0 = float3(a0.xy, h.x);
    float3 g1 = float3(a0.zw, h.y);
    float3 g2 = float3(a1.xy, h.z);
    float3 g3 = float3(a1.zw, h.w);

    float4 norm = taylorInvSqrt(float4(dot(g0,g0), dot(g1,g1), dot(g2,g2), dot(g3,g3)));
    g0 *= norm.x;
    g1 *= norm.y;
    g2 *= norm.z;
    g3 *= norm.w;

    float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    float4 m2 = m * m;
    float4 m4 = m2 * m2;

    float n0 = dot(g0, x0);
    float n1 = dot(g1, x1);
    float n2 = dot(g2, x2);
    float n3 = dot(g3, x3);

    float value = 42.0 * dot(m4, float4(n0, n1, n2, n3));

    // Approx gradient (no recursion)
    float3 grad = g0 * m4.x + g1 * m4.y + g2 * m4.z + g3 * m4.w;
    grad = normalize(grad + 1e-6);

    return float4(grad, value);
}

PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;

    float2 uv = In.Texture;
    uv.y = 1.0 - uv.y; // FIX Y

    uv = uv * fZoom + float2(fOffsetX, fOffsetY);

    float2 fragCoord = uv * float2(320.0, 180.0);
    float2 p = (-float2(320.0, 180.0) + 2.0 * fragCoord) / 180.0;

    float3 ww = normalize(-float3(0.0, 1.0, 1.0));
    float3 uu = normalize(cross(ww, float3(0.0, 1.0, 0.0)));
    float3 vv = normalize(cross(uu, ww));

    float3 rd  = p.x * uu + p.y * vv + 1.5 * ww;
    float3 pos = -ww + rd * (ww.y / rd.y);

    pos.y = fProgress;
    pos *= (3.0 + fWarp * 2.0);

    float4 n = snoise(pos);
    pos -= 0.07 * n.xyz;
    n = snoise(pos);

    pos -= 0.07 * n.xyz;
    n = snoise(pos);

    float intensity = exp(n.w * 3.0 - 1.5);
    Out.Color = float4(intensity, intensity, intensity, 1.0);
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
