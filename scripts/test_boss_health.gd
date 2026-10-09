extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_endless_test()
 game._process(0)
 assert(game.hud.text.contains("MINHOCÃO x2"))
 assert(not game.hud.text.contains("MERGULHOU"))
 game.spawn_timer = 1000
 game.attack_timer = 1000
 game.invulnerability = 1000
 var boss: Dictionary = game.enemies[0]
 boss.pos = game.player + Vector2(200, 0)
 boss.phase = "exposed"
 boss.timer = 1000
 var original: float = boss.hp
 for hit in 20:
  game.bullets.append({"pos": boss.pos, "velocity": Vector2.ZERO, "life": 1.0})
  game.update_game(0)
 assert(is_equal_approx(boss.hp, original - game.damage * 20))
 assert(boss.max_hp == original)
 print("BOSS HEALTH: HP %s -> %s; damage/hit %.2f; bar lost/hit %.3f pixels" % [original, boss.hp, game.damage, game.damage / original * 100])
 boss.phase = "burrow"
 game.bullets.append({"pos": boss.pos, "velocity": Vector2.ZERO, "life": 1.0})
 var before: float = boss.hp
 game.update_game(0)
 assert(boss.hp == before)
 print("BOSS HEALTH PASS: exposed damage, stable max health, burrow invulnerability")
 quit(0)
