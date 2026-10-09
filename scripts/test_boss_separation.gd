extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_horde_test()
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
