extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func press(adapter: Node, button: JoyButton) -> void:
 var event := InputEventJoypadButton.new()
 event.button_index = button
 event.pressed = true
 adapter._input(event)
func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.online.profile = {"nickname": "Teste"}
 game.show_menu()
 await process_frame
 await process_frame
 var adapter: Node = game.controller_input
 adapter.set_connected(true)
 assert(adapter.connected and adapter.using_controller)
 assert(game.controls_help_button.text == "Controle")
 game.open_controls_help()
 await process_frame
 assert(game.state == "controls_help")
 var tabs: Node = game.panel.get_child(1)
 assert(tabs.get_child(1).button_pressed)
 await process_frame
 assert(root.gui_get_focus_owner() == tabs.get_child(1), "Focus must remain on selected controller tab")
 assert(tabs.size.y < 48, "Help tabs should use compact ranking tab height")
 tabs.get_child(0).pressed.emit()
 await process_frame
 assert(game.panel.get_child(1).get_child(0).button_pressed)
 await process_frame
 assert(root.gui_get_focus_owner() == game.panel.get_child(1).get_child(0))
 assert(adapter.using_controller)
 press(adapter, JOY_BUTTON_B)
 await process_frame
 assert(game.state == "menu")
 var keyboard := InputEventKey.new()
 keyboard.keycode = KEY_SHIFT
 keyboard.pressed = true
 adapter._input(keyboard)
 assert(game.controls_help_button.text == "Teclado")
 game.open_controls_help()
 await process_frame
 assert(game.panel.get_child(1).get_child(0).button_pressed)
 await process_frame
 assert(root.gui_get_focus_owner() == game.panel.get_child(1).get_child(0))
 game.show_menu()
 await process_frame
 adapter.set_input_mode(true)
 adapter.send_key(KEY_DOWN)
 await process_frame
 assert(root.gui_get_focus_owner().text == "Boss Rush")
 press(adapter, JOY_BUTTON_A)
 await process_frame
 assert(game.state == "playing")
 press(adapter, JOY_BUTTON_START)
 await process_frame
 assert(game.state == "paused")
 press(adapter, JOY_BUTTON_B)
 await process_frame
 assert(game.state == "playing")
 game.show_upgrades()
 await process_frame
 adapter.set_input_mode(false)
 adapter.refresh_prompts(game)
 for cap in game.find_children("UpgradeKeycap", "PanelContainer", true, false):
  assert(cap.visible, "Keyboard upgrade keycaps must remain visible with a controller connected")
 var cursors := game.find_children("*", "Node2D", true, false)
 for cursor in cursors:
  if cursor.get_script() == load("res://scripts/menu_cursor.gd"):
   cursor._process(0.0)
   assert(cursor.visible, "Keyboard cursor must remain visible with a controller connected")
 var previous: int = game.selected_upgrade
 adapter.send_key(KEY_RIGHT)
 await process_frame
 assert(game.selected_upgrade == (previous + 1) % game.choices.size())
 press(adapter, JOY_BUTTON_A)
 await process_frame
 assert(game.state == "playing")
 adapter.set_connected(false)
 assert(not adapter.using_controller)
 game.queue_free()
 await process_frame
 print("CONTROLLER PASS: menu, confirm, pause, resume, upgrade, disconnect")
 quit()
