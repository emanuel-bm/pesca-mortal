extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("endless")
 game.spawn_enemy(false, "dourado")
 var fish: Dictionary = game.enemies.back()
 fish.hp = 100.0
 game.spawn_enemy(true)
 var boss: Dictionary = game.enemies.back()
 game.elapsed = 59.99
 game.update_minute_buffs()
 assert(fish.hp == 100 and fish.speed == 100)
 game.elapsed = 60
 game.update_minute_buffs()
 assert(is_equal_approx(fish.hp, 110) and is_equal_approx(fish.max_hp, 220))
 assert(is_equal_approx(fish.speed, 110) and is_equal_approx(fish.contact, 16.5))
 assert(boss.hp == 32000, "Minute buffs apply only to fish")
 game.update_minute_buffs()
 assert(is_equal_approx(fish.hp, 110), "Same minute must not buff twice")
 game.elapsed = 180
 game.update_minute_buffs()
 assert(is_equal_approx(fish.hp, 100 * pow(1.1, 3)))
 game.buff_endless_enemies()
 game.spawn_enemy(false, "dourado")
 var fresh: Dictionary = game.enemies.back()
 assert(is_equal_approx(fresh.max_hp, fish.max_hp) and is_equal_approx(fresh.speed, fish.speed))
 assert(is_equal_approx(fresh.stat_multiplier, pow(1.1, 3) * 1.05))
 assert(game.enemy_xp_reward(fresh) == 8)
 game.state = "paused"
 game._process(60)
 assert(game.elapsed == 180)
 game.start_run("training")
 game.elapsed = 120
 game.training.act("pintado")
 assert(is_equal_approx(game.enemies.back().speed, 80 * pow(1.1, 2)))
 assert(is_equal_approx(game.enemies.back().max_hp, 200 * pow(1.1, 2)))
 print("MINUTE BUFF PASS: boundaries, compounding, wounded HP ratio, new fish, boss stacking, XP, pause and training")
 quit()
