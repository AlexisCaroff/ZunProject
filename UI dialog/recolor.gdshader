shader_type canvas_item;

// Recolore une image à deux tons : chaque pixel est situé entre src_a et
// src_b (projection), puis remplacé par la même position entre dst_a et
// dst_b. Alpha conservé. Avec dst = src, l'image reste inchangée.
uniform vec4 src_a : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 src_b : source_color = vec4(1.0);
uniform vec4 dst_a : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 dst_b : source_color = vec4(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 d = src_b.rgb - src_a.rgb;
	float len2 = max(dot(d, d), 1e-5);
	float t = clamp(dot(c.rgb - src_a.rgb, d) / len2, -0.5, 1.5);
	vec3 rgb = mix(dst_a.rgb, dst_b.rgb, t);
	COLOR = vec4(clamp(rgb, 0.0, 1.0), c.a) * vec4(1.0, 1.0, 1.0, COLOR.a);
}
