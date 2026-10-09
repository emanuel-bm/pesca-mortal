extends RefCounted

const EMERGENCE_RADIUS := 90.0
const DASH_WIDTH := 42.0
const ATTACK_RATE := 4.0 / 3.0
const BURROW_TIME := 0.8 / ATTACK_RATE
const TRACK_TIME := 0.5 / ATTACK_RATE
const EMERGENCE_WARNING_TIME := 1.0 / ATTACK_RATE
const DASH_WARNING_TIME := 1.2 / ATTACK_RATE
const DASH_TIME := 0.8 / (ATTACK_RATE * 1.2)
const EXPOSED_TIME := 3.0
const SURFACE_SPEED := 45.0 * 1.2

static func set_phase_timer(enemy: Dictionary, base_time: float) -> void:
 enemy.phase_duration = base_time * randf_range(0.7, 1.3)
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
 enemy.timer -= dt * (float(enemy.get("stat_multiplier", 1.0)) if enemy.phase == "dash" else 1.0)
 match enemy.phase:
  "burrow":
   if enemy.timer <= 0:
    if bool(enemy.get("first_emergence_pending", false)) or randf() < 0.5:
     enemy.first_emergence_pending = false
     enemy.phase = "tracking"
     set_phase_timer(enemy, TRACK_TIME)
     enemy.target = player
    else:
     enemy.phase = "dash_warning"
     set_phase_timer(enemy, DASH_WARNING_TIME)
     var direction := Vector2.from_angle(randf_range(0.0, TAU))
     enemy.dash_start = (player - direction * 250).clamp(Vector2(45, 45), arena - Vector2(45, 45))
     enemy.dash_end = (player + direction * 250).clamp(Vector2(45, 45), arena - Vector2(45, 45))
     enemy.pos = enemy.dash_start
  "tracking":
   enemy.target = player.clamp(Vector2.ONE * 104, arena - Vector2.ONE * 104)
   if enemy.timer <= 0:
    enemy.phase = "emerge_warning"
    set_phase_timer(enemy, EMERGENCE_WARNING_TIME)
  "emerge_warning":
   if enemy.timer <= 0:
    enemy.pos = enemy.target
    enemy.phase = "exposed"
    set_phase_timer(enemy, EXPOSED_TIME)
    return true
  "dash_warning":
   if enemy.timer <= 0:
    enemy.phase = "dash"
    set_phase_timer(enemy, DASH_TIME)
  "dash":
   enemy.pos = enemy.dash_start.lerp(enemy.dash_end, clampf(1.0 - enemy.timer / float(enemy.get("phase_duration", DASH_TIME)), 0, 1))
   if enemy.timer <= 0:
    enemy.phase = "exposed"
    set_phase_timer(enemy, EXPOSED_TIME)
  "exposed":
   enemy.pos = enemy.pos.move_toward(player, SURFACE_SPEED * float(enemy.get("stat_multiplier", 1.0)) * dt)
   if enemy.timer <= 0:
    enemy.phase = "burrow"
    set_phase_timer(enemy, BURROW_TIME)
 return false

