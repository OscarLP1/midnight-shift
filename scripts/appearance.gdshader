shader_type canvas_item;
uniform sampler2D head : filter_nearest;
uniform vec4 jacket : source_color;
uniform vec4 hair : source_color;
void fragment() {
	vec2 cell = fract(UV * 4.0);
	vec4 c = texture(TEXTURE,UV);
	if (cell.y < 0.34) {
		c = texture(head,UV);
		bool skin = c.r > c.g * 1.12 && c.g > c.b * 1.12 && c.r > 0.38;
		if (!skin && c.a>0.5) c.rgb = hair.rgb * (0.55+max(c.r,max(c.g,c.b))*1.5);
	} else if (cell.y < 0.72 && c.a>0.5) {
		bool teal = c.g>c.r*1.2 && c.b>c.r*1.15;
		bool fabric = c.b>c.g*1.06 && c.r>c.g*1.06;
		if (teal || fabric) c.rgb = jacket.rgb * (0.35+max(c.r,max(c.g,c.b))*1.4);
	}
	COLOR = c;
}
