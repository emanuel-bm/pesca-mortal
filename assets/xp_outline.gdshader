shader_type canvas_item;
render_mode unshaded;
uniform vec4 outline_color : source_color = vec4(0.25, 0.65, 1.0, 1.0);

void fragment() {
 vec4 original = texture(TEXTURE, UV);
 vec2 dx = dFdx(UV);
 vec2 dy = dFdy(UV);
 float adjacent = max(max(texture(TEXTURE, UV + dx).a, texture(TEXTURE, UV - dx).a), max(texture(TEXTURE, UV + dy).a, texture(TEXTURE, UV - dy).a));
 // Ignore the faint halo; outline only the solid fried-fish silhouette.
 COLOR = original.a >= 0.5 ? vec4(original.rgb, 1.0) : vec4(outline_color.rgb, step(0.5, adjacent));
}
