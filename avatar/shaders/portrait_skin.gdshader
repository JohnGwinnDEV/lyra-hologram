shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D skin_texture : source_color, filter_linear_mipmap_anisotropic;

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float soft_grain(vec2 p) {
	vec2 cell = floor(p);
	vec2 t = fract(p);
	t = t * t * (3.0 - 2.0 * t);
	return mix(mix(grain(cell), grain(cell + vec2(1.0, 0.0)), t.x),
		mix(grain(cell + vec2(0.0, 1.0)), grain(cell + vec2(1.0)), t.x), t.y);
}

void fragment() {
	vec3 skin = texture(skin_texture, UV).rgb;
	// Preserve the photographed base variation; pores should not read as glitter.
	ALBEDO = skin * vec3(0.90, 0.84, 0.80);
	vec2 pore_uv = UV * 1500.0;
	float resolved = 1.0 - smoothstep(0.5, 1.5, length(fwidth(pore_uv)));
	float pore = (soft_grain(pore_uv) - 0.5) * resolved;
	float variation = soft_grain(UV * 95.0) - 0.5;
	ROUGHNESS = 0.59 + variation * 0.05 + pore * 0.035;
	SPECULAR = 0.32;
	METALLIC = 0.0;
	NORMAL_MAP = vec3(0.5 + pore * 0.008,
		0.5 + (soft_grain(pore_uv + vec2(13.0, 29.0)) - 0.5) * resolved * 0.008, 1.0);
	NORMAL_MAP_DEPTH = 0.12;
}
