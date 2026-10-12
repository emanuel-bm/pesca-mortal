extends RefCounted

const BASE_HEALTH := 32000.0 * 20.0
const HAND_DAMAGE := 280.0
const LOG_DAMAGE := 200.0
const LOG_SPEED := 600.0 / 0.325
const LOG_OVERSHOOT := 1.5
const LOG_RANGE_MULTIPLIER := 1.5
const LOG_SIZE := Vector2(160, 56)
const LOG_HITBOX_SIZE := Vector2(160, 36)
const LOG_WARNING_TIME := 0.6
const LOG_WARNING_SPEED_MULTIPLIER := 0.5
const HAND_WARNING_TIME := 0.5
const HAND_SCALE := 0.8
const HAND_RANGE := 160.0
const HAND_TARGET_OFFSET := 160.0
const MOVE_SPEED := 120.0

static func initialize(enemy: Dictionary) -> void:
 enemy.phase = "approach"
 enemy.timer = 2.0
 enemy.target = enemy.pos
 enemy.hand_angle = 0.0
 enemy.hand_offset = Vector2.ZERO

static func hand_polygon(center: Vector2, angle: float = 0.0) -> PackedVector2Array:
 # Wrist, palm, thumb and four distinct fingers; rendering and hits share this shape.
 var outline := PackedVector2Array([
  Vector2(-30, 58), Vector2(-36, 20), Vector2(-60, -1), Vector2(-65, -23),
  Vector2(-54, -32), Vector2(-31, -11), Vector2(-32, -62), Vector2(-25, -72),
  Vector2(-15, -69), Vector2(-13, -24), Vector2(-9, -83), Vector2(0, -89),
  Vector2(10, -83), Vector2(11, -24), Vector2(17, -73), Vector2(27, -78),
  Vector2(36, -70), Vector2(32, -16), Vector2(39, -55), Vector2(49, -59),
  Vector2(57, -50), Vector2(48, 20), Vector2(29, 58)])
 for index in outline.size(): outline[index] = center + (outline[index] * HAND_SCALE).rotated(angle)
 return outline

static func hand_hits(enemy: Dictionary, point: Vector2, radius: float = 14.0) -> bool:
 var polygon := hand_polygon(enemy.target, enemy.hand_angle)
 if Geometry2D.is_point_in_polygon(point, polygon): return true
 for index in polygon.size():
  if Geometry2D.get_closest_point_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()]).distance_to(point) <= radius: return true
 return false

static func choose_attack(enemy: Dictionary, player: Vector2, visible_world: Rect2) -> String:
 if enemy.pos.distance_to(player) <= HAND_RANGE: return "hand"
 var launch_area := Rect2(visible_world.get_center() - visible_world.size * LOG_RANGE_MULTIPLIER / 2.0, visible_world.size * LOG_RANGE_MULTIPLIER)
 return "log" if launch_area.has_point(enemy.pos) else ""

static func update(enemy: Dictionary, dt: float, player: Vector2, arena: Vector2, visible_world: Rect2 = Rect2()) -> String:
 var pursuit: Vector2 = player - enemy.pos
 if absf(pursuit.x) > 0.01: enemy.facing_left = pursuit.x < 0
 var movement_multiplier := LOG_WARNING_SPEED_MULTIPLIER if enemy.phase == "log_warning" else 1.0
 enemy.pos = enemy.pos.move_toward(player, enemy.speed * movement_multiplier * dt)
 if enemy.phase in ["hand_warning", "hand_impact"]:
  enemy.target = enemy.pos + enemy.hand_offset
 enemy.timer -= dt
 if enemy.phase == "approach":
  if enemy.timer <= 0:
   var attack := choose_attack(enemy, player, visible_world)
   if attack.is_empty(): return ""
   enemy.phase = attack + "_warning"
   enemy.timer = HAND_WARNING_TIME if attack == "hand" else LOG_WARNING_TIME
   enemy.target = throw_endpoint(enemy.pos, player, arena) if attack == "log" else enemy.pos + (player - enemy.pos).limit_length(HAND_TARGET_OFFSET)
   enemy.hand_angle = (player - enemy.pos).angle() + PI / 2
   if attack == "hand": enemy.hand_offset = enemy.target - enemy.pos
 elif enemy.phase.ends_with("_warning") and enemy.timer <= 0:
  var attack: String = enemy.phase.trim_suffix("_warning")
  enemy.phase = attack + "_impact"
  enemy.timer = 0.35
  return attack
 elif enemy.phase.ends_with("_impact") and enemy.timer <= 0:
  enemy.phase = "recovery"
  enemy.timer = 1.4
 elif enemy.phase == "recovery" and enemy.timer <= 0:
  enemy.phase = "approach"
  enemy.timer = 2.0
 return ""

