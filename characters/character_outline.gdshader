shader_type canvas_item;

uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(0.805, 0.77, 0.720, 1.0); // #EEB466
// Épaisseur du contour en pixels (sample dans les 8 directions)
uniform float outline_width : hint_range(1.0, 200.0) = 4.0;
// Décalage de l'outline en pixels : vec2(0,-10)=haut  vec2(0,10)=bas  vec2(10,0)=droite
uniform vec2 outline_direction = vec2(0.0, -5.0);

void fragment() {
	vec4 current = texture(TEXTURE, UV);

	if (enabled) {
		vec2 ps = TEXTURE_PIXEL_SIZE;

		// Le décalage déplace le point de lecture du sprite, ce qui fait apparaître
		// l'outline dans la direction opposée (on soustrait pour décaler "vers" la direction)
		vec2 shift = outline_direction * ps;

		float n  = texture(TEXTURE, UV - shift + vec2( 0.0,           -outline_width) * ps).a;
		float s  = texture(TEXTURE, UV - shift + vec2( 0.0,            outline_width) * ps).a;
		float e  = texture(TEXTURE, UV - shift + vec2( outline_width,  0.0          ) * ps).a;
		float w  = texture(TEXTURE, UV - shift + vec2(-outline_width,  0.0          ) * ps).a;
		float ne = texture(TEXTURE, UV - shift + vec2( outline_width, -outline_width) * ps).a;
		float nw = texture(TEXTURE, UV - shift + vec2(-outline_width, -outline_width) * ps).a;
		float se = texture(TEXTURE, UV - shift + vec2( outline_width,  outline_width) * ps).a;
		float sw = texture(TEXTURE, UV - shift + vec2(-outline_width,  outline_width) * ps).a;

		float alpha_max = max(max(max(n, s), max(e, w)), max(max(ne, nw), max(se, sw)));

		if (current.a < 0.01 && alpha_max > 0.01) {
			COLOR = vec4(outline_color.rgb, outline_color.a * alpha_max);
		} else {
			COLOR = current;
		}
	} else {
		COLOR = current;
	}
}
