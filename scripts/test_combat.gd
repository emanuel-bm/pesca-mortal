extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_run()
 game.update_game(0.01)
 assert(game.enemies.size() == 2, "Initial wave must spawn two enemies")
 assert(game.MAX_HEALTH == 50.0, "Base health must remain 50")
 assert(game.health == 50.0 and game.max_health == 50.0, "Health must start at 50")
 for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.ZERO]:
  game.start_run()
  game.spawn_timer = 100
  game.attack_timer = 100
  game.spawn_enemy(false)
  var enemy: Dictionary = game.enemies[0]
  enemy.pos = game.player + direction * 10
  enemy.speed = 0
  var before: Vector2 = game.player
  game.update_game(0.01)
  assert(game.health == 40.0, "Contact must deal 10 damage")
  var push: Vector2 = game.knockback_velocity
  assert(push.length() > 0, "Hit must cause knockback, including exact overlap")
  if direction != Vector2.ZERO:
   assert(push.dot(direction) < 0, "Knockback must point away from attacker")
  game.update_game(0.02)
  assert(game.health == 40.0, "Invulnerability must prevent repeated contact damage")
  assert((game.player - before).dot(push) > 0, "Knockback must move player")
  for step in 30: game.update_game(0.01)
  assert(game.knockback_velocity.is_zero_approx(), "Knockback must decay")
 game.start_run()
 assert(game.knockback_velocity == Vector2.ZERO, "Restart must reset knockback")
 game.show_pause()
 game.show_fps = true
 game._process(0)
 assert(game.fps_label.visible and "FPS" in game.fps_label.text, "FPS toggle must show counter")
 game.show_fps = false
 game._process(0)
 assert(not game.fps_label.visible, "FPS toggle must hide counter")
 assert(Vector2i(2560, 1440) in game.RESOLUTIONS and Vector2i(3840, 2160) in game.RESOLUTIONS)
 game.start_run()
 game.spawn_timer = 100
 game.attack_timer = 100
 game.spawn_enemy(false)
 var tank: Dictionary = game.enemies[0]
 tank.tank = true
 tank.radius = 22.0
 tank.pos = game.player + Vector2(200, 0)
 tank.speed = 0
 tank.hp = 1.0
 assert(game.enemy_xp_reward({"radius": 13.0}) == 1)
 assert(game.enemy_xp_reward(tank) == 5)
 assert(game.enemy_xp_reward({"radius": 26.0}) > 3)
 game.bullets.append({"pos": tank.pos, "velocity": Vector2.ZERO, "life": 1.0})
 game.update_game(0.01)
 assert(game.gems.size() == 1 and game.gems[0].xp == 5)
 game.player = game.gems[0].pos
 game.update_game(0.01)
 assert(game.level == 1 and game.xp == 5 and game.gems.is_empty(), "Pintado pickup must grant five XP")
 assert(game.xp_needed() == 7)
 game.health = 10
 game.xp = game.xp_needed()
 game.update_game(0.0)
 assert(game.level == 2 and game.health == game.MAX_HEALTH and game.state == "upgrade", "Level up must fully heal")
 assert(game.level_healing == 40, "Level up must restore the missing 40 health")
 game.add_xp_number(game.player, 5)
 assert(game.damage_numbers.back().text == "+5 XP" and game.damage_numbers.back().color == game.XP_COLOR and game.damage_numbers.back().font_size == 12)
 assert(game.sounds.players.has("level"))
 var previous_cost := 0
 for rank in range(1, 51):
  game.level = rank
  var cost: int = game.xp_needed()
  assert(cost > previous_cost)
  assert(cost >= ceili((5 + (rank - 1) * 3) * 1.4))
  previous_cost = cost
 print("COMBAT PASS: waves, HP, damage, knockback, FPS, XP scaling and collection")
 quit(0)
