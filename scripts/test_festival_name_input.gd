extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.start_run("endless")
 game.festival_result = {"run_id": "test"}
 game.finish(false)
 var field: LineEdit = game.festival_name_edit
 assert(not field.editable, "Festival name must bypass native accent composition")
 await process_frame
 assert(not field.has_focus(), "Result name must not start focused")
 var hint := field.placeholder_text
 assert(not hint.is_empty() and not field.caret_force_displayed)
 game.menu_mouse_navigation = true
 game.focus_menu_hover(field)
 assert(not field.has_focus(), "Hover must not activate the name field")
 field.grab_focus()
 assert(field.placeholder_text.is_empty(), "Focused name must hide the placeholder")
 assert(field.caret_force_displayed and field.caret_blink, "Focused name must show a blinking caret")
 for code in [74, 111, 227, 111, 0, 65]:
  var event := InputEventKey.new()
  event.pressed = true
  event.unicode = code
  event.keycode = KEY_A if code == 0 else code
  field._gui_input(event)
 assert(field.text == "JooA", "Accent/dead key must be ignored and subsequent typing must work")
 var backspace := InputEventKey.new()
 backspace.pressed = true
 backspace.keycode = KEY_BACKSPACE
 field._gui_input(backspace)
 assert(field.text == "Joo")
 var escape := InputEventKey.new()
 escape.pressed = true
 escape.keycode = KEY_ESCAPE
 field._gui_input(escape)
 assert(not field.has_focus(), "Escape must release name entry")
 assert(game.festival_name_draft == "Joo")
 field.grab_focus()
 field.select_all()
 var replace_key := InputEventKey.new()
 replace_key.pressed = true
 replace_key.unicode = 66
 replace_key.keycode = KEY_B
 field._gui_input(replace_key)
 assert(field.text == "B", "Selection replacement must work")
 for index in 40: field._gui_input(replace_key)
 assert(field.text.length() == 30, "Keep the participant name limit")
 var toggle := InputEventKey.new()
 toggle.pressed = true
 toggle.alt_pressed = true
 toggle.keycode = KEY_ENTER
 var was_fullscreen: bool = game.fullscreen
 game._input(toggle)
 assert(game.fullscreen != was_fullscreen, "Fullscreen shortcut must work while entering a name")
 game._input(toggle)
 game.free()
 print("FESTIVAL NAME INPUT PASS")
 quit()
