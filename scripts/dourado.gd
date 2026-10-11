extends RefCounted

const TRIGGER_RANGE_RATIO := 0.7
const WARNING_TIME := 1.1
const DASH_TIME := 0.21125
const RECOVERY_TIME := 0.75
const DASH_SPEED := 756.0
const PREDICTION_TIME := 0.5
const BASE_HEALTH := 200.0
const COOLDOWN_MIN := 1.0
const COOLDOWN_MAX := 3.0

static func initialize(enemy: Dictionary) -> void:
 enemy.phase = "approach"
 enemy.timer = 0.0
 enemy.cooldown = 0.0
 enemy.dash_direction = Vector2.RIGHT

static func dash_speed(enemy: Dictionary) -> float:
 return DASH_SPEED * float(enemy.get("stat_multiplier", 1.0))

static func dash_range(enemy: Dictionary) -> float:
 return dash_speed(enemy) * DASH_TIME

static func update(enemy: Dictionary, dt: float, player: Vector2, arena: Vector2, player_velocity: Vector2 = Vector2.ZERO) -> void:
 var direction: Vector2 = player - enemy.pos
 enemy.cooldown = maxf(0.0, float(enemy.get("cooldown", 0.0)) - dt)
 match enemy.phase:
  "approach":
   enemy.pos = enemy.pos.move_toward(player, enemy.speed * dt)
   enemy.facing_left = direction.x < 0
   if enemy.pos.distance_to(player) <= dash_range(enemy) * TRIGGER_RANGE_RATIO and enemy.cooldown <= 0:
    enemy.phase = "warning"
    enemy.timer = WARNING_TIME
    var target := (player + player_velocity * PREDICTION_TIME).clamp(Vector2(18, 18), arena - Vector2(18, 18))
    var predicted_direction: Vector2 = target - enemy.pos
    enemy.dash_direction = predicted_direction.normalized() if predicted_direction.length_squared() > 0 else Vector2.RIGHT
    enemy.facing_left = enemy.dash_direction.x < 0
  "warning":
   enemy.timer -= dt
   if enemy.timer <= 0:
    enemy.phase = "dash"
    enemy.timer = DASH_TIME
  "dash":
   var step := minf(dt, enemy.timer)
   enemy.pos += enemy.dash_direction * dash_speed(enemy) * step
   enemy.timer -= dt
   if enemy.timer <= 0:
    enemy.phase = "recovery"
    enemy.timer = RECOVERY_TIME
    enemy.cooldown = randf_range(COOLDOWN_MIN, COOLDOWN_MAX)
  "recovery":
   enemy.timer -= dt
   if enemy.timer <= 0: enemy.phase = "approach"
 enemy.pos = Vector2(enemy.pos).clamp(Vector2.ONE * enemy.radius, arena - Vector2.ONE * enemy.radius)
