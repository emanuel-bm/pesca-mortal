extends "res://scripts/game.gd"
var legacy_checked := 0
func legacy(index: int, direction: Vector2) -> Vector2:
 var origin: Vector2 = enemies[index].pos
 var radius: float = crowd_radii[index]
 var padding := radius + crowd_max_radius + 6.0
 var minimum := Vector2i(((origin - Vector2.ONE * padding) / CROWD_CELL_SIZE).floor())
 var maximum := Vector2i(((origin + Vector2.ONE * padding) / CROWD_CELL_SIZE).floor())
 var checked := 0
 var force := Vector2.ZERO
 var count := 0
 var sideways := direction.orthogonal() * (0.45 if index % 2 == 0 else -0.45)
 for y in range(minimum.y, maximum.y + 1):
  for x in range(minimum.x, maximum.x + 1):
   for other_index: int in crowd_grid.get(Vector2i(x, y), []):
    checked += 1
    if other_index == index or crowd_active[other_index] == 0 or crowd_bosses[other_index] != crowd_bosses[index]: continue
    var difference := origin - crowd_positions[other_index]
    var influence := radius + crowd_radii[other_index] + 6.0
    var distance_squared := difference.length_squared()
    if distance_squared >= influence * influence: continue
    var distance := sqrt(distance_squared)
    var away := difference / distance if distance > 0.01 else Vector2.from_angle(fmod(float(index * 127), TAU))
    var pressure := 1.0 - distance / influence
    force += away * pressure
    if away.dot(direction) < -0.7: force += sideways * pressure
    count += 1
    if count >= 16:
     legacy_checked += checked
     return force.limit_length(1.5)
 legacy_checked += checked
 return force.limit_length(1.5)
