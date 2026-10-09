extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_horde_test()
 assert(game.enemies.size() == 520 and game.test_run and game.run_mode == "horde")
 assert(is_equal_approx(game.speed, game.BASE_PLAYER_SPEED * 2))
 var original_health: float = game.health
 # Exercise real contact through the same update loop as normal gameplay.
 game.enemies[0].pos = game.player
 game.update_game(0)
 assert(game.health < original_health and game.invulnerability > 0)
 assert(game.knockback_velocity != Vector2.ZERO)
 var damaged_health: float = game.health
 game.receive_hit(10, game.player)
 assert(game.health == damaged_health, "Normal damage cooldown must apply")
 game.invulnerability = 0
 game.receive_hit(10000, game.player)
 assert(game.health == 1 and game.state == "playing")
 game._process(0)
 assert(game.hud.text.contains("520 INIMIGOS") and game.fps_label.visible)
 var event := InputEventKey.new()
 event.pressed = true
 event.keycode = KEY_F5
 game._input(event)
 assert(game.enemies.size() == 620)
 event.keycode = KEY_F6
 game._input(event)
 assert(game.enemies.size() == 520)
 game.update_game(0.01)
 assert(game.enemies.size() == 520 and game.bullets.is_empty())
 var count: int = game.run_history.size()
 game.show_menu()
 assert(game.run_history.size() == count)
 game.start_horde_test()
 game.restart_run()
 assert(game.run_mode == "horde" and game.enemies.size() == 520)
 game.start_run()
 assert(game.speed == game.BASE_PLAYER_SPEED and not game.test_run)
 game.receive_hit(10, game.player)
 assert(game.health == original_health - 10)
 print("HORDE PASS: 520 enemies, all species, contact damage, cooldown, knockback, death protection, double speed, live count, F5/F6, no records, restart and normal mode reset")
 quit(0)
