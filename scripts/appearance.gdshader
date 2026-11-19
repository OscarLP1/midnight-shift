shader_type canvas_item;
uniform sampler2D head : filter_nearest;
uniform float columns = 4.0;
uniform bool same_head = false;
uniform float haircut = 0.0;
uniform bool female = false;
uniform sampler2D female_head : filter_nearest;
uniform vec4 jacket : source_color;
uniform vec4 hair : source_color;
void fragment() {
	vec2 cell = fract(UV * vec2(columns,4.0));
	vec4 c = texture(TEXTURE,UV);
	if (cell.y < 0.34) {
		float source_column = floor(floor(UV.x*columns)*4.0/columns);
		vec2 head_uv = vec2((source_column+fract(UV.x*columns))/4.0,UV.y);
		// Both versions keep the protagonist face and gait alignment.
		vec2 head_pixel = floor(cell * vec2(32.0,48.0));
		if (female) {
			float frame = floor(UV.x*columns);
			vec2 female_uv = vec2((floor(frame*8.0/columns)+cell.x)/8.0,UV.y);
			c = texture(female_head,female_uv);
		}
		vec2 pixel = floor(cell * vec2(32.0,48.0));
		bool fringe = pixel.y >= 4.0 && pixel.y <= 6.0 && ((haircut==1.0 && pixel.x<15.0 && pixel.x>4.0) || (haircut==2.0 && pixel.x>12.0 && pixel.x<27.0) || (haircut==3.0 && pixel.x>5.0 && pixel.x<27.0 && pixel.y==6.0) || (haircut==4.0 && pixel.x>7.0 && pixel.x<23.0 && pixel.y==4.0) || (haircut==5.0 && pixel.x>10.0 && pixel.x<21.0 && pixel.y==5.0));
		if (fringe && c.a<0.1) c = vec4(hair.rgb*0.72,1.0);
		bool skin = c.r > c.g * 1.12 && c.g > c.b * 1.12 && c.r > 0.38;
		if (!skin && c.a>0.5) c.rgb = hair.rgb * (0.55+max(c.r,max(c.g,c.b))*1.5);
	} else if (cell.y < 0.72 && c.a>0.5) {
		bool teal = c.g>c.r*1.2 && c.b>c.r*1.15;
		bool fabric = c.b>c.g*1.06 && c.r>c.g*1.06;
		if (teal || fabric) c.rgb = jacket.rgb * (0.35+max(c.r,max(c.g,c.b))*1.4);
	}
	COLOR = c;
}
