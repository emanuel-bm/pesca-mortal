extends Node2D
## Cached drawing on a separate canvas item, refreshed at 20 Hz.
var marker_batches: Array[MultiMesh] = []
var area := Rect2()
var viewport_box := Rect2()
var player_point := Vector2.ZERO
var small_points := PackedVector2Array()
var large_points := PackedVector2Array()
var boss_points := PackedVector2Array()

func setup_batches() -> void:
 for color in [Color(1, 0.2, 0.24), Color(1, 0.2, 0.24), Color(0.75, 0.3, 1)]:
  var vertices := PackedVector3Array([Vector3.ZERO])
  var colors := PackedColorArray([color])
  var indices := PackedInt32Array()
  const SEGMENTS := 32
  for i in SEGMENTS:
   var point := Vector2.from_angle(TAU * i / SEGMENTS)
   vertices.append(Vector3(point.x, point.y, 0))
   colors.append(color)
   indices.append_array(PackedInt32Array([0, i + 1, (i + 1) % SEGMENTS + 1]))
  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = vertices
  arrays[Mesh.ARRAY_COLOR] = colors
  arrays[Mesh.ARRAY_INDEX] = indices
  var mesh := ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
  var batch := MultiMesh.new()
  batch.transform_format = MultiMesh.TRANSFORM_2D
  batch.mesh = mesh
  marker_batches.append(batch)

func update_batch(batch: MultiMesh, points: PackedVector2Array, radius: float) -> void:
 if points.size() > batch.instance_count:
  batch.instance_count = maxi(32, points.size() * 2)
 for i in points.size():
  batch.set_instance_transform_2d(i, Transform2D(Vector2(radius, 0), Vector2(0, radius), points[i]))
 batch.visible_instance_count = points.size()

func refresh(game: Node) -> void:
 area = game.minimap_world_rect()
 var scale_factor: Vector2 = area.size / game.ARENA
 var origin := area.position
 small_points.clear()
 large_points.clear()
 boss_points.clear()
 for enemy in game.enemies:
  var point: Vector2 = origin + Vector2(enemy.pos).clamp(Vector2.ZERO, game.ARENA) * scale_factor
  if enemy.boss: boss_points.append(point)
  elif enemy.tank: large_points.append(point)
  else: small_points.append(point)
 player_point = origin + game.player.clamp(Vector2.ZERO, game.ARENA) * scale_factor
 var visible_world := Rect2(game.camera_offset(), game.get_viewport_rect().size).intersection(Rect2(Vector2.ZERO, game.ARENA))
 viewport_box = Rect2(origin + visible_world.position * scale_factor, visible_world.size * scale_factor)
 if marker_batches.is_empty(): setup_batches()
 update_batch(marker_batches[0], small_points, 1.8)
 update_batch(marker_batches[1], large_points, 3.0)
 update_batch(marker_batches[2], boss_points, 6.0)
 queue_redraw()

func _draw() -> void:
 draw_rect(area, Color(0.055, 0.16, 0.17))
 draw_rect(area, Color(0.3, 0.4, 0.45), false, 2)
 draw_rect(viewport_box, Color(0.55, 0.7, 0.7, 0.3), false, 1)
 for batch in marker_batches:
  if batch.visible_instance_count > 0: draw_multimesh(batch, null)
 draw_circle(player_point, 5, Color(0.01, 0.04, 0.07))
 draw_circle(player_point, 3.5, Color(0.3, 0.85, 1))
