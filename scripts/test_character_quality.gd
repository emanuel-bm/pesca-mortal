extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_horde_test()
 game.clear_panel()
 var offset: Vector2 = game.camera_offset()
 for i in game.enemies.size():
  game.enemies[i].pos = offset + Vector2(50 + (i % 30) * 33, 140 + (i / 30) * 23)
 game.enemies[518].pos = offset + Vector2(400, 400)
 game.enemies[519].pos = offset + Vector2(800, 400)
 for id in ["piranha", "pintado", "canoe", "boss"]:
  assert(game.character_quality.variants.has(id))
  var images: Array = game.character_quality.variants[id]
  assert(images[0].get_width() < images[1].get_width())
 game.enemies[518].phase = "exposed"
 game.enemies[519].phase = "exposed"
 game.enemies[0].facing_left = true
 game.enemies[0].flash = 0.2
 var health: float = game.health
 var radius: float = game.enemies[0].radius
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 for quality in [2, 1, 0]:
  game.graphics_quality = quality
  game.apply_graphics_quality()
  for frame in 10:
   game.queue_redraw()
   await process_frame
  var started := Time.get_ticks_usec()
  for frame in 90:
   game.queue_redraw()
   await process_frame
  print("QUALITY ", quality, " static 520-enemy frame mean ms: ", (Time.get_ticks_usec() - started) / 90000.0)
  if quality < 2:
   assert(game.character_quality.fish_batches[0].visible_instance_count == 259)
   assert(game.character_quality.fish_batches[1].visible_instance_count == 259)
   assert(game.character_quality.fish_batches[0].get_instance_transform_2d(0).origin.is_equal_approx(game.enemies[0].pos - offset))
   assert(game.character_quality.fish_batches[0].get_instance_transform_2d(0).x.x < 0)
   assert(game.character_quality.fish_batches[0].get_instance_color(0).r > 1)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/quality-%d.png" % quality)
 assert(game.health == health and game.enemies[0].radius == radius)
 print("CHARACTER QUALITY PASS: lower-resolution art, batches, positions and gameplay unchanged")
 quit()
