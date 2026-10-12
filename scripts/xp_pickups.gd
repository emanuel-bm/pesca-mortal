extends Node2D

var forest_leaf: Texture2D
var forest_leaf_region: Rect2

func _ready() -> void:
 forest_leaf = load("res://assets/folha-cristalizada-v1.png")
 forest_leaf_region = Rect2(forest_leaf.get_image().get_used_rect())
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
 var game := get_parent()
 if not game.xp_texture: return
 var offset: Vector2 = game.camera_offset()
 var region: Rect2 = game.xp_region
 var visible := Rect2(offset, game.get_viewport_rect().size).grow(72)
 for gem in game.gems:
  if not visible.has_point(gem.pos): continue
  if gem.get("kind", "") == "forest_gem":
   var leaf_size := forest_leaf_region.size * 88.0 / maxf(forest_leaf_region.size.x, forest_leaf_region.size.y)
   draw_texture_rect_region(forest_leaf, Rect2(gem.pos - offset - leaf_size / 2, leaf_size), forest_leaf_region)
   continue
  var giant: bool = gem.get("giant", false)
  var size := 112.0 if giant else (20.0 if gem.xp > 1 else 14.0)
  if game.graphics_quality == 0:
   var dimensions := Vector2(48, 32) if giant else Vector2(6, 4)
   draw_rect(Rect2(gem.pos - offset - dimensions / 2, dimensions), Color(0.30, 0.14, 0.05))
   continue
  var dimensions := region.size * size / maxf(region.size.x, region.size.y)
  draw_texture_rect_region(game.xp_texture, Rect2(gem.pos - offset - dimensions / 2, dimensions), region)
