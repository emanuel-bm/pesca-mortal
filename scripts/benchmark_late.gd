extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run()
 game.elapsed = 300
 game.boss_spawned = true
 game.spawn_timer = 10000
 game.attack_timer = 10000
 game.invulnerability = 10000
 game.rng.seed = 417
 for i in 500:
  game.spawn_enemy(false)
  var enemy: Dictionary = game.enemies.back()
  enemy.pos = Vector2(game.rng.randf_range(30, 2370), game.rng.randf_range(30, 1770))
  enemy.hp = 1e12
 game.spawn_enemy(true)
 var projectile_positions: Array[Vector2] = []
 for i in 300: projectile_positions.append(Vector2(game.rng.randf_range(0, 2400), game.rng.randf_range(0, 1800)))
 var start := Time.get_ticks_usec()
 for frame in 30:
  game.bullets.clear()
  for position in projectile_positions: game.bullets.append({"pos": position, "velocity": Vector2.ZERO, "life": 1000.0})
  game.update_game(0)
 var ms := (Time.get_ticks_usec() - start) / 1000.0 / 30
 print("LATE CPU: %.2f ms/update, 501 enemies, 300 spears (seed 417)" % ms)
 quit(0)
