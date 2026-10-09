extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func seed_for_attack(emerge: bool) -> void:
 for candidate in 100:
  seed(candidate)
  if (randf() < 0.5) == emerge:
   seed(candidate)
   return
 assert(false, "No deterministic seed found")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 game.history_path = "user://minhocao_test_%d.json" % Time.get_ticks_usec()
 root.add_child(game)
 await process_frame
 game.start_run()
 for i in 5: game.choose_upgrade("speed")
 assert(game.speed <= game.MAX_PLAYER_SPEED)
 assert(game.speed <= (240.0 * pow(1.15, 5)) / 2)
 assert(is_equal_approx(game.MAX_PLAYER_SPEED / game.FASTEST_ENEMY_SPEED, 1.32))
 game.start_run()
 assert(is_equal_approx(game.speed, 184.8))
 game.elapsed = 300
 game.update_game(0.01)
 assert(game.boss_spawned and game.enemies.size() == 3, "Boss must spawn alongside two normal enemies")
 game.spawn_timer = 0
 game.update_game(0.01)
 assert(game.enemies.size() == 5, "Hordes must continue during boss fight")
 for enemy in game.enemies:
  if not enemy.boss:
   assert(is_equal_approx(enemy.speed, 85.8) or is_equal_approx(enemy.speed, 162.0))
 game.start_run()
 game.enemies.clear()
 game.spawn_enemy(true)
 var boss: Dictionary = game.enemies[0]
 assert(boss.hp == 32000)
 assert(not game.MINHOCAO.vulnerable(boss))
 game.fire()
 assert(game.bullets.is_empty(), "Do not aim at buried boss")
 seed(417)
 var samples: Array = []
 for index in 100:
  var sample := {"pos": Vector2.ZERO}
  game.MINHOCAO.initialize(sample)
  assert(sample.timer >= game.MINHOCAO.BURROW_TIME * 0.7 and sample.timer <= game.MINHOCAO.BURROW_TIME * 1.3)
  samples.append(sample.timer)
 assert(samples.min() < samples.max(), "Timers must vary independently")
 var target := Vector2(1000, 900)
 seed_for_attack(true)
 game.MINHOCAO.update(boss, boss.timer + 0.01, target, game.ARENA)
 assert(boss.phase == "tracking")
 game.MINHOCAO.update(boss, boss.timer + 0.01, target, game.ARENA)
 assert(boss.phase == "emerge_warning")
 var locked: Vector2 = boss.target
 game.MINHOCAO.update(boss, boss.timer * 0.5, target + Vector2(150, 0), game.ARENA)
 assert(boss.target == locked, "Warning must lock before emergence")
 var emerged: bool = game.MINHOCAO.update(boss, boss.timer + 0.01, target, game.ARENA)
 assert(emerged and boss.phase == "exposed")
 assert(boss.timer >= 2.1 and boss.timer <= 3.9, "Exposure must vary by up to 30 percent")
 assert(game.MINHOCAO.vulnerable(boss))
 game.fire()
 assert(game.bullets.size() == 1)
 game.MINHOCAO.update(boss, boss.timer + 0.01, target, game.ARENA)
 seed_for_attack(false)
 game.MINHOCAO.update(boss, boss.timer + 0.01, target, game.ARENA)
 assert(boss.phase == "dash_warning")
 game.MINHOCAO.update(boss, boss.timer + 0.01, target, game.ARENA)
 assert(boss.phase == "dash")
 var before: Vector2 = boss.pos
 game.MINHOCAO.update(boss, boss.timer * 0.5, target, game.ARENA)
 assert(boss.pos.distance_to(before) > 100)
 game.MINHOCAO.update(boss, boss.timer + 0.01, target, game.ARENA)
 assert(boss.phase == "exposed")
 seed(830)
 var emerge_count := 0
 var repeat_count := 0
 var last_phase := ""
 var angles: Array = []
 for index in 1000:
  var sample := {"pos": Vector2(800, 800)}
  game.MINHOCAO.initialize(sample)
  # Every first attack must emerge, regardless of the random seed.
  sample.timer = 0
  game.MINHOCAO.update(sample, 0, Vector2(1000, 900), game.ARENA)
  assert(sample.phase == "tracking", "First appearance must always choose emergence")
  for step in 3:
   game.MINHOCAO.update(sample, sample.timer + 0.01, Vector2(1000, 900), game.ARENA)
  assert(sample.phase == "burrow" and not sample.first_emergence_pending)
  sample.timer = 0
  game.MINHOCAO.update(sample, 0, Vector2(1000, 900), game.ARENA)
  if sample.phase == "tracking": emerge_count += 1
  else:
   var direction: Vector2 = sample.dash_end - sample.dash_start
   angles.append(direction.angle())
   assert(sample.dash_start.distance_to(Vector2(1000, 900)) > 249)
  if sample.phase == last_phase: repeat_count += 1
  last_phase = sample.phase
 assert(emerge_count > 400 and emerge_count < 600)
 assert(repeat_count > 300)
 assert(angles.min() < -2.5 and angles.max() > 2.5)
 game.start_run()
 game.boss_spawned = true
 game.spawn_enemy(true)
 boss = game.enemies[0]
 boss.phase = "emerge_warning"
 boss.timer = 0.01
 boss.target = game.player + Vector2(60, 0)
 game.attack_timer = 100
 game.update_game(0.02)
 assert(game.health == 41, "Emergence must damage inside warning area")
 print("MINHOCAO PASS: speed cap, HP, invulnerability, target lock, emergence damage, vulnerability, dash, cycle")
 if "--capture" in OS.get_cmdline_user_args():
  assert(game.player_texture != null and game.boss_texture != null)
  game.start_run()
  game.boss_spawned = true
  game.elapsed = 300
  game.spawn_enemy(true)
  boss = game.enemies[0]
  boss.phase = "exposed"
  boss.timer = game.MINHOCAO.EXPOSED_TIME
  boss.pos = game.player + Vector2(210, 0)
  game.fire()
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/minhocao-preview.png")
  game.facing_left = true
  for frame in 3: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/player-left-preview.png")
 game.start_boss_test()
 assert(game.level == 30 and game.health == game.MAX_HEALTH and game.xp == 0)
 assert(game.boss_spawned and game.enemies.size() == 1 and game.enemies[0].boss)
 var ranks := 0
 for id in game.UPGRADES:
  assert(game.upgrade_levels[id] > 0)
  ranks += game.upgrade_levels[id]
 assert(ranks == 29 and game.elapsed == game.RUN_SECONDS)
 game.update_game(0.01)
 assert(game.enemies.size() == 3, "Test mode must keep spawning hordes")
 game.start_run()
 assert(game.level == 1 and game.upgrade_levels.is_empty() and not game.boss_spawned)
 print("BOSS TEST PASS: level 30, 29 upgrades across all attributes, full health, immediate boss and hordes, normal run resets")
 var temporary_history: String = ProjectSettings.globalize_path(game.history_path)
 game.free()
 if FileAccess.file_exists(temporary_history): DirAccess.remove_absolute(temporary_history)
 quit(0)


