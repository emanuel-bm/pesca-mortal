extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.online.profile = {"nickname": "Teste"}
 game.show_nickname()
 game.nickname_attempted = true
 game.online.busy = true
 game.online.action = "rename"
 game.online.status = "Salvando nome…"
 game.online_changed()
 assert(game.nickname_save_button.text == "Salvando...")
 assert(game.nickname_save_button.disabled)
 assert(not game.online_status_label.visible)
 game.online.action = "ranking"
 game.online_changed()
 assert(game.nickname_save_button.text == "Carregando...")
 assert(not game.online_status_label.visible)
 game.online.busy = false
 game.online.status = "Ranking atualizado."
 game.online_changed()
 assert(game.nickname_save_button.text == "Salvar nome")
 assert(not game.online_status_label.visible)
 game.online.action = "rename"
 game.online.status = "Esse nome já está em uso. Escolha outro."
 game.online_changed()
 assert(game.online_status_label.visible)
 assert(game.panel.get_children().find(game.online_status_label) < game.panel.get_children().find(game.nickname_edit))
 game.history_path = "user://test_profile_hud.json"
 game.run_history.clear()
 game.start_run("endless")
 game.level = 25
 game.elapsed = 90
 game.kills = 100
 game.show_pause()
 game._process(0)
 assert(game.hud.text.begins_with("01:30    ELIMINAÇÕES 100"))
 assert(not game.hud.text.contains("(lv"))
 assert(game.stats_heading.text == "ATRIBUTOS DO PESCADOR (lv25)")
 game.show_settings()
 game._process(0)
 assert(game.hud.text.begins_with("01:30    ELIMINAÇÕES 100"))
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
 game.start_run("endless")
 game.enemies.clear()
 for boss in [false, false, true, true]: game.spawn_enemy(boss)
 game.enemies[3].hp = 0
 game.finish(false)
 game._process(0)
 assert(not game.profile_panel.visible)
 var summary := ""
 for child in game.panel.get_children():
  if child is Label: summary += child.text + "\n"
 assert(summary.contains("Teste"))
 assert(summary.contains("Peixes vivos: 2 · Chefes vivos: 1"))
 assert(not summary.contains("ELIMINAÇÕES TOTAIS"))
 var actions: HBoxContainer = game.panel.get_child(game.panel.get_child_count() - 1)
 assert(actions.get_child_count() == 2)
 for frame in 5: await process_frame
 assert(actions.get_child(0).get_global_rect().end.x <= actions.get_child(1).get_global_rect().position.x)
 game.enemies.clear()
 game._process(0)
 assert(game.panel.get_child(3).text == "Peixes vivos: 2 · Chefes vivos: 1")
 game.show_menu()
 game._process(0)
 assert(game.profile_panel.visible)
 assert(game.panel.get_theme_constant("separation") == 16)
 DirAccess.remove_absolute(ProjectSettings.globalize_path(game.history_path))
 print("PROFILE PASS: final level persisted, paused run HUD, historical profile HUD")
 quit(0)
