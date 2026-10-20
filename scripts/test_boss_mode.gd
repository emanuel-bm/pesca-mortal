extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 await process_frame
 game.set_process(false)
 game.start_run("bosses")
 game.test_run = true
 game.invulnerability = INF
 game.attack_timer = INF
 game.spawn_timer = INF
 game.elapsed = 119.99
 game.update_game(0.0)
 assert(game.enemies.is_empty(), "No boss before two minutes")
 game.elapsed = 120.0
 game.spawn_endless_bosses()
 assert(game.enemies.is_empty(), "Endless scheduler cannot spawn in boss mode")
 game.update_game(0.0)
 assert(game.enemies.size() == 1, "Exactly one Minhocão at two minutes")
 assert(game.enemies[0].get("species", "") != "pai_do_mato")
 game.update_game(0.0)
 assert(game.enemies.size() == 1, "First boss cannot spawn twice")
 game.enemies[0].hp = 0.0
 game.update_game(0.0)
 assert(game.state == "playing" and game.bosses_defeated == 1, "Minhocão death does not end the run")
 game.gems.clear()
 game.elapsed = 149.99
 game.update_game(0.0)
 assert(game.enemies.is_empty(), "No Pai do Mato before thirty seconds after the kill")
 game.elapsed = 150.0
 game.update_game(0.0)
 assert(game.enemies.size() == 1 and game.enemies[0].species == "pai_do_mato", "Exactly one Pai do Mato thirty seconds after the kill")
 game.elapsed = 900.0
 game.update_game(0.0)
 assert(game.enemies.size() == 1 and game.state == "playing", "No extra waves or timed victory")
 game.enemies[0].hp = 0.0
 game.update_game(0.0)
 assert(game.state == "won" and game.match_won and game.kills == 2, "Pai do Mato death records victory and final kill")
 game.start_run("bosses")
 game.test_run = true
 game.invulnerability = INF
 game.attack_timer = INF
 game.spawn_timer = INF
 game.elapsed = 120.0
 game.update_game(0.0)
 game.elapsed = 600.0
 game.update_game(0.0)
 assert(game.enemies.size() == 1 and not is_finite(game.next_boss_time), "Pai do Mato must wait for Minhocao's death, regardless of elapsed time")
 game.enemies[0].hp = 0.0
 game.update_game(0.0)
 assert(game.next_boss_time == 630.0, "Delay starts at the actual kill time")
 game.gems.clear()
 game.elapsed = 629.99
 game.update_game(0.0)
 assert(game.enemies.is_empty(), "No boss before the full thirty-second delay")
 game.elapsed = 630.0
 game.update_game(0.0)
 assert(game.enemies.size() == 1 and game.enemies[0].species == "pai_do_mato")
 game.enemies[0].hp = 0.0
 game.update_game(0.0)
 assert(game.state == "won", "Defeating Pai do Mato is the victory condition")
 game.start_run("bosses")
 assert(game.boss_stage == 0 and game.next_boss_time == 120.0, "Restart clears the delayed spawn")
 game.free()
 print("BOSS MODE PASS: Minhocão at 2:00, Pai do Mato 30s after Minhocao death, victory on Pai do Mato death, no endless waves")
 quit()
