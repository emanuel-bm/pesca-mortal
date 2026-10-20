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
  for species in ["piranha", "pintado", "pacu", "dourado", "minhocao", "pai_do_mato"]:
   game.start_run(mode)
   game.spawn_timer = 10000.0
   game.attack_timer = 10000.0
   game.next_boss_time = 10000.0
   var boss: bool = species in ["minhocao", "pai_do_mato"]
   game.elapsed = 599.99
   if mode == "endless": game.next_boss_time = 600.0
   game.spawn_enemy(boss, species)
   var survivor: Dictionary = game.enemies.back()
   survivor.hp *= 0.5
   var snapshot: Dictionary = survivor.duplicate(true)
   game.elapsed = 600.0
   game.update_game(0.0)
   print("%s %s: HP %s -> %s, max HP %s -> %s" % [mode, species, snapshot.hp, survivor.hp, snapshot.max_hp, survivor.max_hp])
   for stat in ["hp", "max_hp", "speed", "contact", "stat_multiplier", "speed_multiplier", "damage_multiplier"]:
    assert(is_equal_approx(survivor[stat], snapshot[stat]), "Living enemy changed: " + species + " " + stat)
   game.spawn_enemy(boss, species)
   var fresh: Dictionary = game.enemies.back()
   assert(fresh.max_hp > survivor.max_hp)
   assert(fresh.speed > survivor.speed)
   assert(fresh.contact > survivor.contact)
   assert(is_equal_approx(fresh.hp, fresh.max_hp))
 print("SPAWN GROWTH SNAPSHOT PASS: living fish and bosses retain HP and attributes in both modes; new enemies receive growth")
 game.queue_free()
 await process_frame
 quit()
