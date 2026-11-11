shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform float fiber_brightness : hint_range(0.0, 1.0) = 1.0;

varying vec3 lock_position;

void vertex() {
	// Object coordinates keep this detail attached to the skinned hair.
	lock_position = VERTEX;
}

void fragment() {
	// Fine vertical streaks suggest fibers on the existing tapered locks.
	// Fade detail below pixel resolution rather than allowing it to shimmer.
	float phase = (lock_position.x + lock_position.z * 0.37) * 2000.0
		+ sin(lock_position.y * 14.0) * 0.7;
	float footprint = fwidth(phase);
	float resolved = exp(-0.125 * footprint * footprint);
	float strand = sin(phase) * 0.5 + 0.5;
	float detail = mix(0.5, strand, resolved);
	float layer = sin(lock_position.x * 85.0 + lock_position.z * 40.0);
	float undertone = smoothstep(0.1, 0.9, layer) * 0.38;
	ALBEDO = mix(vec3(0.68, 0.71, 0.77), vec3(0.22, 0.26, 0.33), undertone)
		* (0.96 + detail * 0.08);
	float white_phase = (lock_position.x + lock_position.z * 0.37) * 800.0
		+ sin(lock_position.y * 14.0) * 0.7;
	float white_footprint = fwidth(white_phase);
	float white_fiber = smoothstep(0.72, 0.96, sin(white_phase))
		* exp(-0.125 * white_footprint * white_footprint);
	ALBEDO = mix(ALBEDO, vec3(0.96, 0.98, 1.0), white_fiber * 0.96);
	EMISSION = vec3(0.80, 0.90, 1.0) * white_fiber * 0.22 * fiber_brightness;
	ROUGHNESS = 0.46 + (1.0 - detail) * 0.08;
	SPECULAR = 0.36;
	METALLIC = 0.0;
}
