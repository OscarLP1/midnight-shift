shader_type canvas_item;
uniform vec2 leaf_origin = vec2(0.0,10.0);
void fragment() {
    vec4 c = texture(TEXTURE,UV);
    vec2 p = UV*vec2(416.0,64.0)-leaf_origin;
    // Frame geometry is local to each whole leaf, never to a cut piece of glass.
    float edge = min(min(p.x,52.0-p.x),min(p.y,34.0-p.y));
    float glint = smoothstep(0.5,0.95,min(c.g,c.b))*smoothstep(0.3,0.75,c.r);
    c = vec4(0.52,0.85,0.91,0.035+glint*0.09);
    if (edge<2.0) c = vec4(0.12,0.24,0.30,1.0);
    if (edge>=1.0 && edge<2.0) c = vec4(0.43,0.64,0.69,0.95);
    // Sliding guide mounts sit at the four frame corners, outside the glass pane.
    bool corner_x = p.x<3.0 || p.x>49.0;
    bool corner_y = p.y<4.0 || p.y>30.0;
    if (corner_x && corner_y) c = vec4(0.62,0.72,0.73,1.0);
    if (corner_x && (p.y<1.0 || p.y>33.0)) c = vec4(0.2,0.3,0.33,1.0);
    // Recessed pull remains attached to the right vertical stile.
    if (p.x>49.0 && p.x<51.0 && p.y>12.0 && p.y<22.0) c = vec4(0.8,0.87,0.86,1.0);
    COLOR = c;
}
