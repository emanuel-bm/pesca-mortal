extends SceneTree

func previous_sweep(game: Node, origin: Vector2, destination: Vector2) -> Array[int]:
 var ids := {}
 var hits: Array[int] = []
 var steps := maxi(1, ceili(origin.distance_to(destination) / 8.0))
 for step in range(steps + 1):
  for index: int in game.piercing_targets(origin.lerp(destination, float(step) / steps), ids):
   hits.append(index)
   ids[game.projectile_enemy_id(game.enemies[index])] = true
 return hits

func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.set_meta("offline_session", true)
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 game.enemies.clear()
 game.rng.seed = 417
 for index in 600:
  game.spawn_enemy(false)
  var enemy: Dictionary = game.enemies.back()
  enemy.pos = game.player + Vector2(game.rng.randf_range(-90, 90), game.rng.randf_range(-90, 90))
  enemy.hp = 1000000.0 + index
  enemy.speed = 0.0
 game.spawn_timer = INF
 game.attack_timer = INF
 game.invulnerability = INF
 game.cards.activate("perfurante")
 game.rebuild_projectile_grid()
 var origin: Vector2 = game.player - Vector2(100, 0)
 var destination: Vector2 = origin + Vector2(195, 0)
 var query_start := Time.get_ticks_usec()
 var expected := previous_sweep(game, origin, destination)
 var old_query := Time.get_ticks_usec() - query_start
 query_start = Time.get_ticks_usec()
 var actual: Array[int] = game.piercing_sweep_targets(origin, destination, {})
 var new_query := Time.get_ticks_usec() - query_start
 assert(actual == expected, "Dense sweep must preserve hit ordering")
 assert(new_query < old_query, "Sweep optimization must reduce processing time")
 print("PIERCING sweep previous/current: ", old_query / 1000.0, "/", new_query / 1000.0, " ms; hits: ", actual.size())
 var start := Time.get_ticks_usec()
 for repeat in 10:
  game.bullets.clear()
  for shot in 32:
   game.fire()
   game.bullets.back().pos = game.player - Vector2(100, 0)
   game.bullets.back().velocity = Vector2(650, 0)
  game.update_game(0.3)
 print("PIERCING STRESS 600 fish / 32 spears / 195px sweep average: ", (Time.get_ticks_usec() - start) / 10000.0, " ms")
 start = Time.get_ticks_usec()
 for repeat in 30:
  game.bullets.clear()
  for shot in 32:
   game.fire()
   game.bullets.back().pos = game.player
   game.bullets.back().velocity = Vector2(650, 0)
  game.update_game(1.0 / 60.0)
 print("PIERCING STRESS 600 fish / 32 spears / 60 FPS step average: ", (Time.get_ticks_usec() - start) / 30000.0, " ms")
 # Keep the same spears alive across frames, as during ordinary gameplay.
 game.bullets.clear()
 for shot in 32:
  game.fire()
  game.bullets.back().pos = game.player
  game.bullets.back().velocity = Vector2(650, 0)
 game.update_game(1.0 / 60.0)
 start = Time.get_ticks_usec()
 for repeat in 60: game.update_game(1.0 / 60.0)
 print("PIERCING STRESS 600 fish / 32 continuing spears average: ", (Time.get_ticks_usec() - start) / 60000.0, " ms")
 quit()
