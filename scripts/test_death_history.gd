extends SceneTree

const HISTORY = preload("res://scripts/run_history.gd")
const PATH := "user://test_death_history.json"

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 await process_frame
 game.set_process(false)
 game.history_path = PATH
 game.run_history.clear()
 for species in ["piranha", "pintado", "pacu", "dourado", "minhocao"]:
  game.start_run()
  game.elapsed = 10
  game.spawn_enemy(species == "minhocao", species if species != "minhocao" else "")
  var enemy: Dictionary = game.enemies[0]
  game.health = 1
  game.receive_hit(80, enemy.pos, enemy, "Investida")
  enemy.display_name = "Alterado"
  var saved: Array = HISTORY.load_records(PATH)
  var matches := saved.filter(func(record: Dictionary) -> bool: return record.killer_id == species)
  assert(matches.size() == 1)
  assert(matches[0].fatal_attack == "Investida")
  if species == "minhocao": assert(matches[0].killer_name == "Minhocão")
  game.finish(false)
  assert(game.run_history.size() == saved.size(), "Repeated finish must not duplicate deaths")
 var records: Array = HISTORY.load_records(PATH)
 assert(HISTORY.deaths_by_enemy(records) == {"piranha": 1, "pintado": 1, "pacu": 1, "dourado": 1, "minhocao": 1})
 records.append({"seconds": 10, "kills": 0, "reason": "death"})
 records.append({"seconds": 10, "kills": 0, "reason": "quit", "killer_id": "piranha"})
 records.append({"seconds": 10, "kills": 0, "reason": "won", "killer_id": "minhocao"})
 assert(HISTORY.deaths_by_enemy(records).unknown == 1)
 assert(HISTORY.deaths_by_enemy(records).piranha == 1)
 game.start_run()
 game.elapsed = 10
 game.record_run("quit")
 var quit_records: Array = game.run_history.filter(func(record: Dictionary): return record.reason == "quit")
 assert(quit_records.size() == 1 and quit_records[0].killer_id == "")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
 game.run_active = false
 game.queue_free()
 await process_frame
 print("DEATH HISTORY PASS: all enemies, fatal attack, persistence, legacy records and duplicate protection")
 quit(0)
