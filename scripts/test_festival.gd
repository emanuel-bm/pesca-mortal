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
 var record := {"mode": "endless", "seconds": 60.0, "kills": 10, "level": 1, "character": "Pescador", "reason": "death", "run_id": "a".repeat(32), "record_valid": true, "competitive_version": "0.4"}
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
 game.show_nickname()
 assert(game.state == "menu", "Festival never opens the account registration screen")
 game.start_run("endless")
 game.elapsed = 45.0
 game.kills = 7
 game.finish(false)
 assert(game.festival_name_edit.text.is_empty(), "Never carry a previous participant's name")
 assert(game.run_history.size() == 1 and game.player_totals.kills == 7)
 assert(game.player_totals.seconds == 45.0)
 assert(game.online.pending.is_empty(), "A finished run is not consent to publish")
 game.show_menu()
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
 game.save_festival_result()
 assert(game.online.pending.size() == 1)
 game.save_festival_result()
 assert(game.online.pending.size() == 1, "Double confirmation cannot duplicate a run")
 assert(game.online.nickname() == "Festival Hightech")
 assert(game.run_history.size() == 2 and game.player_totals.kills == 10 and game.player_totals.seconds == 75.0)
 game.show_menu()
 game.start_run("training")
 game.elapsed = 10.0
 game.record_run("menu")
 assert(game.run_history.size() == 2, "Training does not inflate festival totals")
 game.queue_free()
 DirAccess.remove_absolute(client.storage_path)
 client.queue_free()
 await process_frame
 print("FESTIVAL PASS: optional names, station totals, independent outbox, HTTP sync, isolation, replay")
 quit()
