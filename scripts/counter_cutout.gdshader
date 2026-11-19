shader_type canvas_item;
// Discard the rectangular floor baked into the prop. Coordinates are source pixels.
void fragment() {
    vec2 p = UV * vec2(96.0,61.0);
    float top = 29.0;
    if (p.x >= 3.0 && p.x < 28.0) top = 9.0;
    if (p.x >= 32.0 && p.x < 60.0) top = 2.0;
    if (p.x >= 28.0 && p.x < 63.0 && p.y >= 23.0) top = 23.0;
    if (p.x >= 63.0 && p.x < 71.0) top = 15.0;
    if (p.x >= 75.0 && p.x < 91.0) top = 10.0;
    vec4 c = texture(TEXTURE, UV);
    if (p.y < top || p.y > 59.0 || (p.y > 34.0 && (p.x < 2.0 || p.x > 94.0))) c.a = 0.0;
    COLOR = c;
}
