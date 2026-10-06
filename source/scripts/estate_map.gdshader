shader_type canvas_item;
uniform sampler2D restored_map : source_color, filter_linear;
uniform vec2 points[24];
uniform float weights[24];
uniform bool house=false;
uniform float central[6];
void fragment() {
	float closest=100.0;
	float restored=0.0;
	for(int i=0;i<24;i++) {
		vec2 delta=(UV-points[i])*vec2(1.5,1.0);
		float d=dot(delta,delta);
		if(d<closest) {closest=d;restored=weights[i];}
	}
	float area=house ? 1.0 : 1.0-smoothstep(0.0121,0.0324,closest);
	restored*=area;
	if(!house) {
		vec2 centers[6]={vec2(.393,.295),vec2(.49,.66),vec2(.52,.448),vec2(.747,.334),vec2(.35,.50),vec2(.67,.50)};
		vec2 radii[6]={vec2(.062,.086),vec2(.073,.075),vec2(.070,.077),vec2(.03,.04),vec2(.097,.092),vec2(.058,.067)};
		for(int i=0;i<6;i++) {
			vec2 q=(UV-centers[i])/radii[i];
			restored=max(restored,central[i]*(1.0-smoothstep(.65,1.2,dot(q,q))));
		}
	}
	COLOR=mix(texture(TEXTURE,UV),texture(restored_map,UV),restored);
}
