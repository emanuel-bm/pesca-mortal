extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for multiplier in [1.0, 1.5, 2.0, 10.0]:
  var fish := {"pos": Vector2(500, 800), "phase": "warning", "timer": 0.0, "stat_multiplier": multiplier, "dash_direction": Vector2.RIGHT, "radius": 23.0}
  fish.dash_distance = game.DOURADO.dash_range(fish)
  var expected: Vector2 = game.dourado_warning_endpoint(fish, fish.pos)
  game.DOURADO.update(fish, 0.0, Vector2(1200, 800), game.ARENA)
  assert(is_equal_approx(fish.dash_remaining, fish.dash_distance))
  fish.stat_multiplier *= 1.05
  var start: Vector2 = fish.pos
  game.DOURADO.update(fish, 0.1, Vector2(1200, 800), game.ARENA)
  assert(is_equal_approx(fish.pos.x - start.x, game.DOURADO.DASH_SPEED * 0.1), "Speed stays fixed at every buff level")
  game.DOURADO.update(fish, 10.0, Vector2(1200, 800), game.ARENA)
  if not Vector2(fish.pos).is_equal_approx(expected):
   push_error("Warning endpoint differs from dash endpoint at multiplier %s: indicated %s, reached %s" % [multiplier, expected, fish.pos])
   quit(1)
   return
 game.dourado_particles.clear()
 var charging := {"pos": Vector2(800, 800), "phase": "warning", "dash_direction": Vector2.RIGHT}
 game.update_dourado_particles(charging, charging.pos, "warning", 0.1)
 assert(not game.dourado_particles.is_empty(), "Preparation emits particles")
 game.dourado_particles.clear()
 charging.pos = Vector2(1100, 800)
 charging.phase = "recovery"
 game.update_dourado_particles(charging, Vector2(800, 800), "dash", 0.25)
 assert(game.dourado_particles.size() >= 9, "Particles cover the entire path including the final dash frame")
 assert(game.dourado_particles.front().origin.x == 776.0)
 assert(game.dourado_particles.back().origin.x >= 1056.0)
 print("DOURADO WARNING PASS: fixed speed, uncapped distance, locked warning, preparation particles and full trail")
 quit()
