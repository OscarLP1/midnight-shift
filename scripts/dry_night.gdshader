shader_type canvas_item;
uniform sampler2D dry_exterior : filter_nearest;
uniform sampler2D clean_fridges : filter_nearest;
void fragment() {
    vec4 base = texture(TEXTURE, UV);
    // Surgical interior-only patch: outside rails, floor, walls and props stay original.
    vec2 p = UV*vec2(640.0,360.0);
    bool interior_x = (p.x>=48.0 && p.x<152.0) || (p.x>=164.0 && p.x<265.0) || (p.x>=277.0 && p.x<377.0) || (p.x>=391.0 && p.x<485.0) || (p.x>=498.0 && p.x<593.0);
    if (interior_x && p.y>=58.0 && p.y<83.0) base = texture(clean_fridges,UV);
    // Keep the original interior and collision-aligned artwork pixel-perfect.
    if (UV.y >= 297.0 / 360.0 || (UV.y >= 40.0 / 360.0 && (UV.x < 22.0 / 640.0 || UV.x >= 618.0 / 640.0))) base = texture(dry_exterior, UV);
    COLOR = base;
}
