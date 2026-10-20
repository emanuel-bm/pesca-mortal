extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for mode in ["endless", "bosses", "training"]:
  game.start_run(mode)
  game.spawn_timer = INF
  game.attack_timer = INF
  game.next_boss_time = INF
  game.spawn_enemy(false, "dourado")
  var survivor: Dictionary = game.enemies.back()
  survivor.hp = 50.0
  for sample in [[59.99, 1.0], [60.0, 1.2], [120.0, 1.4], [180.0, 1.5], [1200.0, 2.52], [1800.0, 3.12]]:
   game.elapsed = sample[0]
   game.update_game(0.0)
   assert(is_equal_approx(survivor.hp, 50.0 * sample[1]))
   assert(is_equal_approx(survivor.max_hp, 100.0 * sample[1]))
   assert(is_equal_approx(survivor.speed, 100.0 * sample[1]))
   assert(is_equal_approx(survivor.contact, 30.0 * minf(sample[1], 3.0)))
   assert(is_equal_approx(game.DOURADO.dash_range(survivor), game.DOURADO.DASH_BASE_DISTANCE * sample[1]))
   assert(is_equal_approx(game.DOURADO.dash_speed(survivor), game.DOURADO.DASH_SPEED * sample[1]))
   game.spawn_enemy(false, "dourado")
   var fresh: Dictionary = game.enemies.back()
   assert(is_equal_approx(fresh.max_hp, 100.0 * sample[1]))
   assert(is_equal_approx(fresh.speed, 100.0 * sample[1]))
   assert(is_equal_approx(fresh.contact, 30.0 * minf(sample[1], 3.0)))
   assert(is_equal_approx(game.DOURADO.dash_range(fresh), game.DOURADO.DASH_BASE_DISTANCE * sample[1]))
   assert(game.enemy_xp_reward(fresh) == 20)
   game.enemies.erase(fresh)
  game.state = "paused"
  game._process(60)
  assert(game.elapsed == 1800.0)
 game.start_run("training")
 game.elapsed = 120.0
 game.training.act("pintado")
 assert(is_equal_approx(game.enemies.back().speed, 80.0 * 1.4))
 assert(is_equal_approx(game.enemies.back().max_hp, 100.0 * 1.4))
 print("MINUTE BUFF PASS: living and spawned enemy growth, minute boundaries, wounded HP, dash attributes, damage cap, XP, pause and training")
 quit()
