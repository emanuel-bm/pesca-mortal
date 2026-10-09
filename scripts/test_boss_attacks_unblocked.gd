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
