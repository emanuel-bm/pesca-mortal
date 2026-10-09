extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for mode in ["bosses", "endless"]:
  game.start_run(mode)
  game.spawn_timer = INF
  game.attack_timer = INF
  game.spawn_enemy(false)
  game.enemies[-1].pos = Vector2(10, 10)
  game.spawn_enemy(false)
  game.enemies[-1].hp = 0
  game.spawn_enemy(true)
  game.state = "paused"
  game._process(0)
  assert(game.hud.text.contains("PEIXES 1"))
  assert(not game.hud.text.contains("VISÍVEIS") and not game.hud.text.contains("NÍVEL"))
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
 game.state = "paused"
 game._process(0)
 assert(game.hud.text.contains("PEIXES VISÍVEIS"))
 print("FISH HUD PASS: live fish across map, bosses excluded, diagnostics test-only, no duplicated level")
 quit()
