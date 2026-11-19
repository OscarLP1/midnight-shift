shader_type canvas_item;
uniform sampler2D dry_exterior : filter_nearest;
void fragment() {
    vec4 base = texture(TEXTURE, UV);
    // Keep the original interior and collision-aligned artwork pixel-perfect.
    if (UV.y >= 297.0 / 360.0 || (UV.y >= 40.0 / 360.0 && (UV.x < 22.0 / 640.0 || UV.x >= 618.0 / 640.0))) base = texture(dry_exterior, UV);
    COLOR = base;
}
