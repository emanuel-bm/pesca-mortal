extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_horde_test()
 var started := Time.get_ticks_usec()
 game.update_minimap(0)
 for frame in 200:
  game.minimap_renderer.refresh(game)
 print("MINIMAP TRANSFORMS: %.3f ms" % [(Time.get_ticks_usec() - started) / 200000.0])
 started = Time.get_ticks_usec()
 for frame in 200:
  if game.has_method("rebuild_crowd_grid"):
   game.rebuild_crowd_grid()
   game.rebuild_projectile_grid()
  else:
   game.rebuild_enemy_grid()
   game.rebuild_enemy_grid()
 print("FRAME GRID BUILDS: %.3f ms" % [(Time.get_ticks_usec() - started) / 200000.0])
 quit(0)
