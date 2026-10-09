extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://scripts/crowd_query_reference.gd").new()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 game.elapsed = 420.0
 game.speed = game.BASE_PLAYER_SPEED * 2.0
 game.attack_timer = INF
 for index in 518:
  game.spawn_enemy(false)
  var fish: Dictionary = game.enemies.back()
  fish.tank = index % 2 == 1
  fish.radius = 44.0 if fish.tank else 13.0
  fish.speed = 85.8 if fish.tank else game.FASTEST_ENEMY_SPEED
  fish.contact = 15.0 if fish.tank else 10.0
  fish.hp = (100.0 if fish.tank else 30.0) * (1 + game.elapsed / 300.0)
  fish.max_hp = fish.hp
 for index in 2: game.spawn_enemy(true)
 game.boss_spawned = true
 var rng := RandomNumberGenerator.new()
 rng.seed = 417
 for scenario in 3:
  for i in game.enemies.size():
   game.enemies[i].pos = game.player + Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * [90, 250, 700][scenario]
  game.rebuild_crowd_grid()
  for i in game.enemies.size():
   var direction: Vector2 = (game.player - game.enemies[i].pos).normalized()
   assert(game.crowd_separation(i, direction).is_equal_approx(game.legacy(i, direction)), "Separation changed")
  game.legacy_checked = 0
  var start := Time.get_ticks_usec()
  for repeat in 20:
   for i in game.enemies.size(): game.legacy(i, Vector2.RIGHT)
  var before := (Time.get_ticks_usec() - start) / 20000.0
  game.crowd_candidates_checked = 0
  game.crowd_cells_skipped = 0
  start = Time.get_ticks_usec()
  for repeat in 20:
   for i in game.enemies.size(): game.crowd_separation(i, Vector2.RIGHT)
  var after := (Time.get_ticks_usec() - start) / 20000.0
  print("QUERY scenario ", scenario, " old/new ms: ", before, "/", after, " candidates: ", game.legacy_checked, "/", game.crowd_candidates_checked, " skipped cells: ", game.crowd_cells_skipped)
 print("CROWD QUERY PASS: same force and neighbor order in dense, scattered and sparse scenes")
 quit()
