extends VBoxContainer
## Xbox control reference. Icons are drawn locally to match the game's UI.
const HELP := preload("res://scripts/controls_help_text.gd")
class XboxIcon extends Control:
 var kind := ""
 func _draw() -> void:
  var center := Vector2(28, 28)
  var light := Color("e4e1d8")
  var dark := Color("202b36")
  if kind == "stick":
   draw_circle(center, 25, Color("8b8984"))
   draw_circle(center, 21, light)
   draw_circle(center, 15, dark)
   draw_arc(center, 11, 0, TAU, 32, Color("8b8984"), 2, true)
  elif kind == "pad":
   var points := PackedVector2Array([Vector2(20, 4), Vector2(36, 4), Vector2(36, 20), Vector2(52, 20), Vector2(52, 36), Vector2(36, 36), Vector2(36, 52), Vector2(20, 52), Vector2(20, 36), Vector2(4, 36), Vector2(4, 20), Vector2(20, 20)])
   draw_colored_polygon(points, light)
   draw_circle(center, 4, Color("8b8984"))
  elif kind in ["A", "B"]:
   draw_circle(center, 25, Color("303b45"))
   draw_circle(center, 21, Color("70c44b") if kind == "A" else Color("ef6557"))
   var font := get_theme_default_font()
   var width := font.get_string_size(kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
   draw_string(font, Vector2(28 - width / 2, 38), kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, dark)
  else:
   draw_circle(center, 24, light)
   for y in [19, 28, 37]: draw_line(Vector2(16, y), Vector2(40, y), dark, 3)

func _ready() -> void:
 add_theme_constant_override("separation", 12)
 add_row("stick", "Analógico esquerdo", HELP.MOVE_NAVIGATE)
 add_row("pad", "Direcional", HELP.MOVE_NAVIGATE_CHOOSE)
 add_row("A", "A", HELP.CONFIRM)
 add_row("B", "B", HELP.BACK)
 add_row("menu", "Menu (Start)", HELP.PAUSE)
 var note := Label.new()
 note.text = "Nas melhorias, use somente o direcional."
 note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 note.add_theme_font_size_override("font_size", 22)
 add_child(note)

func add_row(kind: String, name_text: String, description: String) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 12)
 add_child(row)
 var icon := XboxIcon.new()
 icon.kind = kind
 icon.custom_minimum_size = Vector2(56, 56)
 icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(icon)
 var name_label := Label.new()
 name_label.text = name_text
 name_label.custom_minimum_size.x = 180
 name_label.add_theme_font_size_override("font_size", 22)
 row.add_child(name_label)
 var label := Label.new()
 label.text = description
 label.add_theme_font_size_override("font_size", 22)
 row.add_child(label)
