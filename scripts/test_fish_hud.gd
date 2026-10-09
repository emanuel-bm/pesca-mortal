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
 game.start_endless_test()
 game.state = "paused"
 game._process(0)
 assert(game.hud.text.contains("PEIXES VISÍVEIS"))
 print("FISH HUD PASS: live fish across map, bosses excluded, diagnostics test-only, no duplicated level")
 quit()
