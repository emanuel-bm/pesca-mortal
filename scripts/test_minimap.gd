extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 var remote_card := Vector2(100, 100)
 game.cards.spawn("furia", remote_card)
 game.cards.spawn("ima", game.player)
 game.minimap_timer = 0
 game.update_minimap(0)
 var card_map: Node = game.minimap_renderer
 assert(card_map.card_points.size() == 2, "Minimap must include all cards, including off-screen drops")
 assert(card_map.card_points[0].is_equal_approx(game.minimap_point(remote_card)))
 game.cards.update_pickups(0)
 game.minimap_timer = 0
 game.update_minimap(0)
 assert(card_map.card_points.size() == 1, "Collected cards must disappear from the minimap")
 game.cards.update_pickups(30)
 game.minimap_timer = 0
 game.update_minimap(0)
 assert(card_map.card_points.is_empty(), "Expired cards must disappear from the minimap")
 game.cards.spawn("perfurante", remote_card)
 game.start_run("training")
 game.update_minimap(0)
 assert(card_map.card_points.is_empty(), "Restart must clear card markers")
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
 game.minimap_timer = 0
 game.update_minimap(0)
 var map: Node = game.minimap_renderer
 assert(map.small_points.size() == 259 and map.large_points.size() == 259 and map.boss_points.size() == 2)
 assert(map.player_point.is_equal_approx(game.minimap_point(game.player)))
 assert(is_equal_approx(map.area.position.y, 46))
 assert(is_equal_approx(map.area.end.x, game.get_viewport_rect().size.x - 22))
 game.state = "paused"
 game._process(0)
 assert(is_equal_approx(game.fps_label.position.y, map.area.position.y))
 assert(is_equal_approx(game.fps_label.position.x + 150 + 22, map.area.position.x))
 assert(map.marker_batches.size() == 3)
 for species in 3:
  var points: PackedVector2Array = [map.small_points, map.large_points, map.boss_points][species]
  var batch: MultiMesh = map.marker_batches[species]
  assert(batch.visible_instance_count == points.size())
  if DisplayServer.get_name() != "headless":
   assert(batch.get_instance_transform_2d(0).origin.is_equal_approx(points[0]))
   assert(is_equal_approx(batch.get_instance_transform_2d(0).x.x, [1.8, 3.0, 6.0][species]))
 var small_batch: MultiMesh = map.marker_batches[0]
 var capacity := small_batch.instance_count
 map.update_batch(small_batch, PackedVector2Array(), 1.8)
 assert(small_batch.visible_instance_count == 0 and small_batch.instance_count == capacity)
 map.refresh(game)
 var point: Vector2 = map.player_point
 game.player += Vector2(10, 0)
 game.update_minimap(0.01)
 assert(map.player_point == point, "Reuse snapshot between refreshes")
 game.update_minimap(0.05)
 assert(map.player_point.is_equal_approx(game.minimap_point(game.player)))
 root.size = Vector2i(800, 600)
 game.update_minimap(0)
 assert(map.area == game.minimap_world_rect(), "Resize must refresh immediately")
 game.show_menu()
 game.update_minimap(0)
 assert(not map.visible)
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
 game.update_minimap(0)
 assert(map.visible)
 game.spawn_timer = INF
 game.attack_timer = INF
 game.update_game(0.01)
 for index in game.enemies.size():
  var cell := Vector2i((Vector2(game.enemies[index].pos) / game.COLLISION_CELL_SIZE).floor())
  assert(index in game.enemy_grid.get(cell, []), "Projectile grid must use post-movement positions")
 print("MINIMAP PASS: card markers/collection/expiry/restart, species markers, transform, refresh rate, resize, menu visibility, post-movement projectile grid")
 quit(0)
