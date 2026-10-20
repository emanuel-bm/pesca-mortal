extends Node2D

const IDS := ["ima", "furia", "intangivel", "perfurante"]
const REPEAT_WEIGHT_FACTOR := 0.5
const MIN_REPEAT_WEIGHT := 0.000001
const NAMES := {"ima": "ÍMÃ", "furia": "FÚRIA", "intangivel": "INTANGÍVEL", "perfurante": "PERFURANTE"}
const EFFECT_SECONDS := 6.0
const FLOOR_SECONDS := 30.0
const PICKUP_SIZE := Vector2(32, 48)
const SHINE = preload("res://assets/cards/shine.gdshader")

var game: Node2D
var pickups: Array[Dictionary] = []
var last_drop_id := ""
var drop_streak := 0
var effects := {"furia": 0.0, "intangivel": 0.0, "perfurante": 0.0}
var textures: Dictionary = {}
var effect_layer: CanvasLayer
var effect_row: BoxContainer
var indicators: Dictionary = {}
var blocked_seconds := 0.0
var block_label: Label
var visual_age := 0.0
var magnet_visual_seconds := 0.0
var fury_burst_seconds := 0.0
var shield_impact_seconds := 0.0
var shield_impact_direction := Vector2.UP
var visuals := preload("res://scripts/card_visuals.gd").new()

func _ready() -> void:
 z_index = 5
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 for id in IDS: textures[id] = load("res://assets/cards/%s.png" % id)
 effect_layer = CanvasLayer.new()
 add_child(effect_layer)
 effect_row = BoxContainer.new()
 effect_row.position = Vector2(22, 186)
 effect_row.add_theme_constant_override("separation", 18)
 effect_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 effect_layer.add_child(effect_row)
 block_label = Label.new()
 block_label.add_theme_font_size_override("font_size", 20)
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
  label.add_theme_font_size_override("font_size", 20)
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  item.add_child(label)
  effect_row.add_child(item)
  indicators[id] = {"item": item, "label": label, "icon": icon}
 refresh()

func reset() -> void:
 last_drop_id = ""
 drop_streak = 0
 visual_age = 0.0
 magnet_visual_seconds = 0.0
 fury_burst_seconds = 0.0
 shield_impact_seconds = 0.0
 shield_impact_direction = Vector2.UP
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
 var species: String = enemy.get("species", "")
 var base := lerpf(0.05, 0.01, progress) if enemy.tank else lerpf(0.01, 0.0025, progress)
 if species == "pacu": base = lerpf(0.05, 0.02, progress)
 if species == "dourado": base = lerpf(0.10, 0.05, progress)
 return minf(1.0, base * (1.0 + game.luck / 100.0))

func drop(enemy: Dictionary) -> void:
 if game.rng.randf() < drop_chance(enemy):
  var count := 2 if enemy.get("species", "") == "pai_do_mato" else 1
  var first_id := ""
  for index in count:
   var offset := Vector2((index - 0.5) * 36.0, 0) if count == 2 else Vector2.ZERO
   var id := draw_drop_card(game.rng.randf(), first_id)
   spawn(id, enemy.pos + offset)
   first_id = id

func drop_card_weight(id: String) -> float:
 if id != last_drop_id: return 1.0
 # A positive floor keeps even very long streaks possible.
 return maxf(MIN_REPEAT_WEIGHT, pow(REPEAT_WEIGHT_FACTOR, drop_streak))

func draw_drop_card(roll: float, excluded_id: String = "") -> String:
 var total := 0.0
 var selected := ""
 for id in IDS:
  if id == excluded_id: continue
  total += drop_card_weight(id)
  selected = id
 var remaining := roll * total
 for id in IDS:
  if id == excluded_id: continue
  remaining -= drop_card_weight(id)
  if remaining < 0.0:
   selected = id
   break
 drop_streak = drop_streak + 1 if selected == last_drop_id else 1
 last_drop_id = selected
 return selected

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
 if id not in IDS: return
 if game.run_active:
  game.match_card_uses[id] = int(game.match_card_uses.get(id, 0)) + 1
 game.sounds.play_card(id)
 if id == "ima":
  magnet_visual_seconds = 1.0
  for gem in game.gems: gem["magnetized"] = true
 else:
  if not active(id): effect_row.move_child(indicators[id].item, effect_row.get_child_count() - 1)
  effects[id] = EFFECT_SECONDS * (1.0 + game.persistence / 100.0)
  if id == "furia": game.attack_timer = minf(game.attack_timer, game.effective_attack_delay())
 refresh()

