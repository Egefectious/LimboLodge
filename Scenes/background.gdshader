shader_type canvas_item;

uniform vec3 color_deep : source_color = vec3(0.02, 0.01, 0.05); // Deep Void
uniform vec3 color_mid  : source_color = vec3(0.15, 0.05, 0.25); // Purple Haze
uniform vec3 color_high : source_color = vec3(0.3, 0.1, 0.4);    // Highlights

// Rotates UV coordinates to create swirling
vec2 rotate(vec2 uv, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

// Simple hash noise
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// Value Noise
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian Motion for smoke details
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        st = rotate(st, 0.5); // Swirl each layer
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV;
    
    // Warping logic: The coordinates themselves move
    vec2 warp = vec2(0.0);
    warp.x = fbm(uv + vec2(TIME * 0.05, TIME * 0.02));
    warp.y = fbm(uv + vec2(TIME * 0.02, TIME * 0.06));
    
    // Sample the noise with warped coordinates
    float fog = fbm(uv * 3.0 + warp * 1.5);
    
    // Color Grading
    vec3 final_color = mix(color_deep, color_mid, fog);
    // Add bright highlights at peaks
    final_color = mix(final_color, color_high, smoothstep(0.6, 1.0, fog));
    
    // Vignette (Darken edges)
    float dist = distance(uv, vec2(0.5));
    float vignette = 1.0 - smoothstep(0.5, 1.2, dist);
    final_color *= vignette;
    
    // Scanline Effect (Subtle retro feel)
    float scanline = sin(uv.y * 600.0) * 0.04;
    final_color -= scanline;

    COLOR = vec4(final_color, 1.0);
}