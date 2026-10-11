extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 assert(game.hud.get_theme_font("font") == game.game_font, "HUD must use the global DOS font")
 game.show_upgrades()
 for child in game.panel.get_children():
  if child is Control: assert(child.get_theme_font("font") == game.game_font)
 game.start_run()
 game.spawn_timer = 100
 game.attack_timer = 100
 game.spawn_enemy(false)
 var enemy: Dictionary = game.enemies[0]
 enemy.pos = game.player + Vector2(100, 0)
 enemy.speed = 0
 game.bullets.append({"pos": enemy.pos, "velocity": Vector2.ZERO, "life": 1.0})
 game.update_game(0.01)
 assert(game.damage_numbers.size() == 1 and game.damage_numbers[0].text == "20")
 assert(is_equal_approx(enemy.hp, 1.0))
 game.bullets.append({"pos": enemy.pos, "velocity": Vector2.ZERO, "life": 1.0})
 game.update_game(0.01)
 assert(game.enemies.is_empty() and game.damage_numbers.size() == 2, "Lethal hits must show damage too")
 game.update_damage_numbers(0.71)
 assert(game.damage_numbers.is_empty(), "Numbers must expire")
 game.add_damage_number(game.player, 24.5)
 assert(game.damage_numbers[0].text == "25")
 game.start_run()
 assert(game.damage_numbers.is_empty(), "Restart clears numbers")
 game.spawn_timer = 100
 game.attack_timer = 100
 game.spawn_enemy(true)
 enemy = game.enemies[0]
 game.bullets.append({"pos": enemy.pos, "velocity": Vector2.ZERO, "life": 1.0})
 game.update_game(0.01)
 assert(game.damage_numbers.is_empty(), "Buried boss must not show a hit")
 var stream: AudioStream = game.sounds.players.shot.stream
 assert(stream != null and stream.get_length() > 0.1 and stream.get_length() < 0.4)
 print("FEEDBACK PASS: normal/lethal hit, decimal damage, expiry, restart, buried immunity, recorded spear audio")
 if "--capture" in OS.get_cmdline_user_args():
  game.start_run()
  game.spawn_timer = 100
  game.attack_timer = 100
  game.spawn_enemy(false)
  enemy = game.enemies[0]
  enemy.pos = game.player + Vector2(90, 0)
  enemy.speed = 0
  game.bullets.append({"pos": enemy.pos, "velocity": Vector2.ZERO, "life": 1.0})
  game.update_game(0.01)
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/damage-preview.png")
 quit(0)
