extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_run()
 game.spawn_timer = 100
 game.attack_timer = 100
 for tank in [false, true]:
  var art: Dictionary = game.pintado_art if tank else game.piranha_art
  assert(not art.is_empty() and not art.polygons.is_empty())
  var enemy := {"pos": game.player + Vector2(120 if tank else -120, 0), "radius": 44.0 if tank else 13.0, "boss": false, "tank": tank, "facing_left": false, "hp": 100.0, "max_hp": 100.0, "speed": 0.0, "contact": 15.0 if tank else 10.0, "flash": 0.0}
  var size: Vector2 = game.FISH_VISUALS.size_for(art, enemy.radius)
  assert(is_equal_approx(maxf(size.x, size.y), 88.0 if tank else 26.0))
  assert(game.enemy_overlaps(enemy, enemy.pos, 0), "Body center must collide")
  assert(not game.enemy_overlaps(enemy, enemy.pos + Vector2.ONE * enemy.radius, 0), "Transparent corner must not collide")
  for x in range(-24, 25, 4):
   for y in range(-24, 25, 4):
    enemy.facing_left = false
    var original: bool = game.enemy_overlaps(enemy, enemy.pos + Vector2(x, y), 0)
    enemy.facing_left = true
    assert(game.enemy_overlaps(enemy, enemy.pos + Vector2(-x, y), 0) == original, "Hitbox must mirror with sprite")
  game.enemies.append(enemy)
 assert(game.water_texture != null and game.canoe_texture != null)
 var map_area: Rect2 = game.minimap_world_rect()
 assert(game.minimap_point(Vector2.ZERO).is_equal_approx(map_area.position))
 assert(game.minimap_point(game.ARENA).is_equal_approx(map_area.end))
 assert(game.minimap_point(game.ARENA / 2).is_equal_approx(map_area.get_center()))
 assert(game.get_viewport_rect().encloses(game.minimap_rect()))
 game.set_process(false)
 var before: float = game.water_time
 game.update_water(0.5)
 assert(game.water_time > before)
 game.state = "paused"
 before = game.water_time
 game.update_water(0.5)
 assert(game.water_time == before, "Water must freeze during pause")
 game.state = "playing"
 game.player += Vector2(40, 20)
 game.update_water(0.0)
 assert(game.water_material.get_shader_parameter("camera_world") == game.camera_offset())
 print("FISH PASS: 26/88px sizes, silhouette collision, transparent corners, mirroring, water and canoe")
 if "--capture" in OS.get_cmdline_user_args():
  game.gems.append({"pos": game.player + Vector2(70, 90), "xp": 1})
  game.gems.append({"pos": game.player + Vector2(-70, 90), "xp": 5})
  game._process(0.0)
  assert(game.health_bar.size.y == 20 and game.xp_bar.size.y == 20)
  assert(game.health_bar.position.y == 0 and game.xp_bar.position.y == 20)
  assert(game.health_label.get_theme_font_size("font_size") == 16)
  assert(game.xp_label.get_theme_constant("outline_size") == 0)
  assert("HP" in game.health_label.text)
  var cells: NoiseTexture2D = game.water_material.get_shader_parameter("cell_texture")
  if cells.get_image() == null: await cells.changed
  cells.get_image().save_png("res://.tools/water-cells.png")
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/river-preview.png")
 quit(0)

