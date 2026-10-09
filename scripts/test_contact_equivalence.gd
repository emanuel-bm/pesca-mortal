extends SceneTree
const VISUALS = preload("res://scripts/fish_visuals.gd")
func legacy(art: Dictionary, enemy: Dictionary, point: Vector2, padding: float) -> bool:
 var local: Vector2 = point - enemy.pos
 if local.length_squared() > pow(enemy.radius * 1.42 + padding, 2): return false
 if art.is_empty(): return local.length() < enemy.radius + padding
 if enemy.get("facing_left", false): local.x *= -1
 var size := VISUALS.size_for(art, enemy.radius)
 for normalized in art.polygons:
  var polygon := PackedVector2Array()
  for vertex in normalized: polygon.append(vertex * size)
  if Geometry2D.is_point_in_polygon(local, polygon): return true
  for i in polygon.size():
   var closest := Geometry2D.get_closest_point_to_segment(local, polygon[i], polygon[(i + 1) % polygon.size()])
   if local.distance_squared_to(closest) <= padding * padding: return true
 return false
func _initialize() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = 472
 var count := 0
 for path in ["res://assets/piranha.png", "res://assets/pintado-v2.png"]:
  var art := VISUALS.load_art(path)
  for radius in [13.0, 44.0, 26.0]:
   for padding in [0.0, 5.0, 14.0]:
    for flip in [false, true]:
     var enemy := {"pos": Vector2(123, 234), "radius": radius, "facing_left": flip}
     for sample in 500:
      var point: Vector2 = enemy.pos + Vector2(rng.randf_range(-90, 90), rng.randf_range(-90, 90))
      assert(VISUALS.overlaps(art, enemy, point, padding) == legacy(art, enemy, point, padding), "Contact differs from original")
      count += 1
     # Check original contour vertices and exact padding boundaries too.
     var size := VISUALS.size_for(art, radius)
     for polygon in art.polygons:
      for vertex in polygon:
       for offset in [Vector2.ZERO, Vector2(padding, 0), Vector2(0, padding)]:
        var local: Vector2 = vertex * size + offset
        if flip: local.x *= -1
        var point: Vector2 = enemy.pos + local
        assert(VISUALS.overlaps(art, enemy, point, padding) == legacy(art, enemy, point, padding))
        count += 1
 print("CONTACT EQUIVALENCE PASS: ", count, " comparisons, species, facing, radii, padding and contour boundaries")
 quit()
