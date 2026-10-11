extends RefCounted

# All animations use a fixed number of particles, a separate visual clock and
# a two-pixel grid. They never consume the gameplay RNG or create scene nodes.
const PIXEL := 2.0
const HEX := [Vector2(0, -44), Vector2(38, -22), Vector2(38, 22), Vector2(0, 44), Vector2(-38, 22), Vector2(-38, -22)]
var hex_texture: Texture2D
var cell_texture: Texture2D

func _init() -> void:
 hex_texture = make_hex_texture(22)
 cell_texture = make_hex_texture(5)

func make_hex_texture(radius: int) -> Texture2D:
 var image := Image.create(radius * 2 + 3, radius * 2 + 3, false, Image.FORMAT_RGBA8)
 var origin := Vector2.ONE * (radius + 1)
 for edge in 6:
  var a := origin + Vector2.from_angle(-PI / 2.0 + edge * TAU / 6.0) * radius
  var b := origin + Vector2.from_angle(-PI / 2.0 + (edge + 1) * TAU / 6.0) * radius
  var steps := ceili(a.distance_to(b)) * 2
  for step in steps + 1:
   var point := a.lerp(b, float(step) / steps).round()
   image.set_pixel(int(point.x), int(point.y), Color.WHITE)
 return ImageTexture.create_from_image(image)

func pixel(canvas: Node2D, point: Vector2, size: Vector2, color: Color) -> void:
 canvas.draw_rect(Rect2((point / PIXEL).round() * PIXEL, size), color)

func sparkle(canvas: Node2D, point: Vector2, size: float, color: Color) -> void:
 pixel(canvas, point - Vector2(size, 1), Vector2(size * 2 + 2, 2), color)
 pixel(canvas, point - Vector2(1, size), Vector2(2, size * 2 + 2), color)
 pixel(canvas, point, Vector2(2, 2), Color(1, 1, 0.9, color.a))

func shield(canvas: Node2D, center: Vector2, time: float, impact: float, direction: Vector2, fade: float) -> void:
 var pulse := 0.5 + 0.5 * sin(time * 3.0)
 var flash := impact / 0.32
 canvas.draw_texture_rect(hex_texture, Rect2(center - Vector2(47, 47), Vector2(94, 94)), false, Color(0.12, 0.35, 0.65, fade * 0.5))
 canvas.draw_texture_rect(hex_texture, Rect2(center - Vector2(45, 45), Vector2(90, 90)), false, Color(0.3 + flash * 0.6, 0.8, 1, fade * (0.65 + pulse * 0.25)))
 # Sparse honeycomb: cells at the perimeter leave the face and body readable.
 for index in 12:
  var angle := -PI / 2.0 + index * TAU / 12.0
  var point := center + Vector2.from_angle(angle) * (28.0 if index % 2 else 32.0)
  var sweep := pow(maxf(0.0, cos(angle - time * 2.2)), 6.0)
  var hit := maxf(0.0, Vector2.from_angle(angle).dot(direction)) * flash
  var alpha := fade * (0.12 + sweep * 0.6 + hit * 0.6)
  canvas.draw_texture_rect(cell_texture, Rect2((point / 2.0).round() * 2.0 - Vector2(10, 10), Vector2(20, 20)), false, Color(0.5 + hit * 0.5, 0.9, 1, alpha))
 for index in 6:
  var vertex: Vector2 = center + HEX[index]
  sparkle(canvas, vertex, 2.0, Color(0.65, 0.95, 1, fade * (0.5 + pulse * 0.35)))
  var phase := fposmod(time * 0.8 + index / 6.0, 1.0)
  pixel(canvas, vertex + HEX[index].normalized() * (3 + phase * 9), Vector2(2, 2), Color(0.4, 0.85, 1, fade * (1 - phase)))
 if impact > 0:
  var point := center + direction * 37.0
  sparkle(canvas, point, 4.0 + (1 - flash) * 6.0, Color(0.85, 1, 1, flash))

func fury_color(red: Color, gold: Color, burst: float, alpha: float) -> Color:
 var color := red.lerp(gold, clampf(burst / 0.12, 0.0, 1.0))
 color.a = alpha
 return color