static func log_rect(log: Dictionary) -> Rect2:
 var angle: float = log.get("angle", 0.0)
 var extent := Vector2(absf(cos(angle)) * LOG_HITBOX_SIZE.x + absf(sin(angle)) * LOG_HITBOX_SIZE.y, absf(sin(angle)) * LOG_HITBOX_SIZE.x + absf(cos(angle)) * LOG_HITBOX_SIZE.y)
 return Rect2(Vector2(log.pos) - extent / 2, extent)

static func throw_endpoint(origin: Vector2, player: Vector2, arena: Vector2) -> Vector2:
 var travel := (player - origin) * LOG_OVERSHOOT
 var angle := travel.angle()
 var margin := Vector2(absf(cos(angle)) * LOG_SIZE.x + absf(sin(angle)) * LOG_SIZE.y, absf(sin(angle)) * LOG_SIZE.x + absf(cos(angle)) * LOG_SIZE.y) / 2 + Vector2(2, 2)
 var fraction := 1.0
 for axis in 2:
  if travel[axis] > 0: fraction = minf(fraction, (arena[axis] - margin[axis] - origin[axis]) / travel[axis])
  elif travel[axis] < 0: fraction = minf(fraction, (margin[axis] - origin[axis]) / travel[axis])
 return origin + travel * maxf(0.0, fraction)

static func log_shapes(_art: Dictionary = {}) -> Array[PackedVector2Array]:
 var shapes: Array[PackedVector2Array] = []
 var half := LOG_HITBOX_SIZE / 2
 shapes.append(PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]))
 return shapes

static func log_hits(log: Dictionary, point: Vector2, padding: float = 0.0) -> bool:
 if not log_rect(log).grow(padding).has_point(point): return false
 var local: Vector2 = (point - Vector2(log.pos)).rotated(-float(log.get("angle", 0.0)))
 return Rect2(-LOG_HITBOX_SIZE / 2, LOG_HITBOX_SIZE).grow(padding).has_point(local)

static func draw(game: Node2D, enemy: Dictionary, offset: Vector2, art: Dictionary) -> void:
 var position: Vector2 = enemy.pos - offset
 if enemy.phase.begins_with("hand"):
  var polygon := hand_polygon(enemy.target - offset, enemy.hand_angle)
  game.draw_colored_polygon(polygon, Color(1, 0.35, 0.12, 0.45 if enemy.phase.ends_with("impact") else 0.2))
  polygon.append(polygon[0])
  game.draw_polyline(polygon, Color(1, 0.65, 0.15), 3)
 elif enemy.phase == "log_warning":
  game.draw_line(position, enemy.target - offset, Color(1, 0.65, 0.15, 0.4), LOG_HITBOX_SIZE.y)
 if not art.is_empty():
  var size: Vector2 = Vector2(art.region.size) / maxf(art.region.size.x, art.region.size.y) * 220
  game.draw_set_transform(position, 0, Vector2(-1 if enemy.get("facing_left", false) else 1, 1))
  game.draw_texture_rect_region(art.texture, Rect2(-size / 2, size), Rect2(art.region), Color.WHITE if enemy.flash <= 0 else Color(1.7, 1.7, 1.7))
  game.draw_set_transform(Vector2.ZERO)
 if game.run_mode != "bosses": game.draw_boss_health(enemy, position + Vector2(-70, 120), 140, Color(0.3, 0.8, 0.25))
