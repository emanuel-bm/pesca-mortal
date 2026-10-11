extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run()
 for index in 2: game.spawn_enemy(false)
 var back: Dictionary = game.enemies[0]
 var front: Dictionary = game.enemies[1]
 back.pos = Vector2(1000, 900)
 front.pos = Vector2(1008, 900)
 game.rebuild_enemy_grid()
 assert(is_equal_approx(game.separation_radius(back), 3.9))
 assert(is_equal_approx(game.separation_radius({"boss": false, "radius": 44}), 13.2))
 assert(not game.move_enemy_if_free(0, Vector2(1002, 900)))
 assert(back.pos == Vector2(1000, 900))
 assert(game.move_enemy_if_free(1, Vector2(1010, 900)))
 assert(game.move_enemy_if_free(0, Vector2(1002, 900)))
 assert(not game.move_enemy_if_free(0, Vector2(1020, 900)), "Cannot cross an occupied space")
 assert(back.pos == Vector2(1002, 900))
 back.pos = Vector2(1000, 900)
 front.pos = Vector2(1008, 900)
 game.player = Vector2(1100, 900)
 game.rebuild_enemy_grid()
 var moved_sideways := false
 var previous_velocity := Vector2(back.speed, 0)
 for frame in 240:
  var previous: Vector2 = back.pos
  game.rebuild_enemy_grid()
  game.pursue_player(0, 1.0 / 60)
  assert(back.pos.distance_to(previous) <= back.speed / 60.0 + 0.001)
  var velocity: Vector2 = back.crowd_velocity
  assert(velocity.distance_to(previous_velocity) <= back.speed * 5.0 / 60 + 0.01)
  previous_velocity = velocity
  if absf(back.pos.y - 900) > 1: moved_sideways = true
 assert(moved_sideways and back.pos.x > front.pos.x + 20, "Fish must flow around the stationary blocker")
 for index in 98:
  game.spawn_enemy(false)
  game.enemies[-1].pos = Vector2(1000, 900)
 for frame in 30:
  game.rebuild_enemy_grid()
  for index in game.enemies.size():
   var previous: Vector2 = game.enemies[index].pos
   game.pursue_player(index, 1.0 / 60)
   assert(game.enemies[index].pos.distance_to(previous) <= game.enemies[index].speed / 60.0 + 0.001)
 print("CROWD PASS: bounded speed/acceleration, sideways flow, no position jumps with 100 overlapping fish")
 quit(0)
