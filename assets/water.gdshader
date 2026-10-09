shader_type canvas_item;
render_mode unshaded;

uniform sampler2D cell_texture : repeat_enable, filter_linear;
uniform sampler2D river_texture : source_color, repeat_enable, filter_nearest;
uniform vec2 camera_world = vec2(0.0);
uniform vec2 view_size = vec2(1152.0, 720.0);
uniform int quality = 2;
uniform float water_time = 0.0;

void fragment() {
 // Amostragem em pixels de mundo: mover a câmera não arrasta a água.
 vec2 world = floor((UV * view_size + camera_world) / 2.0) * 2.0;
 if (quality == 0) {
  COLOR = vec4(texture(river_texture, world / 1024.0).rgb * 0.65, 1.0);
 } else {
 float t = water_time;
 vec2 warp = vec2(sin(world.y * 0.014 + t * 0.48), cos(world.x * 0.012 - t * 0.37)) * 14.0;
 if (quality == 2) warp += vec2(sin(world.y * 0.045 + world.x * 0.018 - t * 0.7), cos(world.x * 0.039 + world.y * 0.021 + t * 0.6)) * 9.0;
 vec2 uv = (world + warp) / 512.0;
 float cells_a = texture(cell_texture, uv + vec2(t * 0.011, t * -0.007)).r;
 float cells_b = quality == 2 ? texture(cell_texture, uv * 1.43 + vec2(t * -0.008, t * 0.012) + vec2(0.31)).r : 1.0;
 float edge_a = 1.0 - smoothstep(0.015, 0.055, cells_a);
 float edge_b = 1.0 - smoothstep(0.01, 0.035, cells_b);
 float swell = sin(world.x * 0.008 + world.y * 0.005 + t * 0.65) * 0.5 + 0.5;
 vec3 original = texture(river_texture, uv * 0.5).rgb * 0.65;
 vec3 base = mix(vec3(0.047, 0.117, 0.122), original, 0.22);
 vec3 light = vec3(0.14, 0.24, 0.23);
 float shimmer = edge_a * (0.27 + swell * 0.28) + edge_b * 0.16;
 vec3 color = base + light * shimmer + vec3(0.005, 0.012, 0.012) * swell;
 // Reflexos ocasionais discretos, sem clarear toda a arena.
 float glint = step(0.985, sin(world.x * 0.029 + t * 0.6) * sin(world.y * 0.033 - t * 0.44));
 color += vec3(0.04, 0.065, 0.055) * glint;
 COLOR = vec4(color, 1.0);
 }
}
