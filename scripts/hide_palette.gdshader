shader_type canvas_item;
uniform vec4 jacket : source_color;
uniform vec4 hair : source_color;
uniform float head_top[16];
void fragment() {
	vec4 c = texture(TEXTURE,UV);
	vec2 cell = fract(UV*4.0);
	int index = int(floor(UV.y*4.0))*4+int(floor(UV.x*4.0));
	if (c.g>c.r*1.15 && c.b>c.r*1.1) {
		c.rgb = jacket.rgb*(0.35+max(c.g,c.b)*1.4);
	} else if (cell.y*48.0 < head_top[index]+11.0 && c.r<0.35 && c.g<0.30 && c.b<0.27 && c.a>0.5) {
		c.rgb = hair.rgb*(0.55+max(c.r,max(c.g,c.b))*1.5);
	}
	COLOR = c;
}
