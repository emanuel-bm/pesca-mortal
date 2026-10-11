shader_type canvas_item;
render_mode unshaded;
uniform vec4 outline_color : source_color = vec4(0.30, 0.14, 0.05, 1.0);

void fragment() {
 vec4 original = texture(TEXTURE, UV);
 vec2 dx = dFdx(UV) * 1.5;
 vec2 dy = dFdy(UV) * 1.5;
 float adjacent = max(max(texture(TEXTURE, UV + dx).a, texture(TEXTURE, UV - dx).a), max(texture(TEXTURE, UV + dy).a, texture(TEXTURE, UV - dy).a));
 // Ignore the faint halo; outline only the solid fried-fish silhouette.
 COLOR = original.a >= 0.5 ? vec4(original.rgb, 1.0) : vec4(outline_color.rgb, step(0.5, adjacent));
}
