extends RefCounted

const PREFERENCES := ["speed", "rate", "damage", "shots", "max_health", "crit_chance", "luck"]
var direction := Vector2.RIGHT
var decision_timer := 0.0
var action_timer := 0.0
var last_state := ""

## A fixed clockwise orbit keeps the horde behind the boat. The radial
## correction returns to the route after dodging, without chasing a moving point.
static func orbit_direction(origin: Vector2, arena: Vector2) -> Vector2:
 var radii := arena * Vector2(0.33, 0.30)
 var offset := (origin - arena / 2.0) / radii
 if offset.length() < 0.1: return Vector2.RIGHT
 var radial := offset.normalized()
 var tangent := Vector2(-radial.y, radial.x)
 var correction := clampf((1.0 - offset.length()) * 3.0, -2.5, 2.5)
 return ((tangent + radial * correction) * radii).normalized()

static func boundary_risk(point: Vector2, arena: Vector2) -> float:
 var risk := 0.0
 # Summing all four sides makes a corner more dangerous than a single wall.
 for distance in [point.x, point.y, arena.x - point.x, arena.y - point.y]:
  risk += 40.0 * pow(maxf(0.0, (330.0 - distance) / 330.0), 2.0)
 return risk

static func preferred_upgrade(options: Array) -> String:
 for id in PREFERENCES:
  if id in options: return id
 return str(options[0]) if not options.is_empty() else ""

func tick(game: Node, delta: float) -> void:
 if game.window_focus_lost: return
 if game.state == "paused": game.resume()
 if game.state != last_state:
  last_state = game.state
  action_timer = 0.0
 action_timer += delta
 if game.state == "upgrade" and action_timer >= 0.8:
  action_timer = 0.0
  game.choose_upgrade(preferred_upgrade(game.choices), game.upgrade_generation)
 elif game.state in ["lost", "won"] and action_timer >= 2.0:
  action_timer = 0.0
  game.start_run("endless")
 elif game.state == "playing":
  decision_timer -= delta
  if decision_timer <= 0.0:
   decision_timer = 0.12
   direction = steer(game)

func steer(game: Node) -> Vector2:
 var origin: Vector2 = game.player
 var orbit := orbit_direction(origin, game.ARENA)
 var xp_direction := Vector2.ZERO
 var nearest := 240.0 * 240.0
 for gem in game.gems:
  var distance := origin.distance_squared_to(gem.pos)
  if distance < nearest and origin.direction_to(gem.pos).dot(orbit) > 0.35 and boundary_risk(gem.pos, game.ARENA) < 1.0:
   nearest = distance
   xp_direction = origin.direction_to(gem.pos)
 var nearby: Array[Dictionary] = []
 for enemy in game.enemies:
  if origin.distance_squared_to(enemy.pos) < 700.0 * 700.0 or enemy.get("phase", "") in ["dash_warning", "emerge_warning"]:
   nearby.append(enemy)
 var best := -INF
 var result := direction
 for i in 24:
  var candidate := Vector2.from_angle(TAU * i / 24.0)
  var point: Vector2 = origin + candidate * game.effective_speed() * 0.7
  var future: Vector2 = origin + candidate * maxf(250.0, game.effective_speed() * 1.6)
  var score := candidate.dot(orbit) * 7.0 + candidate.dot(direction) * 0.8 + candidate.dot(xp_direction) * 0.7
  score -= boundary_risk(point, game.ARENA) + boundary_risk(future, game.ARENA) * 0.7
  var exits := [0.0, 0.0, 0.0]
  for enemy in nearby:
   var phase: String = enemy.get("phase", "")
   var position: Vector2 = enemy.pos
   var radius: float = enemy.get("radius", 20.0) + 35.0
   if phase == "emerge_warning":
    position = enemy.target
    radius = 130.0
   elif phase in ["dash_warning", "dash"] and enemy.has("dash_start"):
    position = Geometry2D.get_closest_point_to_segment(point, enemy.dash_start, enemy.dash_end)
    radius = 85.0
   elif phase in ["warning", "dash"] and enemy.has("dash_direction"):
    var endpoint: Vector2 = position + enemy.dash_direction * float(enemy.get("dash_distance", 200.0))
    position = Geometry2D.get_closest_point_to_segment(point, position, endpoint)
    radius = 65.0
   elif phase == "burrow": continue
   else:
    var velocity: Vector2 = enemy.get("crowd_velocity", Vector2.ZERO)
    position += velocity * 0.4
   var gap := point.distance_to(position) - radius
   score -= 12.0 * pow(clampf((210.0 - gap) / 210.0, 0.0, 2.0), 2.0)
   var path := Geometry2D.get_closest_point_to_segment(position, origin, point)
   if path.distance_to(position) < radius: score -= 30.0
   # Look beyond the immediate dodge: prefer corridors with multiple ways out.
   for exit_index in 3:
    var escape: Vector2 = future + candidate.rotated((exit_index - 1) * PI / 3.0) * 160.0
    exits[exit_index] += clampf((180.0 + radius - escape.distance_to(position)) / 180.0, 0.0, 1.0)
  var open_exits := 0
  for exit_index in 3:
   var escape: Vector2 = future + candidate.rotated((exit_index - 1) * PI / 3.0) * 160.0
   if exits[exit_index] < 0.8 and boundary_risk(escape, game.ARENA) < 4.0: open_exits += 1
  score -= (3 - open_exits) * 2.5
  if score > best:
   best = score
   result = candidate
 return result
