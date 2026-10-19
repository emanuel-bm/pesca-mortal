extends Node
## Shared controller adapter for the launcher and game. Uses existing keyboard UI paths.
var connected := false
var direction_key: Key = KEY_NONE
var repeat_time := 0.0
var using_controller := false
var prompt_timer := 0.0

func _ready() -> void:
 Input.joy_connection_changed.connect(_connection_changed)
 _connection_changed(-1, false)

func _connection_changed(_device: int, _attached: bool) -> void:
 set_connected(not Input.get_connected_joypads().is_empty())

func set_connected(value: bool) -> void:
 connected = value
 set_input_mode(value)
 direction_key = KEY_NONE
 repeat_time = 0.0
 if value:
  var buttons := get_parent().find_children("*", "Button", true, false)
  if get_viewport().gui_get_focus_owner() == null:
   for button in buttons:
    if button.is_visible_in_tree() and not button.disabled:
     button.grab_focus()
     break
 refresh_prompts(get_parent())

func set_input_mode(value: bool) -> void:
 if using_controller == value: return
 using_controller = value
 refresh_prompts(get_parent())
 if get_parent().has_method("update_controls_button"):
  get_parent().update_controls_button()

func refresh_prompts(node: Node) -> void:
 if node is Label:
  if node.text.begins_with("WASD / setas:") or node.has_meta("keyboard_prompt"):
   if not node.has_meta("keyboard_prompt"): node.set_meta("keyboard_prompt", node.text)
   node.text = "Analógico / direcional: mover · Ataque automático\nColete ventrechas para evoluir · Start: pausar" if using_controller else str(node.get_meta("keyboard_prompt"))
 if node.name == "UpgradeKeycap": node.visible = not using_controller
 for child in node.get_children():
  if child != self: refresh_prompts(child)

func movement(include_stick: bool = true) -> Vector2:
 var result := Vector2.ZERO
 for device in Input.get_connected_joypads():
  var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
  if not include_stick: stick = Vector2.ZERO
  var strength := stick.length()
  stick = stick.normalized() * clampf((strength - 0.22) / 0.78, 0.0, 1.0)
  var pad := Vector2(float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)), float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)))
  var candidate := (stick + pad).limit_length()
  if candidate.length_squared() > result.length_squared(): result = candidate
 return result

func send_key(code: Key) -> void:
 var event := InputEventKey.new()
 event.set_meta("controller_generated", true)
 event.keycode = code
 event.pressed = true
 Input.parse_input_event(event)
 var release := InputEventKey.new()
 release.keycode = code
 Input.parse_input_event(release)

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and event.relative.length_squared() > 0:
  set_input_mode(false)
 if event is InputEventKey and event.pressed and not event.has_meta("controller_generated"):
  set_input_mode(false)
 elif event is InputEventMouseButton and event.pressed:
  set_input_mode(false)
 elif event is InputEventJoypadButton and event.pressed:
  set_input_mode(true)
 elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
  set_input_mode(true)
 if event is InputEventJoypadMotion:
  get_viewport().set_input_as_handled()
  return
 if not event is InputEventJoypadButton: return
 if event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
  get_viewport().set_input_as_handled()
  return
 # Consume mapped buttons so Godot's built-in joypad actions cannot activate twice.
 var code: Key = KEY_NONE
 match event.button_index:
  JOY_BUTTON_A: code = KEY_ENTER
  JOY_BUTTON_B, JOY_BUTTON_START: code = KEY_ESCAPE
 if code == KEY_NONE: return
 get_viewport().set_input_as_handled()
 if not event.pressed: return
 if ("state" in get_parent() and get_parent().get("state") == "playing") and code == KEY_ENTER: return
 send_key(code)

func _process(delta: float) -> void:
 if not connected: return
 prompt_timer -= delta
 if prompt_timer <= 0:
  refresh_prompts(get_parent())
  prompt_timer = 0.1
 if ("state" in get_parent() and get_parent().get("state") == "playing"):
  direction_key = KEY_NONE
  return
 var upgrading: bool = "state" in get_parent() and get_parent().get("state") == "upgrade"
 var axis := movement(not upgrading)
 var code: Key = KEY_NONE
 if absf(axis.y) > 0.5: code = KEY_DOWN if axis.y > 0 else KEY_UP
 elif absf(axis.x) > 0.5: code = KEY_RIGHT if axis.x > 0 else KEY_LEFT
 repeat_time -= delta
 if code != direction_key:
  direction_key = code
  repeat_time = 0.35
  if code != KEY_NONE: send_key(code)
 elif code != KEY_NONE and repeat_time <= 0:
  repeat_time = 0.12
  send_key(code)
