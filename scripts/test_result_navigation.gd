extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func press(game: Node, key: Key) -> void:
 game.controller_input.send_key(key)
 await process_frame

func run() -> void:
 set_meta("offline_session", true)
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 for won in [false, true]:
  game.start_run("endless")
  game.festival_result = {"run_id": "navigation"}
  game.finish(won)
  await process_frame
  await process_frame
  assert(root.gui_get_focus_owner() == null, "Result must start without focus")
  await press(game, KEY_DOWN)
  assert(root.gui_get_focus_owner() == game.festival_name_edit)
  await press(game, KEY_DOWN)
  var first: Control = root.gui_get_focus_owner()
  assert(first is Button and first.get_parent() is HBoxContainer)
  await press(game, KEY_RIGHT)
  var second: Control = root.gui_get_focus_owner()
  assert(second != first and second.get_parent() == first.get_parent(), "Right must navigate within the action row")
  await press(game, KEY_LEFT)
  assert(root.gui_get_focus_owner() == first, "Left must return within the action row")
  await press(game, KEY_UP)
  assert(root.gui_get_focus_owner() == game.festival_name_edit, "Up must return to the name row")
  second.grab_focus()
  await press(game, KEY_DOWN)
  assert(root.gui_get_focus_owner() == game.festival_name_edit, "Down must change rows rather than step sideways")
 game.free()
 print("RESULT NAVIGATION PASS: victory/defeat, controller directions, rows, no initial focus")
 quit()
