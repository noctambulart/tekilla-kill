shader_type canvas_item;

void fragment() {
	float grey = dot(COLOR.rgb, vec3(0.30, 0.59, 0.11));
	COLOR = vec4(vec3(grey), COLOR.a * 0.55);
}
