shader_type spatial;
render_mode cull_disabled;
uniform vec3 path[97];
uniform float body_radius = 0.55;
uniform vec4 skin : source_color = vec4(0.64,0.28,0.21,1.0);
uniform bool worm = false;
uniform float armour = 0.0;
varying float belly;
varying float section;
void vertex() {
	int i = int(round(VERTEX.z));
	vec3 tangent = normalize(path[min(i+1,96)]-path[max(0,i-1)] + vec3(0.0,0.0,0.00001));
	vec3 lateral = normalize(cross(vec3(0.0,1.0,0.001),tangent));
	vec3 up = normalize(cross(tangent,lateral));
	float f = float(i)/96.0;
	float taper = mix(1.0,0.035,pow(f,2.7));
	float ring = worm ? 1.0-0.065*pow(sin(f*150.8),2.0) : 1.0;
	float scale = body_radius*taper*ring;
	belly = VERTEX.y;
	section = f;
	NORMAL = normalize(lateral*VERTEX.x+up*VERTEX.y);
	VERTEX = path[i]+vec3(0.0,body_radius*0.70,0.0)+(lateral*VERTEX.x+up*VERTEX.y)*scale;
}
void fragment() {
	vec3 c = skin.rgb;
	if (belly < -0.35) c = mix(c,vec3(0.87,0.75,0.55),0.80);
	if (worm && sin(section*150.8)>0.86) c *= 0.76;
	if (!worm && belly > 0.55) c *= 0.82;
	if (armour>0.0 && belly>0.35 && sin(section*100.0)>0.30) c=mix(c,vec3(0.84,0.47,0.29),0.4+armour*0.12);
	ALBEDO = c;
	ROUGHNESS = 0.86;
}