func fury(canvas: Node2D, center: Vector2, time: float, burst: float, facing: float, fade: float) -> void:
 var outer := fury_color(Color(0.65, 0.025, 0.04), Color(1, 0.5, 0.025), burst, fade * 0.9)
 var flame := fury_color(Color(1, 0.12, 0.035), Color(1, 0.8, 0.12), burst, fade)
 var core := fury_color(Color(1, 0.42, 0.12), Color(1, 1, 0.7), burst, fade)
 # Head-sized shoulder-to-shoulder mantle, open below the face. Discrete
 # square stamps make its curved silhouette stepped rather than antialiased.
 var halo_center := center + Vector2(4 * facing, -25)
 for index in 52:
  var angle := lerpf(PI * 0.12, -PI * 1.12, index / 51.0)
  var wave := sin(angle * 5 + time * 4) * 1.5
  var local := Vector2(cos(angle) * (18 + wave), sin(angle) * (16 + wave))
  local.x *= facing
  var point := halo_center + local
  pixel(canvas, point - Vector2(6, 6), Vector2(12, 12), Color(outer.r, outer.g, outer.b, fade * 0.18))
  pixel(canvas, point - Vector2(4, 4), Vector2(8, 8), outer)
  pixel(canvas, point - Vector2(2, 2), Vector2(6, 6), flame)
  pixel(canvas, point, Vector2(2, 4), core)
  if index % 4 == 0:
   var outward := Vector2(local.x, local.y).normalized()
   var length := 4 + 3 * (0.5 + 0.5 * sin(time * 6 + index))
   for step in 3:
    var tip := point + outward * (length + step * 2) + Vector2(sin(time * 4 + index) * step, -step)
    pixel(canvas, tip, Vector2(4 if step == 0 else 2, 4 if step == 0 else 2), flame if step == 0 else core)
 # Small scrolling curls break up the ribbon into animated tongues of fire.
 for curl in 5:
  var angle := lerpf(-PI * 0.1, -PI * 0.9, curl / 4.0)
  var anchor := halo_center + Vector2(cos(angle) * 18 * facing, sin(angle) * 16)
  for step in 8:
   var turn := step * 0.6 + time * 2 + curl
   var radius := 4 * (1 - step / 10.0)
   pixel(canvas, anchor + Vector2(cos(turn) * facing, sin(turn)) * radius, Vector2(2, 2), core)
 # Head embers share the mantle's palette, so the entire fire turns gold
 # on attack and returns to red together, including the trails and fragments.
 for index in 24:
  var phase := fposmod(time * (1.2 + (index % 4) * 0.18) + index * 0.137, 1.0)
  var angle := index * 2.39996
  var anchor := Vector2((4 + cos(angle) * (12 + index % 3 * 2)) * facing, -25 + sin(angle) * 7)
  var velocity := Vector2(cos(angle) * 10 * facing, -14 - index % 4 * 4)
  var point := center + anchor + velocity * phase + Vector2(sin(phase * TAU + index) * 2, phase * phase * 5)
  var alpha := fade * minf(1.0, phase * 10) * minf(1.0, (1 - phase) * 4)
  var size := 4.0 if index % 5 == 0 else 2.0
  pixel(canvas, point + Vector2(-2, 2), Vector2(size + 2, size + 2), Color(outer.r, outer.g, outer.b, alpha * 0.45))
  pixel(canvas, point + Vector2(0, 4), Vector2(2, 4), Color(flame.r, flame.g, flame.b, alpha * 0.6))
  pixel(canvas, point, Vector2(size, size), Color(flame.r, flame.g, flame.b, alpha))
  if index % 3 == 0: pixel(canvas, point, Vector2(2, 2), Color(core.r, core.g, core.b, alpha))
 if burst > 0:
  var progress := 1.0 - burst / 0.24
  for side in [-1, 1]:
   var shoulder := center + Vector2((4 + side * 14) * facing, -18)
   sparkle(canvas, shoulder, 7 * (1 - progress), Color(core.r, core.g, core.b, fade * (1 - progress)))
   for index in 9:
    var direction := Vector2.from_angle(-PI + index * PI / 8)
    var point := shoulder + direction * (5 + progress * (15 + index % 3 * 4))
    pixel(canvas, point, Vector2(4 if index % 3 == 0 else 2, 2), Color(core.r, core.g, core.b, fade * (1 - progress)))

func piercing(canvas: Node2D, center: Vector2, time: float, fade: float) -> void:
 for index in 16:
  var phase := fposmod(time * 0.9 + index * 0.163, 1.0)
  var side := -1.0 if index % 2 == 0 else 1.0
  var point := center + Vector2(side * (14 + index % 4 * 3) + sin(phase * TAU + index) * 3, 23 - phase * 49)
  var alpha := sin(phase * PI) * fade
  pixel(canvas, point + Vector2(0, 6), Vector2(2, 4), Color(1, 0.7, 0.15, alpha * 0.25))
  # Stepped needles with a bright core, distinct from fury's square embers.
  pixel(canvas, point - Vector2(0, 4), Vector2(2, 8), Color(1, 0.88, 0.4, alpha))
  pixel(canvas, point - Vector2(2, 0), Vector2(6, 2), Color(1, 0.95, 0.65, alpha))
  pixel(canvas, point, Vector2(2, 2), Color(1, 1, 0.95, alpha))
 for index in 4:
  var phase := fposmod(time * 0.7 + index * 0.25, 1.0)
  var point := center + Vector2(-18 + index * 12, 13 - index % 3 * 13)
  var alpha := pow(sin(phase * PI), 8) * fade
  sparkle(canvas, point, 4 if phase > 0.35 and phase < 0.65 else 2, Color(1, 0.92, 0.55, alpha))

func magnet_point(index: int, phase: float) -> Vector2:
 var angle := index * 2.39996 + phase * (1.1 if index % 2 else -1.1)
 var radius := lerpf(68.0 + index % 5 * 7.0, 9.0, phase * phase)
 return Vector2.from_angle(angle) * radius * Vector2(1.0, 0.8)

func magnet(canvas: Node2D, center: Vector2, seconds: float) -> void:
 var elapsed := 1.0 - seconds
 for index in 24:
  var delay := index % 6 * 0.025
  var phase := clampf((elapsed - delay) / 0.76, 0.0, 1.0)
  if elapsed < delay: continue
  if phase < 1:
   var alpha := minf(1.0, phase * 8)
   for trail in [3, 2, 1]:
    var previous := magnet_point(index, maxf(0.0, phase - trail * 0.035))
    pixel(canvas, center + previous, Vector2(2, 2), Color(0.2, 0.85, 0.65, alpha * (0.5 - trail * 0.1)))
   var point := center + magnet_point(index, phase)
   pixel(canvas, point - Vector2(2, 2), Vector2(4, 4), Color(0.2, 0.9, 0.7, alpha * 0.7))
   pixel(canvas, point, Vector2(2, 2), Color(0.85, 1, 0.95, alpha))
  else:
   var flash := maxf(0.0, 1.0 - (elapsed - delay - 0.76) / 0.15)
   sparkle(canvas, center + magnet_point(index, 1.0), 3, Color(0.65, 1, 0.85, flash))
