shader_type canvas_item;
render_mode unshaded;

uniform float age = 0.0;
uniform bool blocked = false;
uniform bool shine_enabled = true;

void fragment() {
 vec4 tex = texture(TEXTURE, UV);
 // Age comes from active gameplay, so the sweep freezes with the run.
 float sweep = mod(age, 2.4) / 1.6;
 float band = (1.0 - smoothstep(0.025, 0.13, abs(UV.y - sweep))) * step(sweep, 1.15);
 tex.rgb = mix(tex.rgb, vec3(1.0, 0.97, 0.78), band * 0.7 * float(shine_enabled));
 if (blocked) tex.rgb = vec3(dot(tex.rgb, vec3(0.299, 0.587, 0.114)));
 COLOR = tex * COLOR;
}
