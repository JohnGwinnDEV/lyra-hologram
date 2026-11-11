shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D strand_texture : source_color, filter_linear_mipmap_anisotropic;
uniform float fiber_brightness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 strand = texture(strand_texture, UV);
	float luminance = dot(strand.rgb, vec3(0.2126, 0.7152, 0.0722));
	// Keep silver below white so texture survives the key and rim lights.
	float detail = 0.46 + 0.54 * sqrt(clamp(luminance, 0.0, 1.0));
	// Retain slate undertones in the darker fibers instead of lifting all
	// texture values to pale silver. The bright surface strands stay silver.
	float undertone = (1.0 - smoothstep(0.012, 0.13, luminance)) * 0.72;
	ALBEDO = mix(vec3(0.84, 0.86, 0.91), vec3(0.17, 0.20, 0.26), undertone) * detail;
	// Sparse white fibers run along the existing hair-card texture direction.
	// Filter their contrast at distance so the threads do not become moire.
	float phase = UV.x * 530.0 + sin(UV.y * 12.0) * 0.35;
	float footprint = fwidth(phase);
	float resolved = exp(-0.125 * footprint * footprint);
	float white_fiber = smoothstep(0.72, 0.96, sin(phase)) * resolved;
	white_fiber *= 0.90 + 0.10 * sin(UV.y * 17.0 + UV.x * 23.0);
	ALBEDO = mix(ALBEDO, vec3(0.96, 0.98, 1.0), white_fiber * 0.96);
	EMISSION = vec3(0.80, 0.90, 1.0) * white_fiber * 0.22 * fiber_brightness;
	ALPHA = strand.a;
	ALPHA_SCISSOR_THRESHOLD = 0.35;
	ROUGHNESS = 0.44 + (1.0 - detail) * 0.08;
	SPECULAR = 0.38;
	METALLIC = 0.0;
}
