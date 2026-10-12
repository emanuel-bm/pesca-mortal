extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for mode in ["endless"]:
  game.start_run(mode)
  for wave in range(1, 9):
   game.enemies.clear()
   game.elapsed = game.next_boss_time
   game.spawn_endless_bosses()
   assert(game.endless_wave == wave)
   assert(game.enemies.size() == (wave if wave <= 5 else wave - 5))
   var expected_arrival: String
   if wave >= 6:
    expected_arrival = "O PAI DO MATO DESPERTOU!" if wave == 6 else "OS PAIS DO MATO DESPERTARAM!"
   else:
    expected_arrival = "O MINHOCÃO DESPERTOU!" if wave == 1 else "OS MINHOCÕES DESPERTARAM!"
   assert(game.boss_arrival_label.text == expected_arrival)
   for boss in game.enemies:
    assert(boss.get("species", "") == ("pai_do_mato" if wave >= 6 else ""))
    assert(boss.max_hp == (640000 if wave >= 6 else 32000))
 game.start_run("training")
 game.training.act("pai_do_mato")
 var boss: Dictionary = game.enemies[0]
 assert(game.RUN_HISTORY.killer_details(boss).killer_id == "pai_do_mato")
 assert(boss.max_hp == 640000 and game.enemy_vulnerable(boss))
 assert(not game.pai_do_mato_art.is_empty() and not game.log_art.is_empty())
 var facing_boss := boss.duplicate(true)
 facing_boss.pos = Vector2(1000, 900)
 game.PAI_DO_MATO.update(facing_boss, 0.1, Vector2(900, 900), game.ARENA)
 assert(facing_boss.facing_left)
 game.PAI_DO_MATO.update(facing_boss, 0.1, Vector2(1100, 900), game.ARENA)
 assert(not facing_boss.facing_left)
 assert(boss.speed == 120, "Pai do Mato base movement speed is 120")
 for phase in ["approach", "hand_warning", "hand_impact", "recovery", "log_impact", "log_warning"]:
  var moving_boss := boss.duplicate(true)
  moving_boss.pos = Vector2(800, 600)
  moving_boss.phase = phase
  moving_boss.timer = 1.0
  game.PAI_DO_MATO.update(moving_boss, 0.1, Vector2(1200, 600), game.ARENA)
  assert(moving_boss.pos.is_equal_approx(Vector2(806 if phase == "log_warning" else 812, 600)), "Half speed during log preparation, full speed otherwise: " + phase)
 var view := Rect2(Vector2(600, 400), Vector2(1200, 1000))
 var slow_boss := boss.duplicate(true)
 slow_boss.pos = Vector2(800, 900)
 slow_boss.speed = 140.0
 slow_boss.timer = 0.0
 game.PAI_DO_MATO.update(slow_boss, 0.0, Vector2(1400, 900), game.ARENA, view)
 assert(slow_boss.phase == "log_warning" and slow_boss.timer == 0.6)
 var log_target: Vector2 = slow_boss.target
 assert(game.PAI_DO_MATO.update(slow_boss, 0.5, Vector2(1400, 900), game.ARENA, view) == "")
 assert(slow_boss.pos.is_equal_approx(Vector2(835, 900)) and slow_boss.speed == 140.0, "Log preparation halves movement without changing base speed")
 assert(slow_boss.target == log_target, "Log aim remains locked while moving")
 assert(game.PAI_DO_MATO.update(slow_boss, 0.1, Vector2(1400, 900), game.ARENA, view) == "log", "Log launches after 0.6 seconds")
 var impact_position: Vector2 = slow_boss.pos
 game.PAI_DO_MATO.update(slow_boss, 0.1, Vector2(1400, 900), game.ARENA, view)
 assert(slow_boss.pos.is_equal_approx(impact_position + Vector2(14, 0)), "Full speed resumes after preparation")
 boss.pos = Vector2(1000, 900)
 assert(game.PAI_DO_MATO.choose_attack(boss, boss.pos + Vector2(160, 0), view) == "hand")
 assert(game.PAI_DO_MATO.choose_attack(boss, boss.pos + Vector2(161, 0), view) == "log")
 var range_player := Vector2(1200, 900)
 var range_view := Rect2(600, 400, 1200, 1000)
 for offset in [Vector2(899, 0), Vector2(-899, 0), Vector2(0, 749), Vector2(0, -749)]:
  assert(game.PAI_DO_MATO.choose_attack({"pos": range_player + offset}, range_player, range_view) == "log", "Log activation range extends 50% beyond the camera")
 for offset in [Vector2(901, 0), Vector2(-901, 0), Vector2(0, 751), Vector2(0, -751)]:
  assert(game.PAI_DO_MATO.choose_attack({"pos": range_player + offset}, range_player, range_view) == "", "No launch outside the expanded range")
 var waiting := boss.duplicate(true)
 waiting.timer = 0
 game.PAI_DO_MATO.update(waiting, 0, Vector2(1800, 900), game.ARENA, Rect2(1500, 400, 500, 1000))
 assert(waiting.phase == "approach", "Offscreen boss cannot start a ranged attack")
 assert(game.PAI_DO_MATO.log_shapes(game.log_art).size() == 1 and game.PAI_DO_MATO.log_shapes(game.log_art)[0].size() == 4)
 game.player = Vector2(1200, 900)
 boss.pos = game.player - Vector2(100, 0)
 boss.timer = 0
 assert(game.PAI_DO_MATO.update(boss, 0, game.player, game.ARENA) == "")
 assert(boss.phase == "hand_warning")
 assert(boss.timer == 0.5, "Hand preparation lasts half a second")
 var locked: Vector2 = boss.target
 var initial_position: Vector2 = boss.pos
 var locked_angle: float = boss.hand_angle
 var locked_offset: Vector2 = boss.hand_offset
 assert(game.PAI_DO_MATO.update(boss, 0.2, game.player + Vector2(200, 0), game.ARENA) == "")
 assert(boss.pos != initial_position and boss.target != locked, "Hand target follows the moving boss")
 assert(Vector2(boss.target - boss.pos).is_equal_approx(locked_offset))
 assert(boss.hand_angle == locked_angle)
 game.PAI_DO_MATO.update(boss, 0.1, game.player + Vector2(0, 200), game.ARENA)
 assert(boss.hand_angle == locked_angle and Vector2(boss.target - boss.pos).is_equal_approx(locked_offset), "Chase turns without rotating the hand")
 locked = boss.target
 assert(game.PAI_DO_MATO.hand_hits(boss, locked))
 assert(not game.PAI_DO_MATO.hand_hits(boss, locked + Vector2(200, 200)))
 boss.hand_angle = 0
 assert(not game.PAI_DO_MATO.hand_hits(boss, locked + Vector2(11, -62.5), 0), "Space between fingers must not hit")
 assert(game.PAI_DO_MATO.hand_hits(boss, locked + Vector2(0, -62.5), 0), "Middle finger must hit")
 game.health = 500
 game.player = locked
 var hp: float = game.health
 assert(game.PAI_DO_MATO.update(boss, 0.199, game.player, game.ARENA) == "", "No hand impact before 0.5 seconds")
 var attack: String = game.PAI_DO_MATO.update(boss, 0.0011, game.player, game.ARENA)
 assert(attack == "hand")
 game.player = boss.target
 game.execute_forest_attack(boss, attack)
 assert(game.health == hp - 280)
 assert(game.PAI_DO_MATO.update(boss, 0, game.player, game.ARENA) == "", "Impact only fires once")
 boss.max_hp = 800000
 boss.pos = Vector2(800, 600)
 boss.target = Vector2(1200, 900)
 game.execute_forest_attack(boss, "log")
 var log: Dictionary = game.enemies.back()
 assert(log.hp == 400000 and log.contact == 0 and not log.landed)
 hp = game.health
 game.update_log(log, 0.65)
 assert(log.landed and game.health == hp)
 game.rebuild_projectile_grid()
 assert(game.projectile_target(log.pos) == game.enemies.find(log), "Spears must target the landed obstacle")
 assert(not game.PAI_DO_MATO.log_hits(log, game.player, 14), "Landing must displace safely")
 var direction := Vector2.RIGHT.rotated(log.angle)
 var start: Vector2 = log.pos - direction * 300
 var stopped: Vector2 = game.move_player_around_logs(start, direction * 600)
 assert((stopped - start).dot(direction) < 300, "Cannot tunnel through a rotated log")
 var side := Vector2(0, 200).rotated(log.angle)
 var sliding: Vector2 = game.move_player_around_logs(stopped, side)
 assert((sliding - stopped).dot(side) > 0, "Movement must remain possible along the obstacle")
 game.elapsed = 120
 game.update_minute_buffs()
 game.buff_endless_enemies()
 assert(log.hp == 400000 and log.max_hp == 400000, "Log health remains fixed at throw time")
 boss.hp = 0
 game.spawn_timer = 10000
 game.attack_timer = 10000
 game.update_game(0)
 assert(game.enemies.has(log), "Log must outlive its parent boss")
 var reward_count: int = game.gems.size()
 game.hit_with_spear(log, 400000)
 game.spawn_timer = 10000
 game.attack_timer = 10000
 game.enemies.erase(boss)
 var kills: int = game.kills
 game.update_game(0)
 assert(not game.enemies.has(log) and game.kills == kills and game.gems.size() == reward_count, "Logs break without kill rewards")
 game.start_run("training")
 game.training.act("pai_do_mato")
 boss = game.enemies[0]
 game.execute_forest_attack(boss, "log")
 game.state = "paused"
 var flight: float = game.enemies.back().flight
 game._process(1)
 assert(game.enemies.back().flight == flight)
 game.start_run("training")
 assert(game.enemies.is_empty())
 var origin := Vector2(1000, 900)
 for angle in [0.0, PI / 2, -PI / 4, PI]:
  var aimed_player := origin + Vector2.RIGHT.rotated(angle) * 300
  var endpoint: Vector2 = game.PAI_DO_MATO.throw_endpoint(origin, aimed_player, game.ARENA)
  assert(endpoint.is_equal_approx(origin + (aimed_player - origin) * 1.5))
  var rotated_log := {"pos": origin, "angle": angle, "shapes": game.PAI_DO_MATO.log_shapes(game.log_art)}
  assert(game.PAI_DO_MATO.log_hits(rotated_log, origin))
  assert(not game.PAI_DO_MATO.log_hits(rotated_log, origin + Vector2(0, 45).rotated(angle)))
 var edge_target: Vector2 = game.PAI_DO_MATO.throw_endpoint(origin, Vector2(2390, 1700), game.ARENA)
 assert(absf((edge_target - origin).normalized().cross((Vector2(2390, 1700) - origin).normalized())) < 0.00001, "Arena clipping preserves a straight trajectory")
 game.training.act("pai_do_mato")
 boss = game.enemies[0]
 boss.pos = Vector2(800, 900)
 boss.target = Vector2(1400, 900)
 game.health = 500
 game.player = Vector2(1100, 900)
 game.execute_forest_attack(boss, "log")
 log = game.enemies.back()
 hp = game.health
 game.update_log(log, 0.65)
 assert(game.health == hp - 200, "Swept flight must hit even across a whole frame")
 game.invulnerability = 0
 game.player = log.pos
 hp = game.health
 game.update_log(log, 1)
 assert(game.health == hp, "Landed log must never deal damage")
 game.start_run("training")
 print("PAI DO MATO PASS: waves, HP, hand silhouette, locked warning, damage, persistent logs, collision, destruction, pause and reset")
 if "--capture" in OS.get_cmdline_user_args():
  game.training.act("pai_do_mato")
  boss = game.enemies[0]
  boss.pos = game.player + Vector2(-230, 0)
  boss.phase = "hand_warning"
  boss.target = game.player + Vector2(150, -50)
  boss.hand_angle = 0
  game.execute_forest_attack(boss, "log")
  log = game.enemies.back()
  log.pos = game.player + Vector2(40, 160)
  log.landed = true
  game.water_ripples.append({"pos": log.pos, "age": 0.16, "life": 1.0, "kind": "log_impact", "angle": log.angle})
  game.water_ripples.append({"pos": boss.target, "age": 0.12, "life": 1.0, "kind": "hand_impact", "angle": boss.hand_angle - PI / 2})
  for age in [0.08, 0.28, 0.48]:
   game.water_ripples.append({"pos": game.player - Vector2(30 + age * 80, 0), "age": age, "direction": Vector2.RIGHT})
  for index in 8:
   var boat_particle: Dictionary = game.make_boat_particle(index, Vector2.RIGHT)
   boat_particle.age = index * 0.025
   game.boat_particles.append(boat_particle)
  game.boss_arrival_timer = 0
  game.boss_arrival_label.hide()
  game.fps_label.hide()
  game.queue_redraw()
  for frame in 4: await process_frame
  game.overlay.hide()
  game.state = "playing"
  game.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/pai-do-mato-preview.png")
 game.free()
 quit()
