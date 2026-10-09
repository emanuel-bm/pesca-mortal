extends Node2D

func _draw() -> void:
 var game := get_parent()
 if not game.xp_texture: return
 var offset: Vector2 = game.camera_offset()
 var region: Rect2 = game.xp_region
 var visible := Rect2(offset, game.get_viewport_rect().size).grow(22)
 for gem in game.gems:
  if not visible.has_point(gem.pos): continue
  var size := 20.0 if gem.xp > 1 else 14.0
  if game.graphics_quality == 0:
   draw_rect(Rect2(gem.pos - offset - Vector2(3, 2), Vector2(6, 4)), game.XP_COLOR)
   continue
  var dimensions := region.size * size / maxf(region.size.x, region.size.y)
  draw_texture_rect_region(game.xp_texture, Rect2(gem.pos - offset - dimensions / 2, dimensions), region)
