shader_type canvas_item;
uniform vec4 jacket : source_color = vec4(0.65,0.32,0.24,1.0);
uniform vec4 hair : source_color = vec4(0.26,0.20,0.17,1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Only recolor the teal fabric; skin, trousers, shoes and badge keep their shading.
	if (c.g > c.r * 1.20 && c.b > c.r * 1.15 && c.g > 0.12) {
		float shade = max(c.g, c.b);
		c.rgb = jacket.rgb * shade * 1.65;
	}
	vec2 cell = fract(UV * vec2(4.0,4.0));
	if (cell.y < 0.27 && c.r < 0.30 && c.g < 0.27 && c.b < 0.29 && c.a > 0.5) {
		c.rgb = hair.rgb * (0.5 + max(c.r,max(c.g,c.b))*2.0);
	}
	COLOR = c;
}
