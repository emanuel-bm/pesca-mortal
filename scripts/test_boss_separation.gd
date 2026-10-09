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
 game.enemies.clear()
 game.spawn_enemy(false)
 game.spawn_enemy(true)
 game.enemies[0].pos = Vector2(500, 500)
 game.enemies[1].pos = Vector2(501, 500)
 game.enemies[1].phase = "exposed"
 game.rebuild_crowd_grid()
 assert(game.crowd_separation(0, Vector2.RIGHT) == Vector2.ZERO)
 assert(game.crowd_separation(1, Vector2.LEFT) == Vector2.ZERO)
 assert(game.crowd_neighbors(0, Vector2(501, 500)).is_empty())
 assert(game.crowd_neighbors(1, Vector2(500, 500)).is_empty())
 assert(game.move_enemy_if_free(1, Vector2(500, 500)), "Fish must not block boss")
 game.spawn_enemy(true)
 game.enemies[2].phase = "exposed"
 game.enemies[2].pos = Vector2(502, 500)
 game.spawn_enemy(false)
 game.enemies[3].pos = Vector2(503, 500)
 game.rebuild_crowd_grid()
 assert(game.crowd_separation(0, Vector2.RIGHT) != Vector2.ZERO, "Fish still repel fish")
 assert(game.crowd_separation(1, Vector2.RIGHT) != Vector2.ZERO, "Bosses still repel bosses")
 assert(game.crowd_neighbors(1, Vector2(501, 500)).size() == 1)
 assert(not game.move_enemy_if_free(1, Vector2(501, 500)), "Boss must block boss")
 print("BOSS SEPARATION PASS: mixed groups ignored; same-group forces and boss blocking preserved")
 quit()
