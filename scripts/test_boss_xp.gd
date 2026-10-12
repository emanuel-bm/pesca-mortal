extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 await process_frame
 game.set_process(false)
 for mode in ["endless", "bosses"]:
  game.start_run(mode)
  game.test_run = true
  game.spawn_timer = 10000
  game.attack_timer = 10000
  game.spawn_enemy(true)
  game.enemies.back().pos = game.player + Vector2(200, 0)
  game.enemies.back().hp = 0
  game.update_game(0)
  assert(game.gems.size() == 1 and game.gems[0].xp == 250 and game.gems[0].giant)
  assert(game.gems[0].kind == "ventrecha")
  assert(game.state == "playing")
  assert(game.cards.pickups.size() == (1 if mode == "endless" else 0))
  if mode == "endless":
   game.xp_bonus = 100
   var first_cost: int = game.xp_needed()
   game.gems[0].pos = game.player
   game.update_game(0)
   assert(game.gems.is_empty())
   var earned: float = game.current_xp() + first_cost
   assert(is_equal_approx(earned, 500), "Boss pickup must preserve XP bonuses and level progression")
 game.start_run("endless")
 game.test_run = true
 game.spawn_timer = 10000
 game.attack_timer = 10000
 game.spawn_enemy(true, "pai_do_mato")
 game.enemies.back().pos = game.player + Vector2(200, 0)
 game.enemies.back().hp = 0
 game.update_game(0)
 assert(game.gems.size() == 1 and game.gems[0].xp == 5000 and game.gems[0].kind == "forest_gem")
 var first_cost: int = game.xp_needed()
 game.gems[0].pos = game.player
 game.update_game(0)
 assert(game.gems.is_empty() and is_equal_approx(game.current_xp() + first_cost, 5000))
 print("BOSS XP PASS: Minhocao 250 XP, Pai do Mato green gem 5000 XP, pickup and XP bonus")
 if "--capture" in OS.get_cmdline_user_args():
  game.start_run("endless")
  game.test_run = true
  game.graphics_quality = 2
  game.gems.append({"pos": game.player + Vector2(-60, 90), "xp": 1})
  game.gems.append({"pos": game.player + Vector2(40, 90), "xp": 250, "giant": true})
  game.gems.append({"pos": game.player + Vector2(150, 90), "xp": 5000, "giant": true, "kind": "forest_gem"})
  game.queue_redraw()
  game.xp_renderer.queue_redraw()
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/boss-xp-preview.png")
 game.free()
 quit(0)
