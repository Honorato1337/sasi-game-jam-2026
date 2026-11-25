shader_type canvas_item;

uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float fog_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fog_color : source_color = vec4(0.02, 0.015, 0.03, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 base_rgb = mix(tex.rgb * COLOR.rgb, fog_color.rgb, fog_amount);
	vec3 final_rgb = mix(base_rgb, vec3(1.0), hit_flash);
	COLOR = vec4(final_rgb, tex.a * COLOR.a);
}
