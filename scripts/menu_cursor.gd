extends Node2D

var game: Node2D

func _process(_delta: float) -> void:
 visible = game.state != "playing"
 position = get_viewport().get_mouse_position()
 queue_redraw()

func _draw() -> void:
 var direction := Vector2(-1, -1).normalized()
 game.draw_spear(self, -direction * 5.25, direction)
