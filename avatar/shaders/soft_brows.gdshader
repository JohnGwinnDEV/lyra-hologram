shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D brow_texture : source_color, filter_linear_mipmap_anisotropic;

void fragment() {
	vec4 brow = texture(brow_texture, UV);
	float detail = dot(brow.rgb, vec3(0.2126, 0.7152, 0.0722));
	// Lift black fibers toward a softer ash brown without painting the skin.
	ALBEDO = mix(vec3(0.22, 0.19, 0.17), vec3(0.34, 0.30, 0.27), detail);
	ALPHA = brow.a;
	ALPHA_SCISSOR_THRESHOLD = 0.35;
	ROUGHNESS = 0.75;
	SPECULAR = 0.18;
}
