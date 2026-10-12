extends Node2D

func _draw() -> void:
 var game := get_parent()
 if not game.xp_texture: return
 var offset: Vector2 = game.camera_offset()
 var region: Rect2 = game.xp_region
 var visible := Rect2(offset, game.get_viewport_rect().size).grow(72)
 for gem in game.gems:
  if not visible.has_point(gem.pos): continue
  if gem.get("kind", "") == "forest_gem":
   draw_forest_gem(gem.pos - offset, game.graphics_quality)
   continue
  var giant: bool = gem.get("giant", false)
  var size := 112.0 if giant else (20.0 if gem.xp > 1 else 14.0)
  if game.graphics_quality == 0:
   var dimensions := Vector2(48, 32) if giant else Vector2(6, 4)
   draw_rect(Rect2(gem.pos - offset - dimensions / 2, dimensions), Color(0.30, 0.14, 0.05))
   continue
  var dimensions := region.size * size / maxf(region.size.x, region.size.y)
  draw_texture_rect_region(game.xp_texture, Rect2(gem.pos - offset - dimensions / 2, dimensions), region)

func draw_forest_gem(center: Vector2, quality: int) -> void:
 # A faceted emerald silhouette stays distinct from the fish belly pickups.
 var outline := PackedVector2Array([Vector2(-18, -26), Vector2(18, -26), Vector2(32, -8), Vector2(0, 36), Vector2(-32, -8)])
 for i in outline.size(): outline[i] += center
 draw_colored_polygon(outline, Color("073d2a"))
 var facets := [
  [Vector2(-15, -22), Vector2(15, -22), Vector2(0, -5)],
  [Vector2(-15, -22), Vector2(0, -5), Vector2(-27, -8)],
  [Vector2(15, -22), Vector2(27, -8), Vector2(0, -5)],
  [Vector2(-27, -8), Vector2(0, -5), Vector2(0, 29)],
  [Vector2(0, -5), Vector2(27, -8), Vector2(0, 29)]
 ]
 var colors := [Color("b4ffd0"), Color("55eaa0"), Color("24bd78"), Color("15945d"), Color("087b50")]
 for i in facets.size():
  var points := PackedVector2Array()
  for point in facets[i]: points.append(center + point)
  draw_colored_polygon(points, colors[i] if quality > 0 else Color("36d88b"))
 if quality > 0:
  draw_line(center + Vector2(-11, -17), center + Vector2(-2, -17), Color("e3ffeb"), 3)
