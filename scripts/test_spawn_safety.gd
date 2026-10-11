extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.rng.seed = 42
 game.start_run("training")
 var bounds := Rect2(Vector2(30, 30), game.ARENA - Vector2(60, 60))
 for point in [game.ARENA / 2, Vector2(18, 18), Vector2(2382, 18), Vector2(18, 1782), Vector2(2382, 1782), Vector2(1200, 18), Vector2(18, 900)]:
  game.player = point
  for index in 200:
   game.spawn_enemy(false)
   var position: Vector2 = game.enemies.back().pos
   assert(game.player.distance_to(position) >= game.ENEMY_SPAWN_DISTANCE - 0.01, "Spawn must preserve the safe area")
   assert(bounds.grow(0.01).has_point(position), "Spawn must stay inside the arena")
  game.enemies.clear()
  for action in ["piranha", "pintado", "dourado", "pacu", "boss"]:
   game.training.act(action)
   for enemy in game.enemies:
    assert(game.player.distance_to(enemy.pos) >= game.ENEMY_SPAWN_DISTANCE - 0.01, "Manual spawns must preserve the safe area")
   game.enemies.clear()
 print("SPAWN SAFETY PASS: moving player, edges, corners, all training species and boss")
 quit()
