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
 for fish in game.enemies:
  var multiplier: float = game.fish_stat_multiplier(fish.get("species", ""))
  var base_speed: float = 80.0 if fish.tank else 125.0
  if fish.get("species", "") == "dourado": base_speed = 100.0
  if fish.get("species", "") == "pacu": base_speed = 125.0
  assert(is_equal_approx(fish.speed, base_speed * pow(1.08, 10)))
 var original_speed: float = game.enemies.back().speed
 game.buff_endless_enemies()
 assert(is_equal_approx(game.enemies.back().speed, original_speed))
 for species in ["piranha", "pintado", "pacu", "dourado"]:
  game.start_run("endless")
  game.elapsed = 600
  game.spawn_enemy(false, species)
  var capped: Dictionary = game.enemies.back()
  var cap: float = game.fish_speed_cap(capped)
  var initial_health: float = capped.max_hp
  assert(is_equal_approx(capped.speed, cap))
  game.elapsed = 1200
  game.update_minute_buffs()
  game.buff_endless_enemies()
  assert(is_equal_approx(capped.speed, cap))
  game.spawn_enemy(false, species)
  assert(is_equal_approx(game.enemies.back().speed, cap))
  assert(game.enemies.back().max_hp > initial_health)
  assert(is_equal_approx(game.enemies.back().max_hp, capped.max_hp))
  if species == "dourado":
   assert(is_equal_approx(game.DOURADO.dash_speed(capped), game.DOURADO.DASH_SPEED))
   assert(is_equal_approx(game.DOURADO.dash_range(capped), game.DOURADO.DASH_BASE_DISTANCE * capped.stat_multiplier))
 game.start_run("endless")
 game.bosses_defeated = 15
 game.spawn_enemy(true, "pai_do_mato")
 var forest_boss: Dictionary = game.enemies.back()
 assert(is_equal_approx(forest_boss.speed, game.PAI_DO_MATO.MOVE_SPEED * pow(1.05, 15)))
 for index in 30: game.buff_endless_enemies()
 assert(is_equal_approx(forest_boss.speed, game.PAI_DO_MATO.MOVE_SPEED * pow(1.08, 10)))
 game.spawn_enemy(true, "pai_do_mato")
 assert(is_equal_approx(game.enemies.back().speed, forest_boss.speed))
 game.spawn_enemy(true)
 var worm: Dictionary = game.enemies.back()
 assert(is_equal_approx(worm.speed, 100.0 * pow(1.08, 10)))
 game.buff_endless_enemies()
 assert(is_equal_approx(worm.speed, 100.0 * pow(1.08, 10)))
 for index in 30: game.choose_upgrade("speed")
 assert(is_equal_approx(game.speed, 190.0 * pow(1.10, 30)))
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
  assert(is_equal_approx(boss.pos.x - 500, 100.0 * minf(boss_multiplier, pow(1.08, 10)) * 0.1))
  boss = {"pos": Vector2(500, 500), "phase": "dash", "dash_remaining": 500.0, "dash_start": Vector2(500, 500), "dash_end": Vector2(1000, 500), "stat_multiplier": boss_multiplier}
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.pos.x - 500, 140.0))
  boss.phase = "emerge_warning"
  boss.timer = 1.0
  game.MINHOCAO.update(boss, 0.1, Vector2(1000, 500), game.ARENA)
  assert(is_equal_approx(boss.timer, 0.9))
 game.start_run()
 game.spawn_timer = 100.0
 var edge_dash := {"pos": Vector2(45, 45), "phase": "dash", "dash_remaining": 60.0, "dash_end": Vector2(105, 45), "stat_multiplier": 100.0}
 game.MINHOCAO.update(edge_dash, 0.02, Vector2(100, 100), game.ARENA)
 assert(is_equal_approx(edge_dash.pos.x, 73.0), "Short edge dash retains 1400 pixels/second even with buffs")
 game.MINHOCAO.update(edge_dash, 0.1, Vector2(100, 100), game.ARENA)
 assert(edge_dash.pos == edge_dash.dash_end and edge_dash.phase == "exposed")
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
 print("SPEED/XP PASS: capped fish speeds, unlimited player speed; independent movement; consecutive level-up choices")
 quit()
