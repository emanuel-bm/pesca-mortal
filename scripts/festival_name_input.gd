extends LineEdit
## Festival kiosk: bypass native text composition, accepting ASCII names only.
## Read-only native editing prevents Windows dead keys from opening IME editing.

func _init() -> void:
 editable = false
 context_menu_enabled = false
 drag_and_drop_selection_enabled = false
 caret_force_displayed = false
 caret_blink = true

var unfocused_placeholder := ""

func _ready() -> void:
 unfocused_placeholder = placeholder_text
 focus_entered.connect(_show_editing_state)
 focus_exited.connect(_show_idle_state)

func _show_editing_state() -> void:
 placeholder_text = ""
 caret_force_displayed = true

func _show_idle_state() -> void:
 placeholder_text = unfocused_placeholder
 caret_force_displayed = false

func _gui_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed: return
 # Leave fullscreen and focus navigation to the game/viewport.
 if event.alt_pressed or event.meta_pressed: return
 if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
  release_focus()
  accept_event()
  return
 if event.keycode in [KEY_TAB, KEY_UP, KEY_DOWN]: return
 if event.ctrl_pressed:
  if event.keycode == KEY_A:
   select_all()
   accept_event()
  return
 if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END]: return
 if event.keycode in [KEY_BACKSPACE, KEY_DELETE]:
  if has_selection():
   _remove_selection()
  elif event.keycode == KEY_BACKSPACE and caret_column > 0:
   var position := caret_column
   text = text.erase(position - 1, 1)
   caret_column = position - 1
  elif event.keycode == KEY_DELETE:
   var position := caret_column
   text = text.erase(position, 1)
   caret_column = position
  text_changed.emit(text)
 else:
  var code: int = event.unicode
  if (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code in [32, 45, 46, 95]:
   if has_selection(): _remove_selection()
   insert_text_at_caret(String.chr(code))
   text_changed.emit(text)
 accept_event()

func _remove_selection() -> void:
 var position := get_selection_from_column()
 delete_text(position, get_selection_to_column())
 deselect()
 caret_column = position
