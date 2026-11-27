shader_type canvas_item;
render_mode unshaded;

uniform sampler2D sand : repeat_enable, filter_nearest;
uniform sampler2D stone : repeat_enable, filter_nearest;
uniform vec2 world_size = vec2(832.0, 640.0);
// World-space extents and door spans are also the source of the solid walls.
uniform vec4 room = vec4(64.0, 240.0, 512.0, 592.0);
uniform vec2 east_door = vec2(408.0, 536.0);
uniform vec2 south_door = vec2(264.0, 408.0);
uniform vec2 north_door = vec2(264.0, 360.0);
uniform vec2 west_door = vec2(-10000.0);
uniform bool base_layer = true;
uniform int floor_kind = 0;

float span(float x, vec2 ends, float feather) {
	return smoothstep(ends.x - feather, ends.x + feather, x)
		* (1.0 - smoothstep(ends.y - feather, ends.y + feather, x));
}

void fragment() {
	vec2 p = UV * world_size;
	// Mirrored sampling joins the generated panels without abrupt tile seams.
	vec2 material_uv = abs(fract(p / 512.0) * 2.0 - 1.0);
	material_uv = clamp(material_uv, vec2(0.5 / 768.0), vec2(1.0 - 0.5 / 768.0));
	vec3 outside = texture(sand, material_uv).rgb;
	vec3 inside = texture(stone, material_uv).rgb;
	float in_room = step(room.x, p.x) * step(p.x, room.z) * step(room.y, p.y) * step(p.y, room.w);
	// Continuous, slightly irregular material transitions, rather than alpha bands.
	float warp = 3.5 * sin(p.y * 0.075) + 2.0 * sin(p.x * 0.11 + p.y * 0.043);
	float east = span(p.y, east_door, 12.0) * (1.0 - smoothstep(0.0, 56.0 + warp, max(0.0, p.x - room.z)))
		* step(room.z, p.x);
	float south = span(p.x, south_door, 12.0) * (1.0 - smoothstep(0.0, 56.0 + warp, max(0.0, p.y - room.w)))
		* step(room.w, p.y);
	float north = span(p.x, north_door, 10.0) * (1.0 - smoothstep(0.0, 44.0 + warp, max(0.0, room.y - p.y)))
		* step(p.y, room.y);
	float west = span(p.y, west_door, 12.0) * (1.0 - smoothstep(0.0, 56.0 + warp, max(0.0, room.x - p.x)))
		* step(p.x, room.x);
	float floor_mask = max(in_room, max(west, max(east, max(south, north))));
	float depth = clamp((p.y - room.y) / (room.w - room.y), 0.0, 1.0);
	if (floor_kind == 0) {
		inside *= mix(vec3(0.83, 0.88, 0.96), vec3(0.97, 0.98, 1.02), depth);
	} else if (floor_kind == 1) {
		inside *= mix(vec3(0.92, 0.88, 0.82), vec3(1.0, 1.0, 0.95), depth);
	}
	// Warm daylight reaches inward from the open facade, while the bar stays cool.
	float warm_east = span(p.y + (room.z - p.x) * 0.18, east_door, 40.0)
		* exp(-abs(room.z - p.x) / 125.0);
	float warm_south = span(p.x + (room.w - p.y) * 0.22, south_door, 34.0)
		* exp(-abs(room.w - p.y) / 100.0);
	float warm_west = span(p.y - (p.x - room.x) * 0.18, west_door, 40.0)
		* exp(-abs(p.x - room.x) / 125.0);
	inside += vec3(0.13, 0.075, 0.025) * max(warm_west, max(warm_east, warm_south)) * (floor_kind == 2 ? 0.25 : 1.0);
	float west_shadow = exp(-abs(p.x - room.x) / 13.0);
	float north_shadow = exp(-abs(p.y - room.y) / 12.0) * (1.0 - span(p.x, north_door, 5.0));
	inside *= 1.0 - (floor_kind == 2 ? 0.05 : 0.16) * max(west_shadow, north_shadow) * in_room;
	float mask = clamp(floor_mask, 0.0, 1.0);
	COLOR = base_layer ? vec4(mix(outside, inside, mask), 1.0) : vec4(inside, mask);
}
