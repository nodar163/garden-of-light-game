shader_type canvas_item;
uniform sampler2D restored_map : source_color, filter_linear;
uniform vec4 zones[6];
uniform float restorations[6];
uniform float complete = 0.0;
void fragment() {
	float restored = complete;
	for (int i=0; i<6; i++) {
		vec2 center = zones[i].xy + zones[i].zw*0.5;
		vec2 q = abs(UV-center)-zones[i].zw*0.5;
		float distance_to_edge = max(q.x,q.y);
		float mask = 1.0-smoothstep(-0.013,0.013,distance_to_edge);
		restored=max(restored,mask*restorations[i]);
	}
	COLOR=mix(texture(TEXTURE,UV),texture(restored_map,UV),restored);
}
