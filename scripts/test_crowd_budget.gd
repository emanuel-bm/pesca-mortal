extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 game.elapsed = 420.0
 game.speed = game.BASE_PLAYER_SPEED * 2.0
 game.attack_timer = INF
 for index in 518:
  game.spawn_enemy(false)
  var fish: Dictionary = game.enemies.back()
  fish.tank = index % 2 == 1
  fish.radius = 44.0 if fish.tank else 13.0
  fish.speed = 85.8 if fish.tank else game.FASTEST_ENEMY_SPEED
  fish.contact = 15.0 if fish.tank else 10.0
  fish.hp = (100.0 if fish.tank else 30.0) * (1 + game.elapsed / 300.0)
  fish.max_hp = fish.hp
 for index in 2: game.spawn_enemy(true)
 game.boss_spawned = true
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
