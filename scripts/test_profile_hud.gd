extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.history_path = "user://test_profile_hud.json"
 game.run_history.clear()
 game.start_run("endless")
 game.level = 25
 game.elapsed = 90
 game.kills = 100
 game.show_pause()
 game._process(0)
 assert(game.hud.text.contains("NÍVEL 25"))
 game.show_settings()
 game._process(0)
 assert(game.hud.text.contains("NÍVEL 25"))
 game.show_menu()
 var records: Array = game.RUN_HISTORY.load_records(game.history_path)
 assert(records[0].level == 25)
 assert(game.RUN_HISTORY.totals(records).levels == 24)
 game.show_history()
 game._process(0)
 var passed: bool = game.hud.text.contains("NÍVEIS CONQUISTADOS 24")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(game.history_path))
 if not passed:
  push_error("Histórico exibiu dados da última partida: " + game.hud.text)
  quit(1)
  return
 game.show_settings()
 game._process(0)
 assert(game.hud.text.contains("NÍVEIS CONQUISTADOS 24"))
 game.start_run("bosses")
 game.elapsed = 10
 game.level = 3
 game.finish(true)
 game._process(0)
 assert(game.hud.text.contains("NÍVEIS CONQUISTADOS 26"))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(game.history_path))
 print("PROFILE PASS: final level persisted, paused run HUD, historical profile HUD")
 quit(0)
