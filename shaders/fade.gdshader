shader_type canvas_item;

uniform float edge_fade : hint_range(0.0, 0.5) = 0.178; // how much to fade near the edge

void fragment() {
	vec2 uv = UV;
	
	float dist_to_edge = min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y));
	float fade = smoothstep(0.0, edge_fade,dist_to_edge);

    COLOR.a *= fade;
}