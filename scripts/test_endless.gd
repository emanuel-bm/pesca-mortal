extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 await process_frame
 game.set_process(false)
 game.history_path = "user://test_pesca_endless_history.json"
 game.run_history.clear()
 game.start_run("endless")
 game.elapsed = 0
 game.invulnerability = 10000
 game.attack_timer = 10000
 game.spawn_timer = 10000
 game.update_game(0)
 assert(game.enemies.is_empty() and not game.boss_spawned, "No timed boss in endless mode")
 game.kills = 999
 game.spawn_endless_bosses()
 assert(game.enemies.is_empty())
 game.kills = 1000
 game.elapsed = 180
 game.spawn_endless_bosses()
 assert(game.enemies.is_empty() and game.next_boss_time == 240)
 game.elapsed = 239.99
 game.spawn_endless_bosses()
 assert(game.enemies.is_empty())
 game.elapsed = 240
 game.spawn_endless_bosses()
 assert(game.enemies.size() == 1 and game.next_boss_time == 360)
 game.spawn_endless_bosses()
 assert(game.enemies.size() == 1, "Milestone cannot spawn twice")
 game.kills = 3000
 game.elapsed = 840
 game.spawn_endless_bosses()
 assert(game.enemies.size() == 21 and game.endless_wave == 6, "Timed waves must spawn 1+2+3+4+5+6 independent of kills")
 game.spawn_enemy(false)
 var fish: Dictionary = game.enemies.back()
 fish.pos = Vector2(50, 50)
 fish.hp = 100.0
 fish.max_hp = 200.0
 fish.speed = 100.0
 fish.contact = 10.0
 var surviving_boss: Dictionary = game.enemies[1]
 game.enemies[0].hp = 0
 game.update_game(0)
 assert(game.state == "playing" and game.bosses_defeated == 1, "Boss death must not end endless run")
 assert(is_equal_approx(fish.hp, 105) and is_equal_approx(fish.max_hp, 210))
 assert(is_equal_approx(fish.speed, 105) and is_equal_approx(fish.contact, 10.5))
 assert(is_equal_approx(surviving_boss.max_hp, 32000 * 1.05))
 game.spawn_enemy(false)
 var fresh: Dictionary = game.enemies.back()
 var base_hp: float = (100.0 if fresh.tank else 30.0) * (1 + game.elapsed / 300.0)
 assert(is_equal_approx(fresh.max_hp, base_hp * 1.05), "New enemies inherit buffs")
 surviving_boss.hp = 0
 game.update_game(0)
 assert(game.bosses_defeated == 2 and is_equal_approx(fish.max_hp, 200 * pow(1.05, 2)))
 game.state = "paused"
 var before: float = game.elapsed
 game._process(0.5)
 assert(game.elapsed == before, "Pause must not increase survival time")
 game.finish(false)
 assert(game.run_history.size() == 1 and game.run_history[0].kills == 3002)
 var loaded: Array = game.RUN_HISTORY.load_records(game.history_path)
 assert(loaded.size() == 1 and loaded[0].seconds == 840)
 game.show_menu()
 assert(game.run_history.size() == 1, "Do not record twice")
 game.start_run("endless")
 game.elapsed = 100
 game.kills = 10
 game.restart_run()
 assert(game.run_mode == "endless" and game.run_history.size() == 2)
 game.elapsed = 20
 game.show_menu()
 assert(game.run_history.size() == 3)
 game.start_run("bosses")
 game.test_run = true
 for id in ["damage", "rate", "shots", "speed", "magnet"]:
  for rank in (5 if id == "speed" else 6): game.choose_upgrade(id)
 game.level = 30
 game.elapsed = game.RUN_SECONDS
 game.boss_spawned = true
 game.spawn_enemy(true)
 game.finish(false)
 assert(game.run_history.size() == 3, "Test mode must not enter ranking")
 var ranked: Array = game.RUN_HISTORY.ranked([
  {"seconds": 100.0, "kills": 1000}, {"seconds": 200.0, "kills": 1}, {"seconds": 100.0, "kills": 2000}
 ])
 assert(ranked[0].seconds == 200 and ranked[1].kills == 2000)
 assert(game.RUN_HISTORY.save_records(ranked, game.history_path) == OK)
 loaded = game.RUN_HISTORY.load_records(game.history_path)
 assert(loaded == ranked)
 game.run_history.clear()
 game.start_run("bosses")
 game.elapsed = 150
 game.level = 25
 game.kills = 42
 game.finish(true)
 game.start_run("endless")
 game.elapsed = 80
 game.kills = 20
 game.finish(false)
 assert(game.run_history.size() == 2)
 loaded = game.RUN_HISTORY.load_records(game.history_path)
 assert(loaded.size() == 2 and loaded[0].character == "Pescador")
 var boss_records: Array = loaded.filter(func(record: Dictionary) -> bool: return record.mode == "bosses")
 assert(boss_records[0].level == 25)
 assert(game.RUN_HISTORY.character_text(boss_records[0]) == "Pescador (lv25)")
 assert(game.RUN_HISTORY.character_text({"character": "Pescador"}) == "Pescador")
 assert(game.RUN_HISTORY.ranked(loaded).size() == 1)
 var chronological: Array = game.RUN_HISTORY.chronological([
  {"seconds": 500, "kills": 100, "date": "2026-01-01T10:00:00", "mode": "endless"},
  {"seconds": 10, "kills": 1, "date": "2026-02-01T10:00:00", "mode": "bosses"}
 ])
 assert(chronological[0].mode == "bosses")
 assert(game.RUN_HISTORY.ranked(chronological)[0].seconds == 500)
 var speed_records := [
  {"mode": "bosses", "reason": "won", "seconds": 300, "kills": 20, "level": 25},
  {"mode": "bosses", "reason": "won", "seconds": 200, "kills": 10, "level": 10},
  {"mode": "bosses", "reason": "death", "seconds": 5, "kills": 2, "level": 2},
  {"mode": "endless", "seconds": 400, "kills": 40, "level": 20}
 ]
 var speed_rank: Array = game.RUN_HISTORY.boss_ranked(speed_records)
 assert(speed_rank.size() == 2 and speed_rank[0].seconds == 200)
 var totals: Dictionary = game.RUN_HISTORY.totals(speed_records)
 assert(totals.seconds == 905 and totals.kills == 72 and totals.levels == 53)
 DirAccess.remove_absolute(ProjectSettings.globalize_path(game.history_path))
 game.start_run("endless")
 game.test_run = true
 for id in ["damage", "rate", "shots", "speed", "magnet"]:
  for rank in (5 if id == "speed" else 6): game.choose_upgrade(id)
 for id in ["damage", "rate", "shots", "magnet"]:
  for rank in (2 if id == "damage" else 1): game.choose_upgrade(id)
 game.level = 35
 game.elapsed = 690.0
 game.kills = 2900
 game.endless_wave = 4
 game.next_boss_time = 720.0
 game.boss_spawned = true
 for index in 2: game.spawn_enemy(true)
 assert(game.level == 35 and game.kills == 2900 and game.elapsed == 690)
 assert(game.test_run and game.run_mode == "endless" and game.enemies.size() == 2)
 assert(game.next_boss_time == 720)
 game.kills = 2999
 game.spawn_endless_bosses()
 assert(game.enemies.size() == 2)
 game.kills = 3000
 game.elapsed = 720
 game.spawn_endless_bosses()
 assert(game.enemies.size() == 7 and game.next_boss_time == 840)
 game.spawn_endless_bosses()
 assert(game.enemies.size() == 7)
 game.kills = 4000
 game.elapsed = 840
 game.spawn_endless_bosses()
 assert(game.enemies.size() == 13 and game.next_boss_time == 960)
 game.restart_run()
 assert(not game.test_run and game.run_mode == "endless" and game.level == 1 and game.kills == 0 and game.enemies.is_empty())
 assert(game.next_boss_time == 240, "Restart must restore the first boss at four minutes")
 var before_test_finish: int = game.run_history.size()
 game.finish(false)
 assert(game.run_history.size() == before_test_finish)
 print("ENDLESS PASS: milestones, simultaneous bosses, compounding buffs, continuing runs, pause, persistence, ranking, no duplicates or test records")
 if "--capture" in OS.get_cmdline_user_args():
  game.run_history = ranked
  game.show_menu()
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/endless-menu.png")
  game.show_history()
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/endless-history.png")
 quit(0)

