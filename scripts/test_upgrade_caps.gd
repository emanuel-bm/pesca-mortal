extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run()
 game.magnet = 499
 assert(game.projected_stats("magnet").magnet == 500)
 game.choose_upgrade("magnet")
 assert(game.magnet == 500)
 assert(game.format_stat("magnet", 500) == "500 (MAX)")
 game.update_stats_preview()
 assert(game.stat_values.magnet.get_theme_color("font_color").is_equal_approx(Color(0.5, 0.85, 1.0)))
 assert(not game.format_stat("magnet", 499).contains("MAX"))
 game.speed = 249.0
 assert(game.projected_stats("speed").speed == 250.0)
 game.choose_upgrade("speed")
 assert(game.speed == 250.0)
 game.speed = game.MAX_PLAYER_SPEED
 assert(game.format_stat("speed", game.speed).ends_with(" (MAX)"))
 assert(not game.format_stat("speed", game.speed - 1).contains("MAX"))
 for iteration in 20:
  game.show_upgrades()
  assert(not "magnet" in game.choices and not "speed" in game.choices)
  assert(game.choices.size() == 3)
 game.start_run("endless")
 game.test_run = true
 for id in ["damage", "rate", "shots", "speed", "magnet"]:
  for rank in (5 if id == "speed" else 6): game.choose_upgrade(id)
 for id in ["damage", "rate", "shots", "magnet"]:
  for rank in (2 if id == "damage" else 1): game.choose_upgrade(id)
 game.level = 35
 game.elapsed = 420.0
 game.kills = 2900
 game.endless_wave = 4
 game.next_boss_time = 450.0
 game.boss_spawned = true
 for index in 2: game.spawn_enemy(true)
 assert(game.magnet <= 500)
 print("UPGRADE CAPS PASS: collection capped, MAX labels, completed upgrades excluded, test loadout capped")
 quit()
