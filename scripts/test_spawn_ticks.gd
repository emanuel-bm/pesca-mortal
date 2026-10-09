extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("endless")
 game.attack_timer = INF
 game.invulnerability = INF
 game.update_game(0)
 assert(game.enemies.size() == 3)
 for step in 9: game.update_game(0.1)
 assert(game.enemies.size() == 3)
 game.update_game(0.11)
 assert(game.enemies.size() == 6)
 var early: float = game.fish_spawn_rate()
 game.elapsed = 180
 assert(game.fish_spawn_rate() > early)
 for pair in [[0, 3], [60, 3], [120, 3], [150, 3], [180, 4], [300, 7], [450, 11], [600, 15], [900, 22], [1200, 30]]:
  game.elapsed = pair[0]
  assert(is_equal_approx(game.fish_spawn_rate(), pair[1]))
 game.enemies.clear()
 for index in 999: game.spawn_enemy(false)
 game.spawn_timer = 0
 game.next_boss_time = INF # Isolate the common-enemy cap from the timed boss wave.
 game.elapsed = 100
 game.update_game(0)
 assert(game.enemies.size() == 1000)
 print("SPAWN TICKS PASS: 1-second waves, growing count, cap 1000")
 quit()
