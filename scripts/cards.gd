extends Node2D

const IDS := ["ima", "furia", "intangivel", "perfurante"]
const NAMES := {"ima": "ÍMÃ", "furia": "FÚRIA", "intangivel": "INTANGÍVEL", "perfurante": "PERFURANTE"}
const EFFECT_SECONDS := 6.0
const FLOOR_SECONDS := 30.0
const PICKUP_SIZE := Vector2(32, 48)
const SHINE = preload("res://assets/cards/shine.gdshader")

var game: Node2D
var pickups: Array[Dictionary] = []
var effects := {"furia": 0.0, "intangivel": 0.0, "perfurante": 0.0}
var textures: Dictionary = {}
var effect_layer: CanvasLayer
var effect_row: HBoxContainer
var indicators: Dictionary = {}
var blocked_seconds := 0.0
var block_label: Label

func _ready() -> void:
 z_index = 5
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 for id in IDS: textures[id] = load("res://assets/cards/%s.png" % id)
 effect_layer = CanvasLayer.new()
 add_child(effect_layer)
 effect_row = HBoxContainer.new()
 effect_row.position = Vector2(22, 186)
 effect_row.add_theme_constant_override("separation", 18)
 effect_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 effect_layer.add_child(effect_row)
 block_label = Label.new()
 block_label.add_theme_font_size_override("font_size", 14)
 block_label.add_theme_color_override("font_color", Color(1, 0.65, 0.2))
 block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 effect_layer.add_child(block_label)
 for id in effects:
  var item := HBoxContainer.new()
  item.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var icon := TextureRect.new()
  icon.texture = textures[id]
  icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  icon.custom_minimum_size = Vector2(24, 36)
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var icon_material := ShaderMaterial.new()
  icon_material.shader = SHINE
  icon_material.set_shader_parameter("shine_enabled", false)
  icon.material = icon_material
  item.add_child(icon)
  var label := Label.new()
  label.add_theme_font_size_override("font_size", 14)
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  item.add_child(label)
  effect_row.add_child(item)
  indicators[id] = {"item": item, "label": label, "icon": icon}
 refresh()

func reset() -> void:
 blocked_seconds = 0.0
 for pickup in pickups:
  remove_child(pickup.sprite)
  pickup.sprite.queue_free()
 pickups.clear()
 for id in effects: effects[id] = 0.0
 refresh()

func active(id: String) -> bool:
 return float(effects.get(id, 0.0)) > 0.0

func drop_chance(enemy: Dictionary) -> float:
 if game.run_mode == "training" and not game.training.cards_enabled: return 0.0
 if enemy.boss: return 1.0 if game.run_mode in ["endless", "training"] else 0.0
 var progress := clampf(game.elapsed / 240.0, 0.0, 1.0)
 return lerpf(0.05, 0.01, progress) if enemy.tank else lerpf(0.01, 0.0025, progress)

func drop(enemy: Dictionary) -> void:
 if game.rng.randf() < drop_chance(enemy):
  spawn(IDS[game.rng.randi_range(0, IDS.size() - 1)], enemy.pos)

func spawn(id: String, world_position: Vector2) -> void:
 var sprite := Sprite2D.new()
 sprite.texture = textures[id]
 sprite.scale = Vector2.ONE * 0.5
 var shine := ShaderMaterial.new()
 shine.shader = SHINE
 sprite.material = shine
 add_child(sprite)
 var pickup := {"id": id, "pos": world_position, "age": 0.0, "sprite": sprite}
 pickups.append(pickup)
 refresh_pickup(pickup)

func activate(id: String) -> void:
 if blocked_seconds > 0: return
 game.sounds.play_card(id)
 if id == "ima":
  for gem in game.gems: gem["magnetized"] = true
 else:
  effects[id] = EFFECT_SECONDS
  if id == "furia": game.attack_timer = minf(game.attack_timer, game.effective_attack_delay())
 refresh()

func tick_effects(dt: float) -> void:
 blocked_seconds = maxf(0.0, blocked_seconds - dt)
 for id in effects: effects[id] = maxf(0.0, effects[id] - dt)

func block_activation() -> void:
 blocked_seconds = 5.0
 refresh()

func update_pickups(dt: float) -> void:
 for index in range(pickups.size() - 1, -1, -1):
  var pickup := pickups[index]
  pickup.age += dt
  var expired: bool = pickup.age >= FLOOR_SECONDS
  var rect := Rect2(pickup.pos - PICKUP_SIZE / 2, PICKUP_SIZE)
  var touching: bool = game.player.distance_to(game.player.clamp(rect.position, rect.end)) <= 14.0
  if expired or (touching and blocked_seconds <= 0):
   if touching and not expired: activate(pickup.id)
   remove_child(pickup.sprite)
   pickup.sprite.queue_free()
   pickups.remove_at(index)
 refresh()

func blink_visible(age: float) -> bool:
 return age < FLOOR_SECONDS - 5.0 or floori((age - (FLOOR_SECONDS - 5.0)) / 0.5) % 2 == 0

func refresh_pickup(pickup: Dictionary) -> void:
 var sprite: Sprite2D = pickup.sprite
 sprite.position = pickup.pos - game.camera_offset() + Vector2(0, sin(pickup.age * TAU / 1.8) * 4.0)
 sprite.visible = game.run_active and blink_visible(pickup.age)
 sprite.material.set_shader_parameter("age", pickup.age)
 sprite.material.set_shader_parameter("blocked", blocked_seconds > 0)

func refresh() -> void:
 for pickup in pickups: refresh_pickup(pickup)
 if not effect_row: return
 effect_row.visible = game.run_active
 for id in effects:
  indicators[id].icon.material.set_shader_parameter("blocked", blocked_seconds > 0)
  indicators[id].item.visible = active(id)
  indicators[id].label.text = "%s\n%.1f s" % [NAMES[id], effects[id]]
 effect_row.reset_size()
 var viewport := get_viewport_rect().size
 block_label.visible = game.run_active and blocked_seconds > 0
 block_label.text = "CARTAS BLOQUEADAS · %.1f s" % blocked_seconds
 block_label.position = Vector2((viewport.x - block_label.get_minimum_size().x) / 2, viewport.y - 82)
 effect_row.position = Vector2(maxf(22, (viewport.x - effect_row.size.x) / 2), viewport.y - 56)
