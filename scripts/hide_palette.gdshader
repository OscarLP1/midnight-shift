shader_type canvas_item;
uniform vec4 jacket : source_color;
uniform vec4 hair : source_color;
uniform float head_top[16];
uniform float depth = 0.0;
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec4 c = texture(TEXTURE,UV);
	vec2 cell = fract(UV*4.0);
	int index = int(floor(UV.y*4.0))*4+int(floor(UV.x*4.0));
	if (c.g>c.r*1.15 && c.b>c.r*1.1) {
		c.rgb = jacket.rgb*(0.35+max(c.g,c.b)*1.4);
	} else if (cell.y*48.0 < head_top[index]+11.0 && c.r<0.35 && c.g<0.30 && c.b<0.27 && c.a>0.5) {
		c.rgb = hair.rgb*(0.55+max(c.r,max(c.g,c.b))*1.5);
	}
	float inside = step(98.0,world_position.x)*step(world_position.x,128.0)*step(235.0,world_position.y)*step(world_position.y,255.0);
	float entering = smoothstep(0.35,0.85,depth);
	c.a *= mix(1.0,inside,entering);
	float shade = mix(1.0,0.55,depth);
	c.rgb *= vec3(shade,shade*0.96,shade*0.91);
	COLOR = c;
}
