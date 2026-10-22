extends SceneTree

const PILOT = preload("res://scripts/festival_autopilot.gd")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 assert(PILOT.preferred_upgrade(["luck", "rate", "speed"]) == "speed")
 assert(PILOT.preferred_upgrade(["crit_chance", "shots", "damage"]) == "damage")
 assert(PILOT.preferred_upgrade(["luck", "max_health", "crit_chance"]) == "max_health")
 assert(PILOT.preferred_upgrade(["luck", "crit_chance", "xp_bonus"]) == "crit_chance")
 assert(PILOT.preferred_upgrade(["persistence", "xp_bonus"]) == "persistence")
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.window_focus_lost = false
 var history_count: int = game.run_history.size()
 game.show_festival_demo()
 assert(game.demo_active and game.state == "playing" and game.test_run)
 var origin: Vector2 = game.player
 for i in 100:
  game.demo_pilot.tick(game, 0.05)
  if game.state == "playing": game.update_game(0.05)
  if game.state == "upgrade": game.demo_pilot.tick(game, 1.0)
 assert(game.player.distance_to(origin) > 50.0, "Demo must move without player input")
 game.enemies.clear()
 game.player = Vector2(1200, 900)
 game.gems.clear()
 game.gems.append({"pos": Vector2(1500, 900)})
 game.enemies.append({"pos": Vector2(1280, 900), "radius": 25.0})
 var away: Vector2 = game.demo_pilot.steer(game)
 assert(away.x < 0.5, "Dodge the enemy instead of following XP into it")
 game.enemies.clear()
 game.gems.clear()
 assert(PILOT.boundary_risk(Vector2(30, 30), game.ARENA) > PILOT.boundary_risk(Vector2(30, 900), game.ARENA))
 for corner in [Vector2(35, 35), Vector2(2365, 35), Vector2(35, 1765), Vector2(2365, 1765)]:
  game.player = corner
  game.gems.assign([{"pos": corner}])
  var escape: Vector2 = game.demo_pilot.steer(game)
  assert(escape.dot(corner.direction_to(game.ARENA / 2.0)) > 0.7, "Leave every corner even with XP as bait")
 game.gems.clear()
 game.player = game.ARENA / 2.0 + Vector2(790, 0)
 var total_angle := 0.0
 for i in 1600:
  var previous: Vector2 = game.player - game.ARENA / 2.0
  var steering: Vector2 = game.demo_pilot.steer(game)
  game.demo_pilot.direction = steering
  game.player += steering * game.effective_speed() * 0.12
  var current: Vector2 = game.player - game.ARENA / 2.0
  total_angle += previous.angle_to(current)
  assert(game.player.x > 250 and game.player.x < game.ARENA.x - 250)
  assert(game.player.y > 250 and game.player.y < game.ARENA.y - 250)
 assert(total_angle > TAU * 2, "Keep circling in the same direction over multiple laps")
 game.show_upgrades()
 var expected: String = PILOT.preferred_upgrade(game.choices)
 var before: int = game.upgrade_levels.get(expected, 0)
 game.demo_pilot.tick(game, 1.0)
 assert(game.upgrade_levels.get(expected, 0) == before + 1)
 assert(game.state == "playing")
 game.finish(false)
 assert(game.festival_result.is_empty())
 game.demo_pilot.tick(game, 2.1)
 assert(game.demo_active and game.state == "playing" and game.health == game.max_health)
 assert(game.elapsed == 0 and game.run_history.size() == history_count)
 var escape := InputEventKey.new()
 escape.keycode = KEY_ESCAPE
 escape.pressed = true
 game._input(escape)
 assert(not game.demo_active and game.state == "menu")
 game.start_run("endless")
 assert(not game.test_run, "Manual matches must remain eligible")
 game.run_active = false
 game.free()
 print("Festival AI demo: PASS")
 quit()
