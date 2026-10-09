extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
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
