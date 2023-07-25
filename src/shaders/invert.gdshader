shader_type canvas_item;

uniform vec4 main_color : source_color = vec4(1.0);
uniform vec4 invert_color : source_color = vec4(1.0);


vec4 invert(vec4 color) {
	if (color.rgba == main_color.rgba) {
		return invert_color;
	} else if (color.rgba == invert_color) {
		return main_color;
	}
	
	return color;
}

void fragment() {
	vec2 uv = UV;
	vec4 color = texture(TEXTURE, uv);
	
	COLOR = invert(color);
	
}
