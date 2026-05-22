shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.05;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV).rgb;
	
	// Film grain
	float noise = random(SCREEN_UV + TIME * 0.1) * 2.0 - 1.0;
	col += noise * grain_intensity;
	
	// Vignette
	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	float vignette = 1.0 - dot(uv, uv) * 0.3 * vignette_intensity;
	col *= clamp(vignette, 0.0, 1.0);
	
	// Scanlines
	float scanline = sin(SCREEN_UV.y * 800.0 + TIME * 2.0) * 0.5 + 0.5;
	col *= 1.0 - (1.0 - scanline) * scanline_intensity;
	
	// Slight green-yellow tint for backrooms sickness
	col.r *= 0.98;
	col.g *= 1.02;
	col.b *= 0.95;
	
	COLOR = vec4(col, 1.0);
}
