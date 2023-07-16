shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform vec4 fill_color : source_color = vec4(1.0);
uniform vec4 swap_color : source_color = vec4(1.0);
uniform float width : hint_range(0, 20) = 1.0;
uniform float shadow_threshold : hint_range(0, 255) = 80.0;
uniform int pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool inside = false;
uniform bool add_margins = true; // only useful when inside is false

void vertex() {
	if (add_margins) {
		VERTEX += (UV * 2.0 - 1.0) * width;
	}
}

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	for (float i = -ceil(width); i <= ceil(width); i++) {
		float x = abs(i) > width ? width * sign(i) : i;
		float offset;
		
		if (pattern == 0) {
			offset = width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = width;
		}
		
		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);
			
			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a == 0.0) == inside) {
				return true;
			}
		}
	}
	
	return false;
}

void fragment() {
	vec2 uv = UV;
	
	if (add_margins) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));
		
		uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
		
		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv);
		}
	} else {
		COLOR = texture(TEXTURE, uv);
		if (fill_color.rgba == COLOR.rgba) {
			COLOR.rgba = swap_color.rgba;
		} else if (COLOR.r == COLOR.b && COLOR.b == COLOR.g && COLOR.a == fill_color.a) { // shadows
			float offset = abs(COLOR.r - fill_color.r);
			if (offset <= shadow_threshold) {
				COLOR.rgb = swap_color.rgb - offset;
				COLOR.a = swap_color.a;
			}
		}
	}
	
	if ((COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		COLOR.rgb = inside ? mix(COLOR.rgb, outline_color.rgb, outline_color.a) : outline_color.rgb;
		COLOR.a += (1.0 - COLOR.a) * outline_color.a;
	}
}