extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run()
 game.elapsed = 300
 game.rng.seed = 417
 for i in 500:
  game.spawn_enemy(false)
  game.enemies.back().pos = Vector2(game.rng.randf_range(0, 2400), game.rng.randf_range(0, 1800))
 game.spawn_enemy(true)
 game.rebuild_enemy_grid()
 for i in 1000:
  var point := Vector2(game.rng.randf_range(-100, 2500), game.rng.randf_range(-100, 1900))
  if i < game.enemies.size(): point = game.enemies[i].pos + Vector2(4, -2)
  var expected := -1
  for index in game.enemies.size():
   var enemy: Dictionary = game.enemies[index]
   if enemy.hp <= 0 or (enemy.boss and not game.MINHOCAO.vulnerable(enemy)): continue
   if game.enemy_overlaps(enemy, point, 5):
    expected = index
    break
  assert(game.projectile_target(point) == expected, "Grid must preserve silhouette collisions and target order")
 var sounds: Node = game.sounds
 for id in sounds.volumes: sounds.volumes[id] = 1.0
 sounds.apply_volumes()
 if DisplayServer.get_name() != "headless":
  sounds.play_shot()
  assert(sounds.players.shot.playing)
 sounds.volumes.shot = 0.0
 sounds.apply_volumes()
 assert(not sounds.players.shot.playing)
 assert(not sounds.effect_enabled("shot") and sounds.effect_enabled("death"))
 var random_state: int = sounds.random.state
 sounds.play_shot()
 assert(not sounds.players.shot.playing and sounds.random.state == random_state)
 sounds.volumes.master = 0.0
 sounds.apply_volumes()
 var death_time: int = sounds.last_death_ms
 sounds.play_death()
 assert(sounds.last_death_ms == death_time)
 for id in sounds.players:
  assert(not sounds.effect_enabled(id) and not sounds.players[id].playing)
 print("PERFORMANCE PASS: grid matches brute force for 1000 probes; per-effect/master mute stops and skips playback")
 quit(0)
