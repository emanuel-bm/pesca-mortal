extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.rng.seed = 42
 game.start_run("endless")
 assert(not game.pacu_unlocked())
 game.endless_wave = 1
 assert(not game.pacu_unlocked())
 game.endless_wave = 2
 assert(game.pacu_unlocked())
 for index in 100:
  game.spawn_enemy(false)
 assert(game.enemies.any(func(enemy: Dictionary): return enemy.get("species", "") == "dourado"))
 game.run_mode = "bosses"
 assert(not game.pacu_unlocked())
 game.bosses_defeated = 1
 assert(game.pacu_unlocked())
 game.start_run("training")
 game.training.act("dourado")
 assert(game.enemies.size() == 10)
 var quadrants := {}
 for enemy in game.enemies:
  assert(enemy.get("species", "") == "dourado")
  var relative: Vector2 = enemy.pos - game.player
  assert(is_equal_approx(relative.length(), 300.0))
  quadrants[Vector2i(signi(int(relative.x)), signi(int(relative.y)))] = true
 assert(quadrants.size() == 4, "Training horde must surround the canoe")
 var fish: Dictionary = game.enemies.back()
 assert(fish.species == "dourado" and not fish.boss and not fish.tank)
 assert(is_equal_approx(fish.hp, 200.0) and is_equal_approx(fish.max_hp, 200.0))
 assert(not game.dourado_art.is_empty() and not game.dourado_art.polygons.is_empty())
 assert(game.enemy_overlaps(fish, fish.pos, 0))
 assert(game.enemy_xp_reward(fish) == 8)
 for multiplier in [1.0, 2.0, 4.0]:
  game.DOURADO.initialize(fish)
  fish.stat_multiplier = multiplier
  var trigger_range: float = game.DOURADO.dash_range(fish) * 0.7
  fish.pos = game.player - Vector2(trigger_range + 1.0, 0)
  game.DOURADO.update(fish, 0, game.player, game.ARENA)
  assert(fish.phase == "approach", "Wait outside 70 percent of current dash range")
  fish.pos = game.player - Vector2(trigger_range - 0.01, 0)
  game.DOURADO.update(fish, 0, game.player, game.ARENA)
  assert(fish.phase == "warning", "Buffed dash must also increase preparation range")
 game.DOURADO.initialize(fish)
 fish.stat_multiplier = 1.0
 fish.pos = game.player - Vector2(100, 0)
 game.DOURADO.update(fish, 0, game.player, game.ARENA)
 assert(fish.phase == "warning")
 var start: Vector2 = fish.pos
 game.DOURADO.update(fish, 0.55, game.player + Vector2(0, 200), game.ARENA)
 assert(fish.phase == "warning" and fish.pos == start and fish.dash_direction == Vector2.RIGHT)
 game.DOURADO.update(fish, 0.55, game.player, game.ARENA)
 assert(fish.phase == "dash")
 game.DOURADO.update(fish, game.DOURADO.DASH_TIME, game.player + Vector2(0, 200), game.ARENA)
 assert(fish.phase == "recovery" and is_equal_approx(fish.pos.y, start.y))
 assert(fish.cooldown >= 1.0 and fish.cooldown <= 3.0)
 fish.cooldown = 3.0
 assert(is_equal_approx(fish.pos.x - start.x, game.DOURADO.DASH_SPEED * game.DOURADO.DASH_TIME))
 assert(is_equal_approx(fish.pos.x - start.x, 159.705), "Dash distance is reduced by 35 percent without changing speed")
 start = fish.pos
 game.DOURADO.update(fish, 0.5, game.player, game.ARENA)
 assert(fish.pos == start and fish.phase == "recovery")
 game.DOURADO.update(fish, 0.25, game.player, game.ARENA)
 assert(fish.phase == "approach")
 fish.pos = game.player - Vector2(100, 0)
 game.DOURADO.update(fish, 1.0, game.player, game.ARENA)
 assert(fish.phase == "approach", "Cannot prepare another dash before cooldown ends")
 game.DOURADO.update(fish, 1.25, game.player, game.ARENA)
 assert(fish.phase == "warning", "Can attack when cooldown ends")
 game.DOURADO.initialize(fish)
 fish.stat_multiplier = 2.0
 fish.pos = game.player - Vector2(100, 0)
 game.DOURADO.update(fish, 0, game.player, game.ARENA)
 game.DOURADO.update(fish, game.DOURADO.WARNING_TIME, game.player, game.ARENA)
 start = fish.pos
 game.DOURADO.update(fish, 0.1, game.player, game.ARENA)
 assert(is_equal_approx(fish.pos.x - start.x, game.DOURADO.DASH_SPEED * 2 * 0.1))
 fish.pos = game.player - Vector2(100, 0)
 game.DOURADO.initialize(fish)
 game.DOURADO.update(fish, 0, game.player, game.ARENA, Vector2(0, 190))
 var expected := Vector2(100, 95).normalized()
 assert(Vector2(fish.dash_direction).is_equal_approx(expected), "Aim ahead of moving canoe")
 game.DOURADO.update(fish, 0.25, game.player, game.ARENA, Vector2(0, -190))
 assert(Vector2(fish.dash_direction).is_equal_approx(expected), "Warning must keep its original aim")
 game.DOURADO.initialize(fish)
 game.DOURADO.update(fish, 0, game.player, game.ARENA, Vector2(0, 380))
 assert(Vector2(fish.dash_direction).is_equal_approx(Vector2(100, 190).normalized()), "Faster canoe leads farther")
 fish.pos = Vector2(100, 100)
 game.DOURADO.initialize(fish)
 game.DOURADO.update(fish, 0, Vector2(18, 100), game.ARENA, Vector2(-190, 0))
 assert(Vector2(fish.dash_direction).is_equal_approx(Vector2.LEFT), "Prediction clamps at arena edge")
 for quality in [0, 1, 2]:
  assert(game.character_quality.texture_for("dourado", quality, game.dourado_art.texture) != null)
 print("DOURADO PASS: unlock, training, artwork collision, XP, locked warning, straight dash and recovery")
 if "--capture" in OS.get_cmdline_user_args():
  fish.pos = game.player + Vector2(100, 0)
  game.DOURADO.update(fish, 0, game.player, game.ARENA)
  game.queue_redraw()
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/pacu-preview.png")
 quit()
