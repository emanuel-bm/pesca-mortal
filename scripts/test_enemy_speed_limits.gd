extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.online.disabled = true
 game.start_run("endless")
 game.test_run = true
 assert(is_equal_approx(game.enemy_speed_cap(), 171.0))
 game.elapsed = 10000
 game.bosses_defeated = 100
 for index in 40: game.spawn_enemy(false)
 for fish in game.enemies: assert(is_equal_approx(fish.speed, 171.0))
 game.buff_endless_enemies()
 for fish in game.enemies: assert(is_equal_approx(fish.speed, 171.0))
 game.choose_upgrade("speed")
 assert(is_equal_approx(game.enemy_speed_cap(), 190.0 * 1.04 * 0.9))
 game.buff_endless_enemies()
 for fish in game.enemies: assert(is_equal_approx(fish.speed, game.enemy_speed_cap()))
 game.max_player_speed = 300.0
 for index in 30: game.choose_upgrade("speed")
 assert(game.speed == 300.0 and game.enemy_speed_cap() == 270.0)
 assert(not game.format_stat("speed", 250.0).contains("MAX"))
 assert(game.format_stat("speed", 300.0).ends_with(" (MAX)"))
 game.show_upgrades()
 assert(not "speed" in game.choices)
 game.resume()
 game.spawn_enemy(false)
 assert(game.enemies.back().speed == 270.0)
 game.speed = 190.0
 var fish: Dictionary = game.enemies.back()
 fish.pos = Vector2(500, 500)
 fish.crowd_velocity = Vector2(270, 0)
 fish.desired_velocity = Vector2(270, 0)
 fish.separation_timer = 1.0
 var before: Vector2 = fish.pos
 game.pursue_player(game.enemies.size() - 1, 0.1)
 assert(fish.pos.distance_to(before) <= 17.101)
 # Compare capped boss movement against its original, at the same phase duration.
 for multiplier in [1.0, 1.05, 1.5, 10.0]:
  var boss := {"pos": Vector2(500, 500), "phase": "exposed", "timer": 3.0, "stat_multiplier": multiplier}
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.pos.x - 500, 54.0 * minf(multiplier, 1.5) * 0.1))
  boss = {"pos": Vector2(500, 500), "phase": "dash", "timer": 1.0, "phase_duration": 1.0, "dash_start": Vector2(500, 500), "dash_end": Vector2(1000, 500), "stat_multiplier": multiplier}
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.pos.x - 500, 500.0 * minf(multiplier, 1.5) * 0.1))
  boss.phase = "tracking"
  boss.timer = 1.0
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.timer, 0.9))
 print("SPEED LIMITS PASS: current player speed, upgrade/config changes, spawn/buff/movement caps, independent boss movement cap and unchanged warnings")
 quit()
