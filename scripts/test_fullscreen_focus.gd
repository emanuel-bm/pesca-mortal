extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Fullscreen focus regression requires a Windows desktop, without --headless")
  quit(1)
  return
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 for full in [false, true, false, true]:
  game.fullscreen = full
  game.apply_display_settings(false)
  DisplayServer.window_move_to_foreground(root.get_window_id())
  root.grab_focus()
  # Foreground activation can be deferred by Windows during a mode switch.
  for attempt in 30:
   DisplayServer.window_move_to_foreground(root.get_window_id())
   await create_timer(0.1).timeout
  print("Fullscreen=", full, " focused=", root.has_focus(), " lost=", game.window_focus_lost, " obscured=", game.window_obscured)
  if game.window_focus_lost or game.window_obscured or game.sounds.focus_paused:
   push_error("Focused fullscreen/windowed game must keep audio and menus active")
   game.free()
   quit(1)
   return
  game.show_settings()
  for item in game.menu_controls:
   if item is Button and item.text == "Voltar":
    item.pressed.emit()
    break
  if game.state != "menu":
   push_error("Settings Back button must work after changing window mode")
   game.free()
   quit(1)
   return
  game.start_run("training")
  game.show_pause()
  game.resume()
  if game.state != "playing":
   push_error("Continue must work after changing window mode")
   game.free()
   quit(1)
   return
  game.show_menu()
 game.free()
 print("FULLSCREEN FOCUS PASS: repeated mode changes preserve audio, settings return and resume")
 quit()
