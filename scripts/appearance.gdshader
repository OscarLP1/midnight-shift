shader_type canvas_item;
uniform sampler2D head : filter_nearest;
uniform float columns = 4.0;
uniform bool same_head = false;
uniform vec4 jacket : source_color;
uniform vec4 hair : source_color;
void fragment() {
	vec2 cell = fract(UV * 4.0);
	vec4 c = texture(TEXTURE,UV);
	if (cell.y < 0.34) {
		float source_column = floor(floor(UV.x*columns)*4.0/columns);
		vec2 head_uv = vec2((source_column+fract(UV.x*columns))/4.0,UV.y);
		if (!same_head) c = texture(head,head_uv);
		bool skin = c.r > c.g * 1.12 && c.g > c.b * 1.12 && c.r > 0.38;
		if (!skin && c.a>0.5) c.rgb = hair.rgb * (0.55+max(c.r,max(c.g,c.b))*1.5);
	} else if (cell.y < 0.72 && c.a>0.5) {
		bool teal = c.g>c.r*1.2 && c.b>c.r*1.15;
		bool fabric = c.b>c.g*1.06 && c.r>c.g*1.06;
		if (teal || fabric) c.rgb = jacket.rgb * (0.35+max(c.r,max(c.g,c.b))*1.4);
	}
	COLOR = c;
}
