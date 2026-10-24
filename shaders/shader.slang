struct VSInput {
    float2 inPosition : POSITION;
};

struct UniformBuffer {
    float4x4 invViewProj;
    float3 cameraPos;
};

ConstantBuffer<UniformBuffer> ubo;

struct VSOutput {
    float4 pos : SV_Position;
    float3 farWorld : TEXCOORD0;
};

struct Grid {
    float cellSize;
    float fadeStart;
    float fadeEnd;
    float3 colorThin;
    float3 colorThick;
    float3 colorAxisX;
    float3 colorAxisY;
};

ConstantBuffer<Grid> grid;
//struct Particle {
//    float2 position;
//    float2 velocity;
//    float4 color;
//}

//struct ParticleSSBO {
//    Particle particles;
//}

//StructuredBuffer<ParticleSSBO>   particlesIn;
//RWStructuredBuffer<ParticleSSBO> particlesOut;

[shader("vertex")]
VSOutput vertMain(VSInput input) {
    VSOutput output;

    float4 far = mul(ubo.invViewProj, float4(input.inPosition, 1.0, 1.0));

    output.farWorld = far.xyz / far.w;

    output.pos = float4(input.inPosition, 0.0, 1.0);

    return output;
}

float distToInt(float x) { return abs(frac(x - 0.5) - 0.5); }

[shader("fragment")]
float4 fragMain(VSOutput vertIn) : SV_Target {

    float3 rOrigin    = ubo.cameraPos;
    float3 rDirection = normalize(vertIn.farWorld - rOrigin);

    if (abs(rDirection.z) < 1e-6) discard;
    float t = -rOrigin.z / rDirection.z;
    if (t <= 0.0) discard;

    float3 p = rOrigin + t * rDirection; 
    float2 uv = p.xy / grid.cellSize;

    float2 w = max(fwidth(uv), float2(1e-6));
    float2 dMinor = float2(distToInt(uv.x), distToInt(uv.y)) / w;
    float2 dMajor = float2(distToInt(uv.x / 10.0), distToInt(uv.y / 10.0)) * 10.0 / w;

    float minor = 1.0 - smoothstep(0.0, 0.5, min(dMinor.x, dMinor.y));
    float major = 1.0 - smoothstep(0.0, 1.3, min(dMajor.x, dMajor.y));
    //float axX   = 1.0 - smoothstep(0.0, 1.3, abs(uv.y) / w.y);
    //float axY   = 1.0 - smoothstep(0.0, 1.3, abs(uv.x) / w.x);

    float cellsPerPixel = max(w.x, w.y);
    minor *= 1.0 - smoothstep(0.3, 0.8, cellsPerPixel);
    major *= 1.0 - smoothstep(0.3, 0.8, cellsPerPixel);

    float3 col = grid.colorThin;
    float alpha = minor * 0.35;

    col = lerp(col, grid.colorThick, major); 
    alpha = lerp(alpha, 0.7, major);

    //col = lerp(col, grid.colorAxisY, axY); 
    //alpha = lerp(alpha, 0.9, axY);

    //col = lerp(col, grid.colorAxisX, axX); 
    //alpha = lerp(alpha, 0.9, axX);

    alpha *= 1.0 - smoothstep(grid.fadeStart, grid.fadeEnd, length(p - rOrigin));

    if (alpha < 0.002) discard;
    return float4(col, alpha);
}

