shader_type canvas_item;

uniform sampler2D deform_texture;
uniform float deform_strength_x = 0.05; // influence sur X
uniform float deform_strength_y = 0.02; // influence sur Y
uniform float scroll_speed = 0.2;

void fragment() {
    vec2 uv = UV;

    // --- UV de la texture de déformation ---
    vec2 deform_uv = UV * 0.5;          // texture 2x plus grande
    deform_uv.y += TIME * scroll_speed; // défilement vertical
    deform_uv = fract(deform_uv);       // wrapping

    // Lecture de la texture de déformation
    vec2 deform = texture(deform_texture, deform_uv).rg - 0.5;

    // Masque vertical (fort en haut, nul en bas)
    float vertical_mask = 1.0 - UV.y;

    // Déformation avec influences séparées
    uv.x += deform.x * deform_strength_x * vertical_mask;
    uv.y += deform.y * deform_strength_y * vertical_mask;

    COLOR = texture(TEXTURE, uv);
}