func tick_effects(dt: float) -> void:
 visual_age += dt
 magnet_visual_seconds = maxf(0.0, magnet_visual_seconds - dt)
 fury_burst_seconds = maxf(0.0, fury_burst_seconds - dt)
 shield_impact_seconds = maxf(0.0, shield_impact_seconds - dt)
 blocked_seconds = maxf(0.0, blocked_seconds - dt)
 for id in effects:
  if game.run_active:
   game.match_card_seconds[id] = float(game.match_card_seconds.get(id, 0.0)) + minf(maxf(dt, 0.0), effects[id])
  effects[id] = maxf(0.0, effects[id] - dt)

func attack_feedback() -> void:
 if active("furia"): fury_burst_seconds = 0.24

func shield_feedback(source: Vector2) -> void:
 # Sustained contact must not restart the animation every simulation frame.
 if shield_impact_seconds > 0.0: return
 shield_impact_seconds = 0.32
 shield_impact_direction = (source - game.player).normalized()
 if shield_impact_direction.is_zero_approx(): shield_impact_direction = Vector2.UP

func player_tint() -> Color:
 if not active("perfurante"): return Color.WHITE
 var fade := minf(1.0, effects.perfurante / 0.25)
 var pulse := 0.5 + 0.5 * sin(floorf(visual_age * 20.0) / 20.0 * 7.0)
 return Color(1.0 + fade * (0.15 + pulse * 0.3), 1.0 + fade * (0.1 + pulse * 0.2), 1.0)

func draw_player_effects(canvas: Node2D, center: Vector2) -> void:
 var time := floorf(visual_age * 20.0) / 20.0
 if active("intangivel"):
  visuals.shield(canvas, center, time, shield_impact_seconds, shield_impact_direction, minf(1.0, effects.intangivel / 0.25))
 if active("perfurante"):
  visuals.piercing(canvas, center, time, minf(1.0, effects.perfurante / 0.25))
 if active("furia"):
  visuals.fury(canvas, center, time, fury_burst_seconds, -1.0 if game.facing_left else 1.0, minf(1.0, effects.furia / 0.25))
 if magnet_visual_seconds > 0.0:
  visuals.magnet(canvas, center, magnet_visual_seconds)

func block_activation() -> void:
 blocked_seconds = 5.0
 for id in effects: effects[id] = 0.0
 magnet_visual_seconds = 0.0
 fury_burst_seconds = 0.0
 shield_impact_seconds = 0.0
 for gem in game.gems: gem["magnetized"] = false
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
 return age < FLOOR_SECONDS - 5.0 or floori((age - (FLOOR_SECONDS - 5.0)) / 0.5) % 2 == 1

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
 effect_row.vertical = game.run_mode == "bosses"
 effect_row.add_theme_constant_override("separation", 8 if effect_row.vertical else 18)
 for id in effects:
  indicators[id].icon.material.set_shader_parameter("blocked", blocked_seconds > 0)
  indicators[id].item.visible = active(id)
  indicators[id].label.text = "%s\n%s s" % [NAMES[id], game.NUMBER_FORMAT.decimal(effects[id], 1, false)]
 effect_row.reset_size()
 var viewport := get_viewport_rect().size
 block_label.visible = game.run_active and blocked_seconds > 0
 block_label.text = "CARTAS BLOQUEADAS · %s s" % game.NUMBER_FORMAT.decimal(blocked_seconds, 1, false)
 block_label.position = Vector2((viewport.x - block_label.get_minimum_size().x) / 2, viewport.y - 82)
 effect_row.position = Vector2(maxf(22, (viewport.x - effect_row.size.x) / 2), viewport.y - 56)
 if game.run_mode == "bosses":
  var hud_bottom: float = game.hud.position.y + game.hud.get_combined_minimum_size().y
  effect_row.position = Vector2(game.hud.position.x, hud_bottom + 12)
  block_label.position = Vector2(effect_row.position.x, effect_row.position.y + effect_row.size.y + 8)
