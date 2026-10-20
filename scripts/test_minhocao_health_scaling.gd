extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for mode in ["endless", "bosses"]:
  game.start_run(mode)
  game.spawn_timer = 10000.0
  game.attack_timer = 10000.0
  game.next_boss_time = 10000.0
  game.spawn_enemy(true)
  var survivor: Dictionary = game.enemies.back()
  survivor.hp = 10000.0
  for index in 3:
   game.spawn_enemy(true)
   game.enemies.back().hp = 0.0
   game.update_game(0.0)
   assert(game.bosses_defeated == index + 1)
   assert(is_equal_approx(survivor.max_hp, 20000.0))
   assert(is_equal_approx(survivor.hp, 10000.0))
   game.spawn_enemy(true)
   var fresh: Dictionary = game.enemies.back()
   assert(is_equal_approx(fresh.max_hp, 20000.0))
   print("%s: kills=%s living_hp=%s living_max_hp=%s new_max_hp=%s" % [mode, game.bosses_defeated, survivor.hp, survivor.max_hp, fresh.max_hp])
   game.enemies.erase(fresh)
 print("MINHOCAO HEALTH SCALING PASS: boss deaths preserve base health and wounded HP in both modes")
 quit()
