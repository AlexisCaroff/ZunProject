shader_type canvas_item;

// ── Révélation horizontale ─────────────────────────────────
// 0.0 = caché  |  1.0 = visible
uniform float progress_x : hint_range(0.0, 1.0) = 1.0;
// true = gauche → droite  |  false = droite → gauche
uniform bool left_to_right = true;

// ── Révélation verticale ───────────────────────────────────
// 0.0 = caché  |  1.0 = visible
uniform float progress_y : hint_range(0.0, 1.0) = 1.0;
// true = haut → bas  |  false = bas → haut
uniform bool top_to_bottom = true;

// ── Douceur du bord (partagée) ────────────────────────────
uniform float edge_softness : hint_range(0.0, 0.5) = 0.02;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	float pos_x = left_to_right  ? UV.x : (1.0 - UV.x);
	float pos_y = top_to_bottom  ? UV.y : (1.0 - UV.y);

	float mask_x = 1.0 - smoothstep(progress_x, progress_x + edge_softness, pos_x);
	float mask_y = 1.0 - smoothstep(progress_y, progress_y + edge_softness, pos_y);

	// Les deux masques se combinent : un pixel n'est visible que si les deux l'autorisent
	color.a *= mask_x * mask_y;

	COLOR = color;
}
