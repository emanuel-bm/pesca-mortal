extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.show_menu()
 game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 assert(game.state == "menu", "Focus loss must preserve the main menu")
 for mode in ["endless", "bosses", "training"]:
  game.start_run(mode)
  game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
  assert(game.state == "paused" and game.overlay.visible, "Focus loss must open the pause menu in every mode")
  var elapsed: float = game.elapsed
  var player: Vector2 = game.player
  var health: float = game.health
  for frame in 3: await process_frame
  assert(game.elapsed == elapsed and game.player == player and game.health == health, "The paused run must not advance")
  var continue_button: Node = root.gui_get_focus_owner()
  game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
  assert(root.gui_get_focus_owner() == continue_button, "Repeated focus loss must preserve the pause menu")
  game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
  assert(game.state == "paused", "Returning focus must leave the run paused")
  game.resume()
  assert(game.state == "playing" and not game.overlay.visible, "Continue must resume the run")
 for state in ["upgrade", "settings", "won", "lost"]:
  game.state = state
  game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
  assert(game.state == state, "Focus loss must preserve existing modal states")
 game.run_active = false
 game.queue_free()
 await process_frame
 print("Focus pause checks passed: all modes, frozen gameplay, explicit resume and preserved menus.")
 quit()
