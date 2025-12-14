shader_type canvas_item;

uniform vec3 color_base : source_color = vec3(0.04, 0.02, 0.07); // #0a0612
uniform vec3 color_fog_1 : source_color = vec3(0.42, 0.11, 0.6); // Purple
uniform vec3 color_fog_2 : source_color = vec3(0.29, 0.0, 0.51); // Darker Purple

void fragment() {
    vec2 uv = UV;
    // Animate fog layers
    float noise1 = sin(uv.x * 5.0 + TIME * 0.2) * cos(uv.y * 5.0 + TIME * 0.1);
    float noise2 = sin(uv.x * 3.0 - TIME * 0.15) * cos(uv.y * 7.0 + TIME * 0.25);

    // Mix base with fog
    vec3 final_color = mix(color_base, color_fog_1, (noise1 + 1.0) * 0.1);
    final_color = mix(final_color, color_fog_2, (noise2 + 1.0) * 0.1);

    // Vignette (Darken corners)
    float dist = distance(uv, vec2(0.5));
    final_color *= (1.0 - smoothstep(0.4, 0.9, dist));

    COLOR = vec4(final_color, 1.0);
}