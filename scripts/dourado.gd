extends RefCounted

const TRIGGER_RANGE_RATIO := 0.7
const WARNING_TIME := 1.1
const DASH_BASE_DISTANCE := 159.705
const RECOVERY_TIME := 0.75
const DASH_SPEED := 1400.0
const PREDICTION_TIME := 0.5
const BASE_HEALTH := 100.0

static func initialize(enemy: Dictionary) -> void:
 enemy.phase = "approach"
 enemy.timer = 0.0
 enemy.dash_direction = Vector2.RIGHT
 enemy.erase("dash_distance")
 enemy.erase("dash_remaining")

static func dash_speed(enemy: Dictionary) -> float:
 return DASH_SPEED * float(enemy.get("speed_multiplier", 1.0))

static func dash_range(enemy: Dictionary) -> float:
 return DASH_BASE_DISTANCE * float(enemy.get("stat_multiplier", 1.0))

static func update(enemy: Dictionary, dt: float, player: Vector2, arena: Vector2, player_velocity: Vector2 = Vector2.ZERO) -> void:
 var direction: Vector2 = player - enemy.pos
 match enemy.phase:
  "approach":
   enemy.pos = enemy.pos.move_toward(player, enemy.speed * dt)
   enemy.facing_left = direction.x < 0
   if enemy.pos.distance_to(player) <= dash_range(enemy) * TRIGGER_RANGE_RATIO:
    enemy.phase = "warning"
    enemy.dash_distance = dash_range(enemy)
    enemy.timer = WARNING_TIME
    var target := (player + player_velocity * PREDICTION_TIME).clamp(Vector2(18, 18), arena - Vector2(18, 18))
    var predicted_direction: Vector2 = target - enemy.pos
    enemy.dash_direction = predicted_direction.normalized() if predicted_direction.length_squared() > 0 else Vector2.RIGHT
    enemy.facing_left = enemy.dash_direction.x < 0
  "warning":
   enemy.timer -= dt
   if enemy.timer <= 0:
    enemy.phase = "dash"
    enemy.dash_remaining = float(enemy.get("dash_distance", dash_range(enemy)))
  "dash":
   var step := minf(dash_speed(enemy) * dt, enemy.dash_remaining)
   enemy.pos += enemy.dash_direction * step
   enemy.dash_remaining -= step
   if enemy.dash_remaining <= 0:
    enemy.phase = "recovery"
    enemy.timer = RECOVERY_TIME
  "recovery":
   enemy.timer -= dt
   if enemy.timer <= 0: enemy.phase = "approach"
 enemy.pos = Vector2(enemy.pos).clamp(Vector2.ONE * enemy.radius, arena - Vector2.ONE * enemy.radius)
