extends VBoxContainer
## Static keyboard legend, using the same key faces as upgrade cards.
const HELP := preload("res://scripts/controls_help_text.gd")
var game: Node
var keys: Dictionary = {}
var mouse_icon: MouseDrawing

class MouseDrawing extends Control:
 var left_down := false
 var right_down := false
 func _draw() -> void:
  var body := Rect2(8, 3, 42, 51)
  var style := StyleBoxFlat.new()
  style.bg_color = Color("e4e1d8")
  style.border_color = Color("8b8984")
  style.set_border_width_all(2)
  style.border_width_bottom = 4
  style.set_corner_radius_all(14)
  draw_style_box(style, body)
  if left_down: draw_rect(Rect2(12, 9, 15, 19), Color("70dc97"))
  if right_down: draw_rect(Rect2(31, 9, 15, 19), Color("70dc97"))
  draw_line(Vector2(29, 5), Vector2(29, 29), Color("8b8984"), 2)
  draw_line(Vector2(10, 30), Vector2(48, 30), Color("8b8984"), 2)
  draw_style_box(style, Rect2(26, 12, 6, 11))

func _ready() -> void:
 add_theme_constant_override("separation", 10)
 add_row(HELP.MOVE, [["W", KEY_W], ["A", KEY_A], ["S", KEY_S], ["D", KEY_D]])
 add_row(HELP.MOVE_NAVIGATE_CHOOSE, [["↑", KEY_UP], ["←", KEY_LEFT], ["↓", KEY_DOWN], ["→", KEY_RIGHT]])
 add_row(HELP.CHOOSE, [["1", KEY_1], ["2", KEY_2], ["3", KEY_3]])
 add_row(HELP.CONFIRM, [["Enter", KEY_ENTER]])
 add_row(HELP.PAUSE + " / voltar", [["Esc", KEY_ESCAPE]])
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 12)
 add_child(row)
 mouse_icon = MouseDrawing.new()
 mouse_icon.custom_minimum_size = Vector2(58, 58)
 row.add_child(mouse_icon)
 var label := Label.new()
 label.text = "Aponte para selecionar · Clique para confirmar"
 label.add_theme_font_size_override("font_size", 22)
 row.add_child(label)
func add_row(description: String, entries: Array) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 9)
 add_child(row)
 var key_group := HBoxContainer.new()
 key_group.custom_minimum_size.x = 220
 key_group.add_theme_constant_override("separation", 7)
 row.add_child(key_group)
 for entry in entries:
  var cap: PanelContainer = game.build_upgrade_keycap(1)
  cap.name = "HelpKey"
  cap.custom_minimum_size = Vector2(70 if str(entry[0]).length() > 1 else 44, 40)
  cap.get_child(0).text = entry[0]
  cap.get_child(0).add_theme_font_size_override("font_size", 26)
  cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
  cap.tooltip_text = description
  key_group.add_child(cap)
  keys[entry[1]] = cap
 var label := Label.new()
 label.text = description
 label.add_theme_font_size_override("font_size", 22)
 row.add_child(label)
