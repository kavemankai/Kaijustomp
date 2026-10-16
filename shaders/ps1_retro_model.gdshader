shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, vertex_lighting;

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec2 snap_resolution = vec2(320.0, 240.0);
uniform float affine_warp_factor : hint_range(0.0, 1.0) = 1.0;

varying vec2 affine_uv;
varying float clip_w;

void vertex() {
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 ndc_pos = clip_pos.xy / clip_pos.w;
	vec2 snapped_ndc = floor(ndc_pos * snap_resolution + 0.5) / snap_resolution;
	clip_pos.xy = snapped_ndc * clip_pos.w;
	POSITION = clip_pos;
	clip_w = mix(1.0, clip_pos.w, affine_warp_factor);
	affine_uv = UV * clip_w;
}

void fragment() {
	vec2 corrected_uv = affine_uv / clip_w;
	vec4 tex_color = texture(albedo_tex, corrected_uv);
	ALBEDO = tex_color.rgb * base_color.rgb * COLOR.rgb;
	ALPHA = tex_color.a * base_color.a;
}
