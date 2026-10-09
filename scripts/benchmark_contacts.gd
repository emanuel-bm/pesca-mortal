extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_horde_test()
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
