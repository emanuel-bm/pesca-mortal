extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run()
 game.rng.seed = 417
 game.elapsed = 420
 for index in 458:
  game.spawn_enemy(false)
  game.enemies[-1].pos = game.player + Vector2((index % 26) * 8 - 104, (index / 26) * 8 + 60)
 var samples: Array[float] = []
 for frame in 180:
  var started := Time.get_ticks_usec()
  game.update_crowd_snapshot(0.01)
  if game.has_method("begin_crowd_step"): game.begin_crowd_step()
  for index in game.enemies.size(): game.pursue_player(index, 0.01)
  samples.append((Time.get_ticks_usec() - started) / 1000.0)
 samples.sort()
 var total := 0.0
 for sample in samples: total += sample
 print("CROWD SPIKES: mean %.3f, p95 %.3f, max %.3f ms; 458 fish" % [total / samples.size(), samples[170], samples[-1]])
 quit(0)
