extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://scripts/crowd_query_reference.gd").new()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_horde_test()
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
