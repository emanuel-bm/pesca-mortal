extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for mode in ["endless", "bosses"]:
  game.start_run(mode)
  game.elapsed = 59.99
  assert(game.fish_spawn_weights() == [1.0, 0.0, 0.0, 0.0])
  game.elapsed = 60
  assert(game.fish_spawn_weights() == [0.8, 0.2, 0.0, 0.0])
  game.boss_spawned = true
  assert(game.fish_spawn_weights() == [0.7, 0.3, 0.0, 0.0])
  if mode == "endless": game.endless_wave = 2
  else: game.bosses_defeated = 1
  assert(game.fish_spawn_weights() == [0.5, 0.15, 0.25, 0.1])
  game.elapsed = 3600
  assert(game.fish_spawn_weights() == [0.5, 0.15, 0.25, 0.1])
 game.rng.seed = 42
 var counts := {"piranha": 0, "pintado": 0, "pacu": 0, "dourado": 0}
 for index in 10000: counts[game.roll_fish_species()] += 1
 for pair in [["piranha", 0.5], ["pintado", 0.15], ["pacu", 0.25], ["dourado", 0.1]]:
  assert(absf(counts[pair[0]] / 10000.0 - pair[1]) < 0.02)
 game.start_run("bosses")
 game.spawn_timer = 1000
 game.attack_timer = 1000
 game.boss_spawned = true
 game.spawn_enemy(true)
 game.enemies.back().hp = 0
 game.update_game(0)
 assert(game.state == "playing" and game.bosses_defeated == 1 and game.pacu_unlocked())
 game.start_run("training")
 game.elapsed = 600
 game.endless_wave = 2
 game.training.act("piranha")
 game.training.act("pintado")
 assert(game.enemies.size() == 200)
 for index in 200:
  assert(game.enemies[index].get("species", "") not in ["dourado", "pacu"])
  assert(game.enemies[index].tank == (index >= 100))
 print("SPAWN DISTRIBUTION PASS: timed stages, mode triggers, final weights, boss continuation and explicit training hordes")
 quit()
