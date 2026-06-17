
varying vec2 vUv;

uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform vec2 u_imageResolution;
uniform float u_time;
uniform vec2 u_trail[20];

uniform float uSpeed;
uniform float uNoiseScale;
uniform float uWarpAmount;
uniform float uFoldFrequency;
uniform float uAngle;
uniform float uConnections;
uniform float uDepth;
uniform vec3 uLightPos;

// --- Ashima's 3D Simplex Noise ---
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
    const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 = v - i + dot(i, C.xxx) ;
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy; 
    vec3 x3 = x0 - D.yyy;      
    i = mod289(i);
    vec4 p = permute( permute( permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
            + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
            + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
    float n_ = 0.142857142857;
    vec3  ns = n_ * D.wyz - D.xzx;
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z); 
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    
    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
}

float getSurface(vec2 p) {
    float c = cos(uAngle), s = sin(uAngle);
    mat2 rot = mat2(c, -s, s, c);
    vec2 rp = rot * p;
    float n1 = snoise(vec3(rp * uNoiseScale * 0.25, u_time * uSpeed * 0.7));
    float n2 = snoise(vec3(rp * uNoiseScale * 0.25 + vec2(21.4, 15.2), u_time * uSpeed * 0.9));
    float trig1 = sin(rp.x * uNoiseScale * 0.5 + u_time * uSpeed) * 0.3;
    float trig2 = cos(rp.y * uNoiseScale * 0.5 - u_time * uSpeed) * 0.3;
    vec2 flow = vec2(n1 + trig1, n2 + trig2);
    vec2 wp = rp + flow * (uWarpAmount * 0.12);
    float freq = uFoldFrequency * 0.5;
    float phase = sin(wp.y * freq + flow.y * 2.0) * uConnections;
    float mainWave = sin(wp.x * freq + phase * uWarpAmount * 0.3);
    float n3 = snoise(vec3(wp * 0.5, u_time * uSpeed * 0.5));
    return (mainWave * 0.85 + n3 * 0.15) * 0.5;
}

void main() {
    // 1. 비율 및 Fluid 기본 굴절 계산
    vec2 ratio = vec2(max(u_resolution.x / u_imageResolution.x, u_resolution.y / u_imageResolution.y));
    ratio *= 1.1; 
    
    vec2 uvCover = (vUv - 0.5) * u_resolution / (u_imageResolution * ratio) + 0.5;

    vec2 p = vUv * 2.0 - 1.0;
    p.x *= u_resolution.x / u_resolution.y;

    vec2 e = vec2(0.09, 0.0);
    float dx = (getSurface(p + e.xy) - getSurface(p - e.xy)) / (2.0 * e.x);
    float dy = (getSurface(p + e.yx) - getSurface(p - e.yx)) / (2.0 * e.x);
    vec2 fluidDistortion = vec2(-dx, -dy) * 0.05;

    // ----------------------------------------------------------------
    // 2. 마우스 잔상 영역
    // ----------------------------------------------------------------
    float trailArea = 0.0;
    vec2 trailDistort = vec2(0.0);

    for(int i = 0; i < 20; i++) {
        float dist = distance(vUv, u_trail[i]);
        float weight = 1.0 - (float(i) / 20.0); 
        
        // 숫자 클수록 잔상 경계 영역 넓어짐
        float pointArea = smoothstep(0.12, 0.0, dist); 
        trailArea += pointArea * weight;

        vec2 dir = vUv - u_trail[i];
        
        // 숫자 작을수록 굴절 강도 낮아짐
        trailDistort += dir * pointArea * weight * 0.04; 
    }
    trailArea = clamp(trailArea, 0.0, 1.0);

    // 원본 이미지 좌표에 Fluid 왜곡과 '마우스 굴절'을 모두 더해줌
    vec2 finalUv = uvCover + fluidDistortion - trailDistort;
    vec3 baseColor = texture2D(u_texture, finalUv).rgb;

    // Fluid 입체감(명암) 추가
    float safeDepth = max(uDepth, 0.02);
    vec3 normal = normalize(vec3(-dx, -dy, safeDepth));
    vec3 lightDir = normalize(uLightPos);
    float diffuse = dot(normal, lightDir) * 0.5 + 0.5;
    baseColor *= mix(0.7, 1.3, diffuse);

    // ----------------------------------------------------------------
    // 3. 진정한 하프톤(Halftone) 이미지 변형 
    // ----------------------------------------------------------------
    float dotSize = 10.0; // 하프톤 도트의 크기
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 center = floor(fragCoord / dotSize) + 0.5;
    vec2 gridPos = (fragCoord / dotSize) - center; 
    float distToCenter = length(gridPos); 

    // 이미지의 밝기 추출 (어두울수록 0.0, 밝을수록 1.0)
    float lum = dot(baseColor, vec3(0.299, 0.587, 0.114));

    // 하프톤의 핵심: 어두운 곳은 도트가 굵고(0.75), 밝은 곳은 도트가 얇음(0.0)
    float maxRadius = 0.85;
    float targetRadius = (1.0 - lum) * maxRadius;

    // 덧씌우기를 없애는 구간
    // 잔상이 없는 곳(trailArea = 0)은 도트 반지름을 1.0으로 강제해서 빈틈없이 원본 이미지를 보여주고,
    // 잔상이 있는 곳은 targetRadius로 서서히 분해시킴.
    float dynamicRadius = mix(1.0, targetRadius, trailArea);

    // 원형 도트 마스크 (가장자리 안티앨리어싱)
    float isDot = smoothstep(dynamicRadius + 0.08, dynamicRadius - 0.08, distToCenter);

    // 하프톤의 바탕이 되는 종이 색상 (여기서는 깔끔한 화이트)
    vec3 paperColor = vec3(1.0); 

    // 최종 색상: 투명도로 섞는 게 아니라, 조건에 따라 색을 완전히 갈라냄
    vec3 finalColor = mix(paperColor, baseColor, isDot);

    gl_FragColor = vec4(finalColor, 1.0);
}