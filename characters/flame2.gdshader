shader_type canvas_item;

uniform sampler2D deform_texture;
uniform float deform_strength = 0.05;
uniform float scroll_speed = 1.0;

void fragment() {
    vec2 uv = UV;

    // UV de déformation animées et tileables
    vec2 deform_uv = UV*0.5;
    deform_uv.y += TIME * scroll_speed;
    deform_uv = fract(deform_uv);

    // Lecture de la noise
    vec2 deform = texture(deform_texture, deform_uv).rg - 0.5;

    // Masque vertical (fort en haut, nul en bas)
    float vertical_mask = 1.0 - UV.y;

    // Application du masque
    uv += deform * deform_strength * vertical_mask;

    COLOR = texture(TEXTURE, uv);
}