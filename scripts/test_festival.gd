extends SceneTree

const ONLINE = preload("res://scripts/online_ranking.gd")
const FESTIVAL = preload("res://scripts/festival.gd")
var client: Node

func _initialize() -> void:
 call_deferred("run")

func settle() -> void:
 var started := Time.get_ticks_msec()
 while client.busy:
  assert(Time.get_ticks_msec() - started < 10000, "HTTP mock did not answer")
  await process_frame
 await process_frame

func run() -> void:
 assert(FESTIVAL.enabled(), "Run this test with -- --festival")
 assert(FESTIVAL.valid_name("João Silva"))
 assert(FESTIVAL.valid_name("Festival Hightech"))
 for name in ["", "   ", "=SUM(A1)", "+name", "a".repeat(31)]: assert(not FESTIVAL.valid_name(name))
 client = ONLINE.new()
 client.storage_path = "user://test_festival_%d.json" % Time.get_ticks_usec()
 client.competitive_build = true
 root.add_child(client)
 client.endpoint = ""
 assert(client.nickname() == "Festival Hightech" and not client.profile.has("token"))
 client.set_nickname("Nome que não deve substituir o perfil automático")
 assert(client.nickname() == "Festival Hightech")
 var record := {"mode": "endless", "seconds": 60.0, "kills": 10, "level": 1, "character": "Pescador", "reason": "death", "run_id": "a".repeat(32), "record_valid": true, "competitive_version": ONLINE.HISTORY.competitive_version()}
 client.queue_record(record)
 assert(client.pending.is_empty(), "Festival cannot publish through the global account flow")
 assert(not client.queue_festival_record(record, ""))
 assert(client.queue_festival_record(record, "João Silva"))
 record.run_id = "b".repeat(32)
 record.seconds = 30.0
 assert(client.queue_festival_record(record, "Ana"))
 assert(client.pending.size() == 2, "A lower score belongs to a different participant")
 assert(client.nickname() == "Festival Hightech", "Participant names never replace the station profile")
 var reloaded := ONLINE.new()
 reloaded.storage_path = client.storage_path
 reloaded.load_state()
 assert(reloaded.pending.size() == 2 and reloaded.nickname() == "Festival Hightech")
 reloaded.free()
 client.endpoint = "http://127.0.0.1:18745/exec"
 client.synchronize()
 await settle()
 assert(client.pending.is_empty(), client.status)
 assert(client.rankings.endless.size() == 2, client.status)
 assert(client.rankings.endless[0].nickname == "João Silva")
 assert(client.rankings.endless[1].nickname == "Ana")
 assert(client.seasons.is_empty())
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.online.endpoint = ""
 assert(game.online.nickname() == "Festival Hightech", "Festival starts with its automatic station profile")
 game.online.competitive_build = true
 game.run_history.clear()
 game.show_menu()
 assert(game.state == "menu")
 assert(not game.records_personal.endless and not game.records_personal.bosses, "Both panels default to the festival")
 var global_view: Node = game.festival_global
 assert(global_view.read_only and not global_view.festival_mode)
 assert(global_view.storage_path != game.online.storage_path, "Global and festival caches stay separate")
 global_view.endpoint = "http://127.0.0.1:18745/exec"
 global_view.competitive_version = ONLINE.HISTORY.LEGACY_VERSION
 global_view.disabled = false
 global_view.competitive_build = true
 global_view.set_nickname("MustNotRegister")
 global_view.queue_record(record)
 assert(global_view.profile.is_empty() and global_view.pending.is_empty(), "Global viewer cannot register or submit results")
 global_view.synchronize()
 var view_started := Time.get_ticks_msec()
 while global_view.busy:
  assert(Time.get_ticks_msec() - view_started < 10000)
  await process_frame
 assert(global_view.fetched_at != "", global_view.status)
 assert(global_view.rankings.endless.is_empty(), "Global query must not return the festival's two entries")
 global_view.disabled = true
 global_view.rankings = {"endless": [{"nickname": "GlobalChampion", "seconds": 9000.0, "kills": 100, "level": 10}], "bosses": []}
 game.online.rankings = {"endless": [{"nickname": "FestivalParticipant", "seconds": 60.0, "kills": 10, "level": 1}], "bosses": []}
 game.show_records_panel()
 var labels: Array = game.records_panel.find_children("*", "Label", true, false)
 assert(labels.any(func(label: Label): return label.text == "FestivalParticipant"))
 assert(not labels.any(func(label: Label): return label.text == "GlobalChampion"))
 game.select_records_tab("endless", true)
 labels = game.records_panel.find_children("*", "Label", true, false)
 assert(labels.any(func(label: Label): return label.text == "GlobalChampion"))
 assert(not labels.any(func(label: Label): return label.text == "FestivalParticipant"))
 assert(not game.records_personal.bosses, "Each panel can show a different leaderboard")
 game.show_nickname()
 assert(game.state == "menu", "Festival never opens the account registration screen")
 assert(not game.records_personal.endless and not game.records_personal.bosses)
 game.start_run("endless")
 game.elapsed = 45.0
 game.kills = 7
 game.finish(false)
 assert(game.festival_name_edit.text.is_empty(), "Never carry a previous participant's name")
 assert(game.festival_name_edit.placeholder_text == "Seu nome ou apelido (opcional, salva no ranking)")
 assert(game.festival_name_edit.get_theme_font_size("font_size") == 16)
 assert(not game.festival_message.visible)
 await process_frame
 assert(not game.festival_name_edit.has_focus(), "No automatic focus on the name field after a run")
 game.festival_name_edit.grab_focus()
 assert(game.festival_name_edit.get_theme_color("caret_color").a == 0.0, "An empty field keeps its focus border but hides the caret")
 game.festival_name_edit.text = "Maria"
 game.festival_name_edit.text_changed.emit("Maria")
 assert(not game.festival_name_edit.has_theme_color_override("caret_color"), "Typing restores the normal caret")
 game.festival_name_edit.text = ""
 game.festival_name_edit.text_changed.emit("")
 for control in game.panel.find_children("*", "Button", true, false):
  assert(control.text not in ["Jogar novamente", "Salvar no ranking do festival"])
 assert(game.run_history.size() == 1 and game.player_totals.kills == 7)
 assert(game.player_totals.seconds == 45.0)
 assert(game.online.pending.is_empty(), "A finished run is not consent to publish")
 await game.exit_festival_result()
 assert(game.festival_result.is_empty() and game.online.pending.is_empty(), "Skipping the name discards the leaderboard entry")
 game._process(0.0)
 assert(game.profile_label.text.contains("PARTIDAS JOGADAS 1"))
 game.start_run("endless")
 game.elapsed = 30.0
 game.kills = 3
 game.finish(false)
 game.festival_result.debug_run = false
 game.festival_result.record_valid = true
 game.festival_name_edit.text = "Maria"
 await game.exit_festival_result()
 assert(game.online.pending.size() == 1)
 assert(game.state == "festival_save_failed", "Offline exit preserves the result and offers retry")
 game.online.endpoint = "http://127.0.0.1:18745/exec"
 game.online.disabled = false
 await game.exit_festival_result()
 assert(game.online.pending.is_empty() and game.state == "menu", "Exit waits for synchronization before returning to menu")
 assert(game.online.nickname() == "Festival Hightech")
 assert(game.run_history.size() == 2 and game.player_totals.kills == 10 and game.player_totals.seconds == 75.0)
 game.start_run("training")
 game.elapsed = 10.0
 game.record_run("menu")
 assert(game.run_history.size() == 2, "Training does not inflate festival totals")
 game.start_run("endless")
 game.elapsed = 20.0
 game.kills = 2
 game.finish(false)
 game.online.competitive_build = false
 game.festival_name_edit.text = "Teste debug"
 await game.exit_festival_result()
 assert(game.state == "festival_debug_notice", "Debug must explain that it did not publish, rather than silently imitate saving")
 assert(game.online.pending.is_empty())
 game.online.competitive_build = true
 game.start_run("bosses")
 game.elapsed = 150.0
 game.kills = 2
 game.finish(false)
 assert(game.festival_result.is_empty() and game.online.pending.is_empty(), "Boss Rush defeats never enter the festival ranking")
 for duration in [150.0, 180.0]:
  game.start_run("bosses")
  game.elapsed = duration
  game.kills = 2
  game.finish(true)
  assert(game.festival_result.reason == "won" and game.festival_result.mode == "bosses")
  game.festival_result.debug_run = false
  game.festival_result.record_valid = true
  game.festival_name_edit.text = "Vitoria_%d" % int(duration)
  await game.exit_festival_result()
  assert(game.state == "menu" and game.online.pending.is_empty(), game.online.status)
 assert(game.online.rankings.bosses.size() == 2, "Both Boss Rush victories publish, including the slower one")
 assert(game.online.rankings.bosses[0].seconds == 150.0 and game.online.rankings.bosses[1].seconds == 180.0)
 print("FESTIVAL BOSS RUSH PASS: defeats excluded; two victories sent through exit and returned by HTTP ranking")
 game.queue_free()
 DirAccess.remove_absolute(client.storage_path)
 client.queue_free()
 await process_frame
 print("FESTIVAL PASS: optional names, station totals, independent outbox, HTTP sync, isolation, replay")
 quit()
