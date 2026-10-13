extends Control

const MAX_ENTRIES := 5
const LIFETIME := 4.0
const CARD_SIZE := Vector2(162, 54)
const STEP := 62.0
const DISPLAY_SCALE := 1.0
var entries: Array[Dictionary] = []

func _init() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func clear() -> void:
 for entry in entries:
  remove_child(entry.card)
  entry.card.queue_free()
 entries.clear()
 hide()

func add_hit(aggressor: String, texture: Texture2D, damage_text: String) -> void:
 var card := PanelContainer.new()
 card.mouse_filter = Control.MOUSE_FILTER_IGNORE
 card.custom_minimum_size = CARD_SIZE
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.08, 0.10, 0.14, 0.92)
 style.border_color = Color("ec716f")
 style.border_width_left = 3
 style.set_corner_radius_all(5)
 style.corner_radius_top_right = 0
 style.corner_radius_bottom_right = 0
 style.content_margin_left = 8
 style.content_margin_right = 10
 style.content_margin_top = 5
 style.content_margin_bottom = 5
 card.add_theme_stylebox_override("panel", style)
 add_child(card)
 var row := HBoxContainer.new()
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_theme_constant_override("separation", 10)
 card.add_child(row)
 var portrait := TextureRect.new()
 portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
 portrait.texture = texture
 portrait.flip_h = true
 portrait.custom_minimum_size = Vector2(42, 42)
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 row.add_child(portrait)
 var details := VBoxContainer.new()
 details.mouse_filter = Control.MOUSE_FILTER_IGNORE
 details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(details)
 for text in [aggressor, "−%s HP" % damage_text]:
  var label := Label.new()
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  label.text = text
  label.clip_text = true
  label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  label.add_theme_font_size_override("font_size", 18)
  if details.get_child_count() > 0:
   label.add_theme_color_override("font_color", Color("ec716f"))
  details.add_child(label)
 card.size = CARD_SIZE
 card.position = Vector2(CARD_SIZE.x + 22, 0)
 card.modulate.a = 0.0
 entries.push_front({"card": card, "age": 0.0, "aggressor": aggressor, "damage": damage_text})
 if entries.size() > MAX_ENTRIES:
  var oldest: Dictionary = entries.pop_back()
  remove_child(oldest.card)
  oldest.card.queue_free()

func refresh(dt: float, game: Node) -> void:
 visible = game.run_active and game.state in ["playing", "paused", "upgrade"] and not entries.is_empty()
 if not visible: return
 var viewport_size: Vector2 = game.get_viewport_rect().size
 var map: Rect2 = game.minimap_world_rect()
 var top := map.end.y + 14.0
 var feed_scale := minf(DISPLAY_SCALE, maxf(0.1, (viewport_size.y - top - 16.0) / (STEP * MAX_ENTRIES - 8.0)))
 scale = Vector2.ONE * feed_scale
 position = Vector2(viewport_size.x - CARD_SIZE.x * feed_scale, top)
 var active_dt := dt if game.state == "playing" else 0.0
 for i in range(entries.size() - 1, -1, -1):
  var entry := entries[i]
  entry.age += active_dt
  if entry.age >= LIFETIME:
   remove_child(entry.card)
   entry.card.queue_free()
   entries.remove_at(i)
 for i in entries.size():
  var entry := entries[i]
  entry.card.position = entry.card.position.lerp(Vector2(0, i * STEP), 1.0 - exp(-18.0 * active_dt))
  entry.card.modulate.a = minf(clampf(entry.age / 0.18, 0.0, 1.0), clampf((LIFETIME - entry.age) / 0.5, 0.0, 1.0))
