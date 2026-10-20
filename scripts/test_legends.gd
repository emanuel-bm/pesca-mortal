extends SceneTree

const HISTORY = preload("res://scripts/run_history.gd")
const ONLINE = preload("res://scripts/online_ranking.gd")
var game: Node

class RegistrationProbe extends ONLINE:
 var sent_action := ""
 func _send(operation: String, _payload: Dictionary) -> void:
  sent_action = operation

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var probe := RegistrationProbe.new()
 probe.endpoint = "http://127.0.0.1:18745/exec"
 probe.profile = {"nickname": "Teste", "token": "a".repeat(64)}
 probe.pending = {"0.4:endless": {"seconds": 53.0}}
 probe.synchronize()
 assert(probe.sent_action == "register", "A saved nickname without player_id must complete registration before uploading scores")
 probe.free()
 assert(HISTORY.competitive_version("v0.3.99") == "0.3")
 assert(HISTORY.competitive_version("1.0.0") == "1.0")
 var old := {"mode": "endless", "seconds": 500.0, "kills": 10, "level": 1, "character": "Pescador", "reason": "death"}
 var records := HISTORY.normalized([old])
 assert(records[0].competitive_version == "0.3", "Legacy records must keep a stable version")
 assert(HISTORY.for_version(records, "0.4").is_empty())
 var client := ONLINE.new()
 client.storage_path = "user://test_legends_client.json"
 client.competitive_version = "0.4"
 client.network_disabled = true
 root.add_child(client)
 client.competitive_build = true
 client.pending.clear()
 # A deployed pre-seasons backend returns rankings without version metadata.
 var notifications := [0]
 client.changed.connect(func() -> void: notifications[0] += 1)
 client.action = "ranking"
 client.busy = true
 client._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify({"ok": true, "rankings": {"endless": [{"nickname": "Legado", "seconds": 500.0, "kills": 10}], "bosses": []}}).to_utf8_buffer())
 assert(not client.busy and notifications[0] == 1, "Rejected legacy response must notify the UI to stop loading")
 assert(client.status == "O serviço de ranking precisa ser atualizado para separar os recordes por versão.")
 assert(client.rankings.endless.is_empty(), "Legacy records must not enter the current ranking")
 client.action = "legends"
 client.requested_version = "0.3"
 client.busy = true
 client._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify({"ok": true, "competitive_version": "0.4", "rankings": {"endless": [], "bosses": []}}).to_utf8_buffer())
 assert(not client.busy and notifications[0] == 2, "Wrong archive version must also release the loading UI")
 assert(not client.legends.has("0.3"), "Wrong-version response must not overwrite an archive")
 client.queue_record(records[0])
 var fresh: Dictionary = old.duplicate()
 fresh.competitive_version = "0.4"
 fresh.seconds = 60.0
 client.queue_record(fresh)
 assert(client.pending.size() == 2, "Different seasons must not overwrite offline scores")
 assert(client.pending["0.3:endless"].seconds == 500.0)
 assert(client.pending["0.4:endless"].seconds == 60.0)
 var restored := ONLINE.new()
 restored.competitive_version = "0.4"
 restored.storage_path = client.storage_path
 restored.load_state()
 assert(restored.pending.size() == 2)
 restored.free()
 # An older cache and unversioned outbox must migrate without contaminating 0.4.
 var file := FileAccess.open(client.storage_path, FileAccess.WRITE)
 file.store_string(JSON.stringify({"profile": {"nickname": "Legado"}, "pending": {"endless": old}, "rankings": {"endless": [old], "bosses": []}}))
 file.close()
 restored = ONLINE.new()
 restored.storage_path = client.storage_path
 restored.competitive_version = "0.4"
 restored.load_state()
 assert(restored.pending.has("0.3:endless"))
 assert(restored.rankings.endless.is_empty(), "Old cache must not appear as the new ranking")
 assert(restored.nickname() == "Legado")
 restored.free()
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.online.network_disabled = true
 game.online.endpoint = ""
 game.online.pending.clear()
 game.online.competitive_version = "0.4"
 game.online.storage_path = "user://test_legends_game_client.json"
 game.history_path = "user://test_legends_history.json"
 game.run_history = records
 game.start_run("endless")
 game.elapsed = 60.0
 game.kills = 10
 game.record_run("death")
 if OS.is_debug_build():
  assert(game.online.pending.is_empty(), "Debug runs must not enter a competitive season")
 else:
  assert(game.online.pending["0.4:endless"].seconds == 60.0, "Previous season's best must not prevent a new submission")
 var loaded := HISTORY.load_records(game.history_path)
 assert(loaded.size() == 2)
 assert(HISTORY.for_version(loaded, "0.3")[0].seconds == 500.0)
 assert(HISTORY.for_version(loaded, "0.4")[0].seconds == 60.0)
 # Seed a valid release result to exercise personal-ranking UI in debug tests.
 for record in loaded:
  record.debug_run = false
  record.record_valid = true
 game.run_history = loaded
 game.online.seasons = ["0.3", "0.2", "0.1"]
 game.online.profile = {"nickname": "Pescador"}
 var archived: Array = []
 for i in 100:
  archived.append({"nickname": "Pescador_%03d" % i, "seconds": 600.0 - i, "kills": 100 - i, "level": 10})
 game.online.legends = {"0.3": {"endless": archived, "bosses": []}, "0.2": {"endless": [archived[1]], "bosses": []}, "0.1": {"endless": [archived[2]], "bosses": []}}
 game.show_menu()
 for frame in 3: await process_frame
 var legends_buttons: Array = game.menu_controls.filter(func(control: Control) -> bool: return control is Button and control.text == "Lendas")
 assert(legends_buttons.size() == 2, "Both ranking panels must expose Lendas to keyboard navigation")
 legends_buttons[0].pressed.emit()
 await process_frame
 await process_frame
 assert(game.state == "legends")
 assert(not game.records_panel.visible and not game.boss_records_panel.visible)
 assert(game.legends_version == "0.4", "Lendas must open on the current competitive version")
 assert("0.4" in game.legends_versions() and "0.3" in game.legends_versions())
 game.online.disabled = false
 game.online.network_disabled = false
 game.online.busy = true
 game.online.action = "ranking"
 game.show_menu()
 assert(game.records_panel.find_child("RankingLoading", true, false) != null, "Global records must show a centered loading indicator")
 game.show_legends()
 assert(game.panel.find_child("RankingLoading", true, false) != null, "Lendas must show loading in place of its ranking")
 game.online.busy = false
 game.online_changed()
 assert(game.panel.find_child("RankingLoading", true, false) == null, "Loading must disappear when the request completes")
 game.run_active = false
 game._process(0.0)
 assert(not game.profile_panel.visible, "The profile card must stay hidden in Lendas")
 game.online.seasons = []
 game.show_legends()
 await process_frame
 await process_frame
 var picker: OptionButton = game.panel.get_child(1).get_child(0)
 assert(not picker.disabled and picker.get_item_text(picker.selected) == "v0.4", "Current version must be selectable without archives")
 game.online.rankings.endless = [{"nickname": "Atual", "seconds": 60.0, "kills": 10, "level": 1}]
 game.render_legends()
 var podium: VBoxContainer = game.panel.find_child("Podium", true, false)
 assert(podium.get_child_count() == 1)
 assert(podium.get_child(0).get_child(0).get_child(1).text == "Atual", "Current version must show its live ranking")
 var personal: PanelContainer = game.panel.find_child("PersonalBest", true, false)
 assert("00:01:00" in personal.get_child(0).get_child(3).text, "Personal best must follow the selected version")
 game.online.seasons = ["0.3", "0.2", "0.1"]
 game.choose_legends_version(game.legends_versions().find("0.3"), game.legends_versions())
 assert(game.legends_version == "0.3")
 podium = game.panel.find_child("Podium", true, false)
 assert(podium.get_child_count() == 3)
 var list: VBoxContainer = game.panel.find_child("LegendList", true, false)
 assert(list.get_child(0).get_child(0).get_child(0).text == "4", "The list must start after the podium")
 personal = game.panel.find_child("PersonalBest", true, false)
 assert("00:08:20" in personal.get_child(0).get_child(3).text, "Archived personal best must remain visible outside the scrolling list")
 assert(personal.get_child(0).get_child(0).text == "-", "A player outside the top 100 must have no global position")
 game.online.profile.player_id = "self"
 archived[4].player_id = "self"
 game.render_legends()
 personal = game.panel.find_child("PersonalBest", true, false)
 assert(personal.get_child(0).get_child(0).text == "5")
 assert(personal.get_child(0).get_child(1).text == archived[4].nickname, "Repeat the global result even if its archived nickname differs")
 assert(personal.get_child(0).get_child(3).text == game.RUN_HISTORY.time_text(archived[4].seconds))
 game.choose_legends_mode(1)
 assert(game.legends_mode == "bosses")
 game.choose_legends_mode(0)
 game.set_process(true)
 if "--capture" in OS.get_cmdline_user_args():
  root.size = Vector2i(1280, 720)
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/lendas-preview.png")
  game.show_menu()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/lendas-menu-preview.png")
 game.run_active = false
 game.online.disabled = true
 client.queue_free()
 game.queue_free()
 for path in [client.storage_path, "user://test_legends_game_client.json", "user://test_legends_history.json"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 await process_frame
 print("LEGENDS PASS: version migration, independent outboxes, cache isolation, new best by season, history persistence, legends selectors and 100-row UI")
 quit()
