extends SceneTree

class Probe extends "res://scripts/startup.gd":
 var played := ""
 var installed := false
 func _play(offline: bool) -> void:
  played = "offline" if offline else "online"
 func _install() -> void:
  installed = true

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var startup := Probe.new()
 root.add_child(startup)
 startup.request.cancel_request()
 startup.repository = "example/pesca"
 startup.asset_name = "pesca-mortal-windows-v{version}.exe"
 assert(startup.newer("v1.10.0", "1.9.9"))
 assert(not startup.newer("v1.0.0", "1.0.0"))
 assert(not startup.newer("v0.9.9", "1.0.0"))
 assert(not startup.newer("1.1.0-beta", "1.0.0"))
 startup._completed(HTTPRequest.RESULT_CANT_CONNECT, 0, [], PackedByteArray())
 assert(startup.played == "offline")
 startup.played = ""
 startup._completed(HTTPRequest.RESULT_SUCCESS, 403, [], PackedByteArray())
 assert(startup.played == "offline", "GitHub failures must allow offline play")
 startup.played = ""
 startup._completed(HTTPRequest.RESULT_SUCCESS, 200, [], "{bad json".to_utf8_buffer())
 assert(startup.played == "offline")
 startup.played = ""
 startup._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify({"tag_name": "v" + str(ProjectSettings.get_setting("application/config/version"))}).to_utf8_buffer())
 assert(startup.played == "online")
 startup.played = ""
 var data := {"tag_name": "v1.1.0", "assets": [{"name": "pesca-mortal-windows-v1.1.0.exe", "digest": "sha256:" + "a".repeat(64), "browser_download_url": "https://github.com/example/pesca/releases/download/v1.1.0/pesca-mortal-windows-v1.1.0.exe"}]}
 startup._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(data).to_utf8_buffer())
 assert(startup.played.is_empty(), "A newer release must offer a choice before loading the game")
 assert(not startup.asset.is_empty())
 var future: Dictionary = data.duplicate(true)
 future.tag_name = "v1.2.0"
 assert(startup.select_asset(future, startup.asset_name, startup.repository).is_empty(), "A release must not install an executable named for a different version")
 future.assets[0].name = "pesca-mortal-windows-v1.2.0.exe"
 assert(not startup.select_asset(future, startup.asset_name, startup.repository).is_empty(), "The filename must follow the remote release, not the installed version")
 var offline_button: Button = startup.actions.get_child(startup.actions.get_child_count() - 1)
 assert(offline_button.text == "Jogar offline")
 offline_button.pressed.emit()
 assert(startup.played == "offline")
 data.assets[0].browser_download_url = "https://example.com/payload.exe"
 assert(startup.select_asset(data, startup.asset_name, startup.repository).is_empty())
 data.assets[0].browser_download_url = "https://github.com/example/pesca/releases/download/v1.1.0/test.zip"
 data.assets[0].digest = ""
 assert(startup.select_asset(data, startup.asset_name, startup.repository).is_empty())
 startup.phase = "download"
 startup.download_path = "user://test-invalid-update.zip"
 var file := FileAccess.open(startup.download_path, FileAccess.WRITE)
 file.store_string("incomplete archive")
 file.close()
 startup._completed(HTTPRequest.RESULT_SUCCESS, 200, [], PackedByteArray())
 assert(not startup.installed and startup.phase == "error")
 DirAccess.remove_absolute(startup.download_path)
 startup.queue_free()
 var ranking: Node = load("res://scripts/online_ranking.gd").new()
 ranking.storage_path = "user://test-offline-outbox.json"
 ranking.disabled = true
 root.add_child(ranking)
 ranking.endpoint = "https://example.invalid/ranking"
 ranking.pending = {}
 ranking.queue_record({"mode": "endless", "seconds": 45.0, "kills": 10, "level": 3, "character": "default", "reason": "died"})
 assert(ranking.pending.has("endless") and not ranking.busy, "Offline scores must be saved without making a network request")
 var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(ranking.storage_path))
 assert(saved.pending.endless.kills == 10)
 DirAccess.remove_absolute(ranking.storage_path)
 ranking.queue_free()
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 assert(game.state == "menu", "First-time offline players must not be blocked by nickname registration")
 assert(game.online.disabled and not game.online.busy)
 set_meta("offline_session", false)
 game.online.disabled = false
 game.online.profile = {}
 game.online.endpoint = ""
 game.show_menu()
 assert(game.state == "menu", "An up-to-date game must remain playable before the ranking server is deployed")
 game.queue_free()
 await process_frame
 print("Startup checks passed: release choice, offline fallback, integrity and first-time offline menu.")
 quit()
