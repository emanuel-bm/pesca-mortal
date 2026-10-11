extends Control

var angle := 0.0

func _ready() -> void:
 custom_minimum_size = Vector2(32, 32)
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
 angle = fmod(angle + delta * 4.0, TAU)
 queue_redraw()

func _draw() -> void:
 var center := size * 0.5
 draw_arc(center, 12.0, 0.0, TAU, 32, Color("263b4d"), 3.0, true)
 draw_arc(center, 12.0, angle, angle + PI * 1.4, 32, Color("ffd36b"), 3.0, true)
