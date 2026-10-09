extends SceneTree

const ONLINE = preload("res://scripts/online_ranking.gd")
var client: Node

func _initialize() -> void:
 call_deferred("run")

func settle() -> void:
 var started := Time.get_ticks_msec()
 while client.busy:
  assert(Time.get_ticks_msec() - started < 5000, "HTTP mock did not answer")
  await process_frame
 await process_frame

func own_score() -> Dictionary:
 for record in client.rankings.endless:
  if record.nickname == client.nickname(): return record
 return {}

func run() -> void:
 client = ONLINE.new()
 client.storage_path = "user://test_online_%d.json" % Time.get_ticks_usec()
 root.add_child(client)
 client.endpoint = "http://127.0.0.1:18745/exec"
 client.set_nickname("Teste_" + Crypto.new().generate_random_bytes(4).hex_encode())
 await settle()
 assert(client.profile.has("player_id"), client.status)
 var player_id: String = client.profile.player_id
 var token: String = client.profile.token
 assert(client.fetched_at != "", "Registration must refresh ranking")
 client.set_nickname("Novo_" + Crypto.new().generate_random_bytes(4).hex_encode())
 await settle()
 assert(client.profile.player_id == player_id and client.profile.token == token)
 client.endpoint = ""
 client.network_disabled = true
 var record := {"mode": "endless", "seconds": 60.0, "kills": 10, "level": 1, "character": "Pescador", "reason": "death"}
 client.queue_record(record)
 client.queue_record({"mode": "endless", "seconds": 50.0, "kills": 10, "level": 1, "character": "Pescador", "reason": "death"})
 assert(client.pending.endless.seconds == 60.0, "A worse record must not replace the outbox")
 var reloaded := ONLINE.new()
 reloaded.storage_path = client.storage_path
 reloaded.load_state()
 assert(reloaded.profile.player_id == player_id and reloaded.pending.endless.seconds == 60.0, "Account and outbox survive restart")
 reloaded.free()
 client.endpoint = "http://127.0.0.1:18745/exec"
 client.synchronize()
 assert(not client.busy and client.pending.has("endless"), "Explicit offline sessions must preserve records without HTTP")
 client.network_disabled = false
 client.synchronize()
 # A newer personal best while the old request is in flight must survive its ACK.
 record.seconds = 70.0
 client.queue_record(record)
 await settle()
 assert(client.pending.is_empty(), client.status)
 assert(own_score().seconds == 70.0)
 record.kills = 1000000
 record.seconds = 80.0
 client.queue_record(record)
 await settle()
 assert(client.status.begins_with("Recorde recusado"))
 assert(client.pending.is_empty(), "A permanent refusal must not retry forever")
 client.synchronize()
 await settle()
 assert(own_score().seconds == 70.0, "Rejected score must not reach ranking")
 client.endpoint = "http://127.0.0.1:18746/exec"
 client.request.timeout = 1.0
 record.seconds = 90.0
 record.kills = 10
 client.queue_record(record)
 await settle()
 assert(client.pending.has("endless"), "Connection failure must preserve the outbox")
 # Exercise the actual game integration: only new personal bests queue submissions.
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.online.storage_path = "user://test_game_online_%d.json" % Time.get_ticks_usec()
 game.online.pending.clear()
 game.online.disabled = false
 game.online.profile = {"nickname": "Teste", "player_id": "test", "token": token}
 game.online.endpoint = ""
 game.history_path = "user://test_online_history_%d.json" % Time.get_ticks_usec()
 game.run_history.clear()
 for seconds in [60.0, 50.0, 70.0]:
  game.start_run("endless")
  game.elapsed = seconds
  game.kills = 10
  game.record_run("death")
  assert(game.online.pending.endless.seconds == (70.0 if seconds == 70.0 else 60.0))
 game.show_nickname()
 await process_frame
 assert(game.nickname_edit != null)
 game.show_menu()
 await process_frame
 assert(game.state == "menu")
 assert(not game.records_personal.endless and not game.records_personal.bosses)
 game.select_records_tab("endless", true)
 assert(game.records_personal.endless and not game.records_personal.bosses)
 game.online.disabled = true
 DirAccess.remove_absolute(ProjectSettings.globalize_path(game.online.storage_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(game.history_path))
 game.run_active = false
 game.queue_free()
 DirAccess.remove_absolute(ProjectSettings.globalize_path(client.storage_path))
 print("ONLINE PASS: HTTP redirects, register/rename, local persistence, latest outbox, in-flight replacement, refusal, offline retry, personal-best-only game integration")
 quit(0)
