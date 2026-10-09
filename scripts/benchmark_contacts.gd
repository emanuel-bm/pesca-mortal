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
 for i in game.enemies.size():
  game.enemies[i].pos = game.player + Vector2((i % 26 - 13) * 6, (i / 26 - 10) * 6)
 var checksum := 0
 var start := Time.get_ticks_usec()
 for iteration in 120:
  for enemy in game.enemies:
   if game.enemy_overlaps(enemy, game.player, 14): checksum += 1
 print("CONTACTS dense 520 mean ms: ", (Time.get_ticks_usec() - start) / 120000.0, " hits: ", checksum)
 start = Time.get_ticks_usec()
 for iteration in 120: game.update_game(0)
 print("HORDE update_game mean ms: ", (Time.get_ticks_usec() - start) / 120000.0)
 quit()
