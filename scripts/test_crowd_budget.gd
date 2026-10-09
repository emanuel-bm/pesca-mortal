extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_horde_test()
 for frame in 12:
  game.update_game(0.01)
  assert(game.crowd_recalculations <= 48)
 for enemy in game.enemies:
  if not enemy.boss: assert(enemy.has("desired_velocity"), "Every fish must get a turn")
 game.enemies.pop_back()
 game.enemies.pop_front()
 game.update_game(0.01)
 assert(game.crowd_recalculations <= 48)
 game.start_run()
 game.spawn_timer = 100
 game.attack_timer = 100
 game.spawn_enemy(false)
 game.update_game(0.01)
 assert(game.crowd_recalculations == 1)
 print("CROWD BUDGET PASS: bounded recalculations, fair rotation, removal safety, normal run reset")
 quit(0)
