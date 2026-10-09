extends RefCounted
## O mesmo recorte e contorno alfa orientam desenho e colisão.

static func load_art(path: String) -> Dictionary:
 if not ResourceLoader.exists(path): return {}
 var texture: Texture2D = load(path)
 var image := texture.get_image()
 var bitmap := BitMap.new()
 bitmap.create_from_image_alpha(image, 0.5)
 var outlines := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 12.0)
 var retained: Array[PackedVector2Array] = []
 var minimum := Vector2(INF, INF)
 var maximum := Vector2(-INF, -INF)
 for outline in outlines:
  if absf(polygon_area(outline)) < image.get_width() * image.get_height() * 0.002: continue
  retained.append(outline)
  for point in outline:
   minimum = minimum.min(point)
   maximum = maximum.max(point)
 var region := Rect2i(Vector2i(minimum.floor()), Vector2i((maximum - minimum).ceil())) if not retained.is_empty() else image.get_used_rect()
 var normalized: Array[PackedVector2Array] = []
 for outline in retained:
  var points := PackedVector2Array()
  for point in outline:
   points.append((point - Vector2(region.position)) / Vector2(region.size) - Vector2(0.5, 0.5))
  normalized.append(points)
 return {"texture": texture, "region": region, "polygons": normalized, "scaled_shapes": {}}

static func polygon_area(points: PackedVector2Array) -> float:
 var area := 0.0
 for i in points.size(): area += points[i].cross(points[(i + 1) % points.size()])
 return area * 0.5

static func size_for(art: Dictionary, radius: float) -> Vector2:
 var dimensions := Vector2(art.region.size)
 return dimensions / maxf(dimensions.x, dimensions.y) * radius * 2

static func overlaps(art: Dictionary, enemy: Dictionary, point: Vector2, padding: float) -> bool:
 var local: Vector2 = point - enemy.pos
 var reach: float = enemy.radius * 1.42 + padding
 if local.length_squared() > reach * reach: return false
 if art.is_empty():
  var distance: float = enemy.radius + padding
  return local.length_squared() < distance * distance
 if enemy.get("facing_left", false): local.x *= -1
 if not art.scaled_shapes.has(enemy.radius):
  var size := size_for(art, enemy.radius)
  var shapes: Array[PackedVector2Array] = []
  var bounds: Array[Rect2] = []
  for normalized in art.polygons:
   var points := PackedVector2Array()
   var minimum := Vector2(INF, INF)
   var maximum := Vector2(-INF, -INF)
   for vertex in normalized:
    var scaled: Vector2 = vertex * size
    points.append(scaled)
    minimum = minimum.min(scaled)
    maximum = maximum.max(scaled)
   shapes.append(points)
   bounds.append(Rect2(minimum, maximum - minimum))
  art.scaled_shapes[enemy.radius] = shapes
  if not art.has("scaled_bounds"): art.scaled_bounds = {}
  art.scaled_bounds[enemy.radius] = bounds
 # Compatibility with shapes already cached before the bounds were introduced.
 if not art.has("scaled_bounds") or not art.scaled_bounds.has(enemy.radius):
  art.scaled_shapes.erase(enemy.radius)
  return overlaps(art, enemy, point, padding)
 var padding_squared := padding * padding
 var bounds_padding := padding + 0.0001 # Conservative guard for float rounding at edges.
 var shapes: Array = art.scaled_shapes[enemy.radius]
 var bounds: Array = art.scaled_bounds[enemy.radius]
 for shape_index in shapes.size():
  var box: Rect2 = bounds[shape_index]
  if local.x < box.position.x - bounds_padding or local.x > box.end.x + bounds_padding or local.y < box.position.y - bounds_padding or local.y > box.end.y + bounds_padding: continue
  var polygon: PackedVector2Array = shapes[shape_index]
  if Geometry2D.is_point_in_polygon(local, polygon): return true
  for i in polygon.size():
   var a := polygon[i]
   var b := polygon[(i + 1) % polygon.size()]
   # A segment cannot touch the padded point outside this bounding box.
   if local.x < minf(a.x, b.x) - bounds_padding or local.x > maxf(a.x, b.x) + bounds_padding or local.y < minf(a.y, b.y) - bounds_padding or local.y > maxf(a.y, b.y) + bounds_padding: continue
   var closest := Geometry2D.get_closest_point_to_segment(local, a, b)
   if local.distance_squared_to(closest) <= padding_squared: return true
 return false
