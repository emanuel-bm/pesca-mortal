extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.show_settings()
 for picker in [game.resolution_picker, game.quality_picker]:
  picker.get_popup().popup()
  await process_frame
  assert(picker.get_popup().visible)
  assert(not game.sounds.focus_paused, "Opening a select must keep audio playing")
  picker.get_popup().hide()
  await process_frame
  assert(not game.sounds.focus_paused, "Closing a select must keep audio playing")
 game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 assert(game.sounds.focus_paused, "Leaving the game must still pause audio")
 game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 assert(not game.sounds.focus_paused)
 game.free()
 print("SELECT AUDIO PASS: dropdowns preserve audio; external focus loss still pauses")
 quit()
