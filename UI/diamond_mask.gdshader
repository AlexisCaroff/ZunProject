shader_type canvas_item;

// Découpe la texture en losange, pour que les portraits épousent le cadre
// doré de UI_affinity_portait_frame.png sans avoir à redessiner les images.

uniform float feather : hint_range(0.0, 0.2) = 0.012;

void fragment() {
	vec2 d = abs(UV - vec2(0.5));
	float edge = d.x + d.y;
	COLOR.a *= 1.0 - smoothstep(0.5 - feather, 0.5, edge);
}
