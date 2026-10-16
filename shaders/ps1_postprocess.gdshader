shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float color_depth = 32.0;
uniform float distortion_amount : hint_range(0.0, 0.5) = 0.06;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.18;

const mat4 BAYER_PATTERN = mat4(
	vec4(-0.5000,  0.2500, -0.3125,  0.4375),
	vec4( 0.0000, -0.2500,  0.1875, -0.0625),
	vec4(-0.3750,  0.3750, -0.4375,  0.3125),
	vec4( 0.1250, -0.1250,  0.0625, -0.1875)
);

vec2 apply_barrel_distortion(vec2 uv, float distortion) {
	vec2 cc = uv - vec2(0.5);
	float dist = dot(cc, cc);
	return uv + cc * dist * distortion;
}

void fragment() {
	vec2 distorted_uv = apply_barrel_distortion(SCREEN_UV, distortion_amount);
	if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec4 raw_color = texture(screen_texture, distorted_uv);
		ivec2 pixel_pos = ivec2(FRAGCOORD.xy) % 4;
		float dither_offset = BAYER_PATTERN[pixel_pos.x][pixel_pos.y];
		vec3 dithered_color = raw_color.rgb + vec3(dither_offset / color_depth);
		vec3 quantized_color = floor(dithered_color * color_depth) / color_depth;
		float scanline = sin(distorted_uv.y * 240.0 * 3.14159 * 2.0) * 0.5 + 0.5;
		quantized_color -= scanline * scanline_opacity * quantized_color;
		COLOR = vec4(quantized_color, 1.0);
	}
}
