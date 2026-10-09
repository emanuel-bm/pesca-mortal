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
 game.elapsed = 10000
 game.bosses_defeated = 100
 for index in 40: game.spawn_enemy(false)
 var multiplier := pow(1.05, 100)
 for fish in game.enemies:
  var base_speed: float = 85.8 if fish.tank else (105.0 + game.elapsed * 0.1) * game.MOVEMENT_MULTIPLIER
  assert(is_equal_approx(fish.speed, base_speed * multiplier))
 var original_speed: float = game.enemies.back().speed
 game.buff_endless_enemies()
 assert(is_equal_approx(game.enemies.back().speed, original_speed * 1.05))
 for index in 30: game.choose_upgrade("speed")
 assert(is_equal_approx(game.speed, 190.0 * pow(1.04, 30)))
 assert(game.speed > 300.0 and not game.format_stat("speed", game.speed).contains("MAX"))
 game.speed = 1.0
 var fish: Dictionary = game.enemies.back()
 fish.pos = Vector2(500, 500)
 fish.speed = 400.0
 fish.crowd_velocity = Vector2(400, 0)
 fish.desired_velocity = Vector2(400, 0)
 fish.separation_timer = 1.0
 var before: Vector2 = fish.pos
 game.pursue_player(game.enemies.size() - 1, 0.1)
 assert(is_equal_approx(fish.pos.distance_to(before), 40.0))
 for boss_multiplier in [1.0, 1.05, 1.5, 10.0]:
  var boss := {"pos": Vector2(500, 500), "phase": "exposed", "timer": 3.0, "stat_multiplier": boss_multiplier}
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.pos.x - 500, 54.0 * boss_multiplier * 0.1))
  boss = {"pos": Vector2(500, 500), "phase": "dash", "timer": 1.0, "phase_duration": 1.0, "dash_start": Vector2(500, 500), "dash_end": Vector2(1000, 500), "stat_multiplier": boss_multiplier}
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.pos.x - 500, 500.0 * boss_multiplier * 0.1))
  boss.phase = "tracking"
  boss.timer = 1.0
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.timer, 0.9))
 game.start_run()
 game.spawn_timer = 100.0
 game.attack_timer = 100.0
 var first_cost: int = game.xp_needed()
 game.level = 2
 var second_cost: int = game.xp_needed()
 game.level = 1
 game.collect_xp(first_cost + second_cost + 2)
 game.update_game(0.0)
 assert(game.level == 2 and game.state == "upgrade")
 game.choose_upgrade(game.choices[0])
 assert(game.level == 3 and game.state == "upgrade", "Surplus XP must immediately open the second choice screen")
 game.choose_upgrade(game.choices[0])
 assert(game.state == "playing" and game.xp == 2)
 print("SPEED/XP PASS: unlimited speeds; independent movement; consecutive level-up choices")
 quit()
