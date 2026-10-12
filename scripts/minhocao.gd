extends RefCounted

const SPEED_LIMITS = preload("res://scripts/enemy_speed_limits.gd")

const EMERGENCE_RADIUS := 90.0
const DASH_WIDTH := 42.0
const ATTACK_RATE := 4.0 / 3.0
const BURROW_TIME := 0.5
const EMERGENCE_WARNING_TIME := 1.0 / ATTACK_RATE
const DASH_WARNING_TIME := 1.2 / ATTACK_RATE
const DASH_SPEED := 1400.0
const CONTACT_DAMAGE := 40.0
const ENDLESS_HEALTH_GROWTH := 1.10
const EMERGENCE_DAMAGE := 60.0
const DASH_DAMAGE := 80.0
const EXPOSED_TIME := 3.0
const SURFACE_SPEED := 100.0

static func set_phase_timer(enemy: Dictionary, base_time: float) -> void:
 enemy.phase_duration = base_time if base_time == BURROW_TIME else base_time * randf_range(0.7, 1.3)
 enemy.timer = enemy.phase_duration

static func initialize(enemy: Dictionary) -> void:
 enemy.phase = "burrow"
 enemy.first_emergence_pending = true
 set_phase_timer(enemy, BURROW_TIME)
 enemy.target = enemy.pos
 enemy.dash_start = enemy.pos
 enemy.dash_end = enemy.pos

static func vulnerable(enemy: Dictionary) -> bool:
 return enemy.phase in ["exposed", "dash"]

static func update(enemy: Dictionary, dt: float, player: Vector2, arena: Vector2) -> bool:
 var movement_multiplier := float(enemy.get("stat_multiplier", 1.0))
 if enemy.phase != "dash": enemy.timer -= dt
 match enemy.phase:
  "burrow":
   if enemy.timer <= 0:
    if bool(enemy.get("first_emergence_pending", false)) or randf() < 0.5:
     enemy.first_emergence_pending = false
     enemy.phase = "emerge_warning"
     set_phase_timer(enemy, EMERGENCE_WARNING_TIME)
     enemy.target = player.clamp(Vector2.ONE * 104, arena - Vector2.ONE * 104)
    else:
     enemy.phase = "dash_warning"
     set_phase_timer(enemy, DASH_WARNING_TIME)
     var direction := Vector2.from_angle(randf_range(0.0, TAU))
     enemy.dash_start = (player - direction * 250).clamp(Vector2(45, 45), arena - Vector2(45, 45))
     enemy.dash_end = (player + direction * 250).clamp(Vector2(45, 45), arena - Vector2(45, 45))
     enemy.pos = enemy.dash_start
  "emerge_warning":
   if enemy.timer <= 0:
    enemy.pos = enemy.target
    enemy.phase = "exposed"
    set_phase_timer(enemy, EXPOSED_TIME)
    return true
  "dash_warning":
   if enemy.timer <= 0:
    enemy.phase = "dash"
    enemy.dash_remaining = enemy.pos.distance_to(enemy.dash_end)
  "dash":
   var step := minf(DASH_SPEED * dt, enemy.dash_remaining)
   enemy.pos = enemy.pos.move_toward(enemy.dash_end, step)
   enemy.dash_remaining -= step
   if enemy.dash_remaining <= 0:
    enemy.phase = "exposed"
    set_phase_timer(enemy, EXPOSED_TIME)
  "exposed":
   enemy.pos = enemy.pos.move_toward(player, SPEED_LIMITS.capped_speed(SURFACE_SPEED, movement_multiplier) * dt)
   if enemy.timer <= 0:
    enemy.phase = "burrow"
    set_phase_timer(enemy, BURROW_TIME)
 return false

