extends SceneTree

const HISTORY = preload("res://scripts/run_history.gd")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var records := [
  {"mode": "endless", "seconds": 1200, "kills": 0, "debug_run": true},
  {"mode": "endless", "seconds": 1060, "kills": 13711, "debug_run": false},
  {"mode": "bosses", "reason": "won", "seconds": 1, "kills": 0, "debug_run": true},
  {"mode": "bosses", "reason": "won", "seconds": 120, "kills": 50, "debug_run": false}
 ]
 var ranked := HISTORY.ranked(records)
 if ranked.size() != 1 or ranked[0].seconds != 1060:
  push_error("Debug run blocks the legitimate 17:40 record")
  quit(1)
  return
 if HISTORY.boss_ranked(records).size() != 1 or HISTORY.chronological(records).size() != 4:
  quit(1)
  return
 var path := "user://test_record_eligibility.json"
 if HISTORY.save_records(records, path) != OK or HISTORY.ranked(HISTORY.load_records(path)).size() != 1:
  quit(1)
  return
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.online.storage_path = path + ".online"
 game.online.pending.clear()
 await process_frame
 game.set_process(false)
 game.history_path = path
 game.run_history.clear()
 game.start_run("endless")
 game.elapsed = 1200
 game.record_run("death")
 var saved := HISTORY.load_records(path)
 assert(saved.size() == 1 and saved[0].debug_run and not saved[0].record_valid)
 assert(HISTORY.ranked(saved).is_empty() and game.online.pending.is_empty())
 game.online.queue_record(records[1])
 assert(game.online.pending.is_empty(), "Debug build must not queue submissions")
 game.online.competitive_build = true
 game.online.queue_record(records[0])
 assert(game.online.pending.is_empty(), "Invalid run must not queue even in release")
 game.online.queue_record(HISTORY.ranked(records)[0])
 assert(game.online.pending.size() == 1, "Release record must enter outbox")
 game.online.queue_record({"mode": "endless", "seconds": 1100, "kills": 14000, "level": 65, "character": "Pescador", "reason": "death", "debug_run": false, "competitive_version": HISTORY.LEGACY_VERSION})
 assert(game.online.pending.values()[0].seconds == 1100, "New valid best must replace the previous record")
 game.run_active = false
 game.queue_free()
 await process_frame
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".online"))
 print("RECORD ELIGIBILITY PASS: persistence, debug exclusion, release outbox and new best")
 quit(0)
