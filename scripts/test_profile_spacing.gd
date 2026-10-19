extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.online.profile = {"nickname": "Teste"}
 game.show_menu()
 game.player_totals = {"kills": 116184, "seconds": 28676, "levels": 1100}
 for viewport_size in [Vector2i(1152, 720), Vector2i(1920, 1080), Vector2i(640, 400)]:
  root.size = viewport_size
  for i in 8: await process_frame
  var profile: Rect2 = game.profile_panel.get_global_rect()
  var records: Rect2 = game.records_panel.get_global_rect()
  assert(profile.end.y + 10 <= records.position.y, "Profile must leave space above records")
 game.queue_free()
 await process_frame
 print("PROFILE LAYOUT PASS: compact text and gap above rankings at three sizes")
 quit()
