shader_type canvas_item;

// texture to scroll
uniform sampler2D custom_texture;
uniform vec4 inactive_color : source_color;
uniform float active : hint_range(0,1);
uniform float scroll_speed;

uniform vec4 override_color : source_color;
uniform float override_mix : hint_range(0,1);

varying vec2 coord;

void vertex() {
	coord = VERTEX;
}

void fragment() {
	// Called for every pixel the material is visible on.
	//coord = (UV / SCREEN_PIXEL_SIZE)/3.0;
	vec2 texture_size = vec2(textureSize(custom_texture,0));
	
	vec2 scrolled_coord = coord + vec2(scroll_speed) * TIME;
	vec2 pixel_coord = floor(scrolled_coord) + vec2(0.5, 0.5);
	
	vec4 col = mix(
		inactive_color,
		texture(custom_texture, fract(pixel_coord/texture_size)),
		active
	);
	
	COLOR = mix(
		col,
		override_color,
		override_mix
	);
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
