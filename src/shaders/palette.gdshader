shader_type canvas_item;

uniform sampler2D palette : hint_default_black; // Insert a palette from lospec for instance
uniform int palette_size = 16;


void fragment(){ 
	vec4 color = texture(TEXTURE, UV);
	vec4 new_color = vec4(.0);
	
	for (int i = 0; i < palette_size; i++) {
		vec4 palette_color = texture(palette, vec2((float(i) + .5) / float(palette_size), .0));
		if (distance(palette_color, color) < distance(new_color, color)) {
			new_color = palette_color;
		}
	}
	
	COLOR = new_color;
	COLOR.a = color.a;
}