extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run()
 assert(game.magnet == 180.0)
 assert(not game.projected_stats().has("magnet"))
 assert(not game.stat_values.has("magnet"))
 game._apply_upgrade("magnet")
 assert(game.magnet == 180.0)
 game.speed = 249.0
 assert(is_equal_approx(game.projected_stats("speed").speed, 249.0 * 1.10))
 game._apply_upgrade("speed")
 assert(is_equal_approx(game.speed, 249.0 * 1.10))
 game.speed = 1000.0
 assert(not game.format_stat("speed", game.speed).contains("MAX"))
 assert(not game.format_stat("speed", game.speed - 1).contains("MAX"))
 for iteration in 20:
  game.show_upgrades()
  assert(not "magnet" in game.choices)
  assert(game.choices.size() == 3)
 game.start_run("endless")
 game.test_run = true
 for id in ["damage", "rate", "shots", "speed", "magnet"]:
  for rank in (5 if id == "speed" else 6): game._apply_upgrade(id)
 for id in ["damage", "rate", "shots", "magnet"]:
  for rank in (2 if id == "damage" else 1): game._apply_upgrade(id)
 game.level = 35
 game.elapsed = 420.0
 game.kills = 2900
 game.endless_wave = 4
 game.next_boss_time = 450.0
 game.boss_spawned = true
 for index in 2: game.spawn_enemy(true)
 assert(game.magnet == 180.0)
 print("UPGRADE CAPS PASS: collection fixed and hidden, speed unlimited, MAX labels, completed upgrades excluded")
 quit()
