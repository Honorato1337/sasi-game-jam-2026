shader_type canvas_item;

uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float fog_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fog_color : source_color = vec4(0.18, 0.13, 0.27, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	vec3 obscured = mix(tex.rgb, fog_color.rgb, fog_amount);
	tex.rgb = mix(obscured, vec3(1.0), hit_flash);
	COLOR = tex;
}
