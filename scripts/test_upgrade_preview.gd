extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_run()
 game.show_upgrades()
 for frame in 5: await process_frame
 var base_rect: Rect2 = game.stats_panel.get_global_rect()
 var menu_rect: Rect2 = game.overlay.get_global_rect()
 var row_rects: Dictionary = {}
 for key in game.stat_values:
  row_rects[key] = game.stat_values[key].get_parent().get_global_rect()
 for hovered in game.UPGRADES:
  game.update_stats_preview(hovered)
  for frame in 5: await process_frame
  if not game.stats_panel.get_global_rect().is_equal_approx(base_rect) or not game.overlay.get_global_rect().is_equal_approx(menu_rect):
   push_error("Hover changed modal geometry: %s; stats %s -> %s; menu %s -> %s" % [hovered, base_rect, game.stats_panel.get_global_rect(), menu_rect, game.overlay.get_global_rect()])
   quit(1)
   return
  for key in game.stat_values:
   if not game.stat_values[key].get_parent().get_global_rect().is_equal_approx(row_rects[key]):
    push_error("Hover changed row geometry: " + key)
    quit(1)
    return
  game.update_stats_preview()
  for frame in 5: await process_frame
 for id in game.UPGRADES:
  game.show_upgrades()
  assert(game.stats_panel.visible)
  var before: Dictionary = game.projected_stats()
  game.update_stats_preview(id)
  assert("→" in game.stat_values[id].text)
  assert(game.projected_stats() == before, "Hover must not modify stats")
  var expected: Dictionary = game.projected_stats(id)
  game.choose_upgrade(id)
  var actual: Dictionary = game.projected_stats()
  for key in actual: assert(is_equal_approx(float(actual[key]), float(expected[key])))
  assert(not game.stats_panel.visible)
 game.speed = 250.0
 game.update_stats_preview("speed")
 assert(game.stat_values.speed.text == "250 → 260")
 game.start_run()
 game.show_upgrades()
 for child in game.panel.get_children():
  if child is Button:
   child.mouse_entered.emit()
   assert(game.preview_upgrade != "")
   child.mouse_exited.emit()
   assert(game.preview_upgrade != "")
 game.show_upgrades()
 assert(game.selected_upgrade == 0 and game.preview_upgrade == game.choices[0])
 assert(game.upgrade_buttons[0].has_focus())
 assert(game.format_stat("rate", 1.53846) == "1,54")
 var navigation := InputEventKey.new()
 navigation.pressed = true
 for movement_key in [KEY_W, KEY_A, KEY_S, KEY_D]:
  navigation.keycode = movement_key
  game._input(navigation)
  assert(game.selected_upgrade == 0 and game.preview_upgrade == game.choices[0], "WASD must not navigate menus")
 navigation.keycode = KEY_DOWN
 game._input(navigation)
 assert(game.selected_upgrade == 1 and game.preview_upgrade == game.choices[1])
 navigation.keycode = KEY_UP
 game._input(navigation)
 assert(game.selected_upgrade == 0)
 navigation.keycode = KEY_RIGHT
 game._input(navigation)
 assert(game.selected_upgrade == 1)
 navigation.keycode = KEY_LEFT
 game._input(navigation)
 assert(game.selected_upgrade == 0)
 var picked: String = game.choices[0]
 var old_rank: int = game.upgrade_levels.get(picked, 0)
 navigation.keycode = KEY_ENTER
 game._input(navigation)
 assert(game.state == "playing" and game.upgrade_levels[picked] == old_rank + 1)
 for id in game.UPGRADES: game.upgrade_levels[id] = 50
 game.speed = 250.0
 game.show_upgrades()
 assert(game.state == "upgrade" and game.choices.size() == 3)
 assert(is_equal_approx(game.projected_stats("speed").speed, 260.0))
 var prior: float = game.damage
 game.choose_upgrade("damage")
 assert(game.damage > prior and game.upgrade_levels.damage == 51)
 game.xp = 4
 game._process(0)
 assert(game.xp_bar.value == 4 and game.xp_bar.max_value == game.xp_needed())
 assert(game.xp_bar.size.x == game.get_viewport_rect().size.x)
 var saved_volumes: Dictionary = game.sounds.volumes.duplicate()
 game.sounds.volumes.master = 0.5
 game.sounds.volumes.shot = 0.2
 game.sounds.volumes.death = 0.8
 game.sounds.apply_volumes()
 assert(is_equal_approx(game.sounds.players.shot.volume_linear, 0.05))
 assert(is_equal_approx(game.sounds.players.death.volume_linear, 0.08))
 game.sounds.volumes.master = 0.0
 game.sounds.apply_volumes()
 for id in game.sounds.players: assert(not game.sounds.effect_enabled(id))
 for player in game.sounds.players.values(): assert(player.volume_linear == 0.0)
 game.sounds.volumes.master = 1.0
 game.sounds.volumes.shot = 0.0
 assert(not game.sounds.effect_enabled("shot") and game.sounds.effect_enabled("death"))
 game.sounds.volumes = saved_volumes
 game.sounds.apply_volumes()
 print("PREVIEW PASS: unlimited upgrades and speed, full-width XP bar, shot volume, hover and application")
 if "--capture" in OS.get_cmdline_user_args():
  game.update_stats_preview(game.choices[0])
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/upgrade-preview.png")
 quit(0)
