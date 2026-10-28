extends SceneTree
## Invoked by the MongoDB integration suite; only accepts an ephemeral local endpoint.
const ONLINE = preload("res://scripts/online_ranking.gd")
var client: Node

func _initialize() -> void:
 call_deferred("run")

func settle() -> void:
 var started := Time.get_ticks_msec()
 while client.busy:
  assert(Time.get_ticks_msec() - started < 10000, "Local MongoDB API did not answer")
  await process_frame
 await process_frame

func run() -> void:
 var endpoint := OS.get_environment("MONGO_TEST_ENDPOINT")
 assert(endpoint.begins_with("http://127.0.0.1:"), "Test must use the disposable local API")
 client = ONLINE.new()
 client.competitive_version = "0.5"
 client.competitive_build = true
 client.storage_path = "user://test_mongodb_%d.json" % Time.get_ticks_usec()
 root.add_child(client)
 client.endpoint = endpoint
 client.set_nickname("Mongo_" + Crypto.new().generate_random_bytes(4).hex_encode())
 await settle()
 assert(client.profile.has("player_id"), client.status)
 var identity: String = client.profile.player_id
 client.network_disabled = true
 client.queue_record({"mode": "endless", "seconds": 60.0, "kills": 10, "level": 1, "character": "Pescador", "reason": "death"})
 assert(client.pending.size() == 1)
 var restored := ONLINE.new()
 restored.storage_path = client.storage_path
 restored.load_state()
 assert(restored.profile.player_id == identity and restored.pending.size() == 1)
 restored.free()
 client.network_disabled = false
 client.synchronize()
 await settle()
 assert(client.pending.is_empty(), client.status)
 assert(client.rankings.endless.size() == 1 and client.rankings.endless[0].seconds == 60.0, client.status)
 var path: String = client.storage_path
 client.queue_free()
 await process_frame
 DirAccess.remove_absolute(path)
 print("MONGODB GODOT PASS: account, persisted offline queue, direct HTTP and ranking")
 quit()
