extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for count in [40, 200, 520]:
  game.start_run()
  game.rng.seed = 417
  game.elapsed = 420
  for index in count:
   game.spawn_enemy(false)
   game.enemies[-1].pos = game.player + Vector2((index % 26) * 8 - 104, (index / 26) * 8 + 60)
  var started := Time.get_ticks_usec()
  for frame in 60:
   game.update_crowd_snapshot(1.0 / 60)
   game.begin_crowd_step()
   game.rebuild_projectile_grid()
   for index in game.enemies.size(): game.pursue_player(index, 1.0 / 60)
  print("CROWD %d: %.3f ms/frame" % [count, (Time.get_ticks_usec() - started) / 60000.0])
 quit(0)
