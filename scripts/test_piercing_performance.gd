extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 game.enemies.clear()
 for index in 400:
  game.spawn_enemy(false)
  var enemy: Dictionary = game.enemies.back()
  enemy.pos = game.player
  enemy.hp = 100000.0 + index
  enemy.speed = 0.0
 game.rebuild_projectile_grid()
 var excluded: Array = []
 var expected: Array[int] = []
 var start := Time.get_ticks_usec()
 var target: int = game.projectile_target(game.player, excluded)
 while target >= 0:
  expected.append(target)
  excluded.append(game.enemies[target])
  target = game.projectile_target(game.player, excluded)
 var before := (Time.get_ticks_usec() - start) / 1000.0
 start = Time.get_ticks_usec()
 var hits: Array[int] = game.piercing_targets(game.player, {})
 var after := (Time.get_ticks_usec() - start) / 1000.0
 assert(hits == expected and hits.size() == 400, "Preserve dense hit order")
 var ids := {}
 for index in hits: ids[game.projectile_enemy_id(game.enemies[index])] = true
 assert(game.piercing_targets(game.player, ids).is_empty(), "Do not hit twice")
 # IDs survive removal and distinguish enemies even when all combat fields match.
 game.enemies.remove_at(0)
 game.spawn_enemy(false)
 game.enemies.back().pos = game.player
 game.rebuild_projectile_grid()
 assert(game.piercing_targets(game.player, ids) == [399], "A newly spawned fish must not inherit an old hit")
 game.spawn_timer = INF
 game.attack_timer = INF
 game.invulnerability = INF
 game.damage = 50.0
 game.cards.activate("perfurante")
 game.fire()
 game.bullets[0].pos = game.player
 game.bullets[0].velocity = Vector2.ZERO
 start = Time.get_ticks_usec()
 game.update_game(0.0)
 var frame_ms := (Time.get_ticks_usec() - start) / 1000.0
 assert(game.bullets[0].hit_enemies.size() == 400, "Exercise real damage processing")
 print("PIERCING 400 targets legacy/optimized query: ", before, "/", after, " ms; full update: ", frame_ms, " ms")
 assert(after < before / 10.0, "Dense query should be at least 10 times faster")
 # Differential probes across cell boundaries, with previous hits and dead fish.
 game.rng.seed = 417
 ids.clear()
 excluded.clear()
 for index in game.enemies.size():
  var enemy: Dictionary = game.enemies[index]
  enemy.pos = Vector2(game.rng.randf_range(0, 2400), game.rng.randf_range(0, 1800))
  if index % 7 == 0:
   ids[game.projectile_enemy_id(enemy)] = true
   excluded.append(enemy)
  if index % 11 == 0: enemy.hp = 0.0
 game.rebuild_projectile_grid()
 for probe in 300:
  var point: Vector2 = game.enemies[probe].pos + Vector2(4, -2)
  var previous_hits := excluded.duplicate()
  expected.clear()
  target = game.projectile_target(point, previous_hits)
  while target >= 0:
   expected.append(target)
   previous_hits.append(game.enemies[target])
   target = game.projectile_target(point, previous_hits)
  assert(game.piercing_targets(point, ids) == expected, "Scattered query must preserve silhouette hits and ordering")
 for probe in 100:
  var origin: Vector2 = game.enemies[probe].pos + Vector2(-160, -90)
  var destination := origin + Vector2(game.rng.randf_range(0, 320), game.rng.randf_range(0, 180))
  var steps := maxi(1, ceili(origin.distance_to(destination) / 8.0))
  var previous_ids := ids.duplicate()
  expected.clear()
  for step in range(steps + 1):
   for index: int in game.piercing_targets(origin.lerp(destination, float(step) / steps), previous_ids):
    expected.append(index)
    previous_ids[game.projectile_enemy_id(game.enemies[index])] = true
  assert(game.piercing_sweep_targets(origin, destination, ids) == expected, "Sweeps must preserve every hit and its sample order")
 print("PIERCING PERFORMANCE PASS: order, repeat exclusion, removal/spawn and real damage processing")
 quit(0)
