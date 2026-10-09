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
 game.spawn_enemy(true)
 game.spawn_enemy(true)
 var attacker: Dictionary = game.enemies[0]
 var blocker: Dictionary = game.enemies[1]
 attacker.phase = "dash"
 attacker.phase_duration = 1.0
 attacker.timer = 1.0
 attacker.dash_start = Vector2(500, 500)
 attacker.dash_end = Vector2(600, 500)
 attacker.pos = attacker.dash_start
 blocker.phase = "exposed"
 blocker.timer = 100
 blocker.pos = Vector2(550, 500)
 game.rebuild_crowd_grid()
 game.update_game(0.5)
 assert(attacker.pos.is_equal_approx(Vector2(550, 500)), "Dash must pass through boss")
 # Endpoint is still attack movement even though the phase becomes exposed.
 blocker.pos = Vector2(600, 500)
 game.rebuild_crowd_grid()
 game.update_game(0.5)
 assert(attacker.pos.is_equal_approx(Vector2(600, 500)) and attacker.phase == "exposed")
 attacker.phase = "emerge_warning"
 attacker.timer = 0.01
 attacker.target = blocker.pos
 game.update_game(0.02)
 assert(attacker.pos.is_equal_approx(attacker.target), "Emergence must ignore crowd blocking")
 print("BOSS ATTACK PASS: dash crossing, final dash frame and emergence ignore crowd blocking")
 quit()
