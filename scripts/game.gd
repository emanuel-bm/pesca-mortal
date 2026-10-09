extends Node2D

const RUN_SECONDS := 300.0
const ENDLESS_FIRST_BOSS_TIME := 240.0
const ENDLESS_BOSS_INTERVAL := 120.0
const ARENA := Vector2(2400, 1800)
const ENEMY_SEPARATION_SCALE := 0.3
const MAX_ENEMIES := 1000
const MAX_HEALTH := 50.0
const XP_GROWTH_PER_LEVEL := 1.06
const XP_COLOR := Color(0.25, 0.65, 1.0)
const XP_ATTRACTION_SPEED := 630.0
const KNOCKBACK_SPEED := 420.0
const KNOCKBACK_DECELERATION := 1800.0
const MOVEMENT_MULTIPLIER := 1.2
const FASTEST_ENEMY_SPEED := 135.0 * MOVEMENT_MULTIPLIER
const BASE_PLAYER_SPEED := 190.0
const MINHOCAO = preload("res://scripts/minhocao.gd")
const FISH_VISUALS = preload("res://scripts/fish_visuals.gd")
const RUN_HISTORY = preload("res://scripts/run_history.gd")
const MAX_COLLECTION_RANGE := 500.0
const HEALTH_CAP := 500.0
const XP_BONUS_CAP := 100
const UPGRADES := ["damage", "rate", "shots", "speed", "magnet", "max_health", "xp_bonus"]
const LABELS := {
 "damage": ["Impacto", "+20% de dano"],
 "rate": ["Ritmo", "+20% de frequência de ataque"],
 "shots": ["Rajada", "+1 projétil por disparo"],
 "speed": ["Passo leve", "+4% de velocidade"],
 "magnet": ["Atração", "+40% de alcance de coleta"],
 "max_health": ["Vitalidade", "+20% de vida máxima"],
 "xp_bonus": ["Aprendizado", "+10% de ganho de XP"]
}

var rng := RandomNumberGenerator.new()
var player := ARENA / 2
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
const COLLISION_CELL_SIZE := 128.0
var enemy_grid: Dictionary = {}
var minimap_renderer: Node2D
var minimap_timer := 0.0
var minimap_view_size := Vector2.ZERO
var crowd_grid: Dictionary = {}
var crowd_cell_radius: Dictionary = {}
var crowd_candidates_checked := 0
var crowd_cells_skipped := 0
var crowd_positions := PackedVector2Array()
var crowd_radii := PackedFloat32Array()
var crowd_active := PackedByteArray()
var crowd_bosses := PackedByteArray()
var crowd_refresh_timer := 0.0
var crowd_max_radius := 21.0
const CROWD_UPDATES_PER_FRAME := 48
var crowd_cursor := 0
var crowd_window_start := 0
var crowd_batch_enabled := false
var crowd_recalculations := 0
const CROWD_CELL_SIZE := 32.0
var gems: Array[Dictionary] = []
var max_health := MAX_HEALTH
var xp_bonus := 0
var xp_remainder := 0
var health := MAX_HEALTH
var knockback_velocity := Vector2.ZERO
var elapsed := 0.0
var level := 1
var level_healing := 0
var xp := 0
var kills := 0
var damage := 20.0
var attack_delay := 0.65
var shot_count := 1
var speed := BASE_PLAYER_SPEED
var magnet := 85.0
var invulnerability := 0.0
var prevent_player_death := false
var spawn_timer := 0.0
var spawn_remainder := 0.0
var attack_timer := 0.0
var boss_spawned := false
var state := "menu"
var run_mode := "bosses"
var run_active := false
var run_recorded := false
var test_run := false
var training: Node
var cards: Node2D
var bosses_defeated := 0
var next_boss_time := ENDLESS_FIRST_BOSS_TIME
var endless_wave := 0
var run_history: Array = []
var player_totals := {"seconds": 0.0, "kills": 0, "levels": 0}
var history_path := "user://endless_runs.json"
var upgrade_levels: Dictionary = {}
var choices: Array[String] = []
var upgrade_buttons: Array[Button] = []
var selected_upgrade := 0
var menu_controls: Array[Control] = []
var menu_mouse_navigation := false
var hud: Label
var xp_bar: ProgressBar
var xp_label: Label
var health_bar: ProgressBar
var health_label: Label
var overlay: PanelContainer
var panel: VBoxContainer
const RESOLUTIONS := [Vector2i(960, 600), Vector2i(1152, 720), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
var selected_resolution := Vector2i(1152, 720)
var fullscreen := false
var settings_return := "menu"
var resolution_picker: OptionButton
var fullscreen_toggle: CheckButton
var show_fps := false
var quality_picker: OptionButton
var character_quality = preload("res://scripts/character_quality.gd").new()
var graphics_quality := 2
var fps_toggle: CheckButton
var fps_label: Label
var sounds: Node
var player_texture: Texture2D
var boss_texture: Texture2D
var facing_left := false
var modal_row: Control
var boss_records_panel: PanelContainer
var profile_panel: PanelContainer
var profile_label: Label
var profile_name_label: Label
var records_panel: PanelContainer
var stats_panel: PanelContainer
var stats_heading: Label
var stat_values: Dictionary = {}
var stat_names: Dictionary = {}
var stat_base_names: Dictionary = {}
var preview_upgrade := ""
var damage_numbers: Array[Dictionary] = []
var game_font: FontFile
var piranha_art: Dictionary = {}
var pintado_art: Dictionary = {}
var water_texture: Texture2D
var canoe_texture: Texture2D
var canoe_region: Rect2
var xp_texture: Texture2D
var xp_region: Rect2
var xp_outline_material: ShaderMaterial
var xp_renderer: Node2D
var water_surface: ColorRect
var water_material: ShaderMaterial
var water_time := 0.0
var wake_timer := 0.0
var water_ripples: Array[Dictionary] = []
var online: Node
var online_status_label: Label
var nickname_edit: LineEdit
var nickname_save_button: Button
var nickname_attempted := false
var records_personal := {"endless": false, "bosses": false}
var test_artifact_paths: Array[String] = []

func _ready() -> void:
 var cursor_layer := CanvasLayer.new()
 cursor_layer.layer = 100
 add_child(cursor_layer)
 var menu_cursor := preload("res://scripts/menu_cursor.gd").new()
 menu_cursor.game = self
 cursor_layer.add_child(menu_cursor)
 get_window().title = "Pesca Mortal " + str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
 rng.randomize()
 game_font = load("res://assets/fonts/Perfect DOS VGA 437 Win.ttf")
 game_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
 game_font.hinting = TextServer.HINTING_NONE
 game_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
 piranha_art = FISH_VISUALS.load_art("res://assets/piranha.png")
 pintado_art = FISH_VISUALS.load_art("res://assets/pintado-v2.png")
 if ResourceLoader.exists("res://assets/water.png"): water_texture = load("res://assets/water.png")
 if ResourceLoader.exists("res://assets/ventrescha-v3.png"):
  xp_texture = load("res://assets/ventrescha-v3.png")
  xp_region = Rect2(xp_texture.get_image().get_used_rect())
  xp_outline_material = ShaderMaterial.new()
  xp_outline_material.shader = load("res://assets/xp_outline.gdshader")
  xp_outline_material.set_shader_parameter("outline_color", XP_COLOR)
  xp_renderer = preload("res://scripts/xp_pickups.gd").new()
  xp_renderer.material = xp_outline_material
  xp_renderer.z_index = -1
  add_child(xp_renderer)
 if ResourceLoader.exists("res://assets/player-canoe.png"):
  canoe_texture = load("res://assets/player-canoe.png")
  canoe_region = Rect2(canoe_texture.get_image().get_used_rect())
 setup_water()
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 if ResourceLoader.exists("res://assets/player.png"): player_texture = load("res://assets/player.png")
 if ResourceLoader.exists("res://assets/minhocao.png"): boss_texture = load("res://assets/minhocao.png")
 sounds = preload("res://scripts/sound_effects.gd").new()
 add_child(sounds)
 character_quality.setup(self)
 load_display_settings()
 var automated_test := false
 for argument in OS.get_cmdline_args():
  if OS.has_feature("editor") and argument.begins_with("res://scripts/test_"): automated_test = true
 if automated_test:
  history_path = "user://test_boot_history_%d_%d.json" % [Time.get_ticks_usec(), get_instance_id()]
  test_artifact_paths.append(history_path)
 run_history = RUN_HISTORY.load_records(history_path)
 online = preload("res://scripts/online_ranking.gd").new()
 online.disabled = automated_test
 online.network_disabled = bool(get_tree().get_meta("offline_session", false))
 if automated_test:
  online.storage_path = "user://test_boot_online_%d_%d.json" % [Time.get_ticks_usec(), get_instance_id()]
  test_artifact_paths.append(online.storage_path)
 add_child(online)
 if bool(get_tree().get_meta("offline_session", false)): online.status = "Sessão offline. O ranking será sincronizado ao jogar online."
 online.changed.connect(online_changed)
 var layer := CanvasLayer.new()
 add_child(layer)
 hud = Label.new()
 hud.position = Vector2(22, 46)
 hud.add_theme_font_size_override("font_size", 16)
 layer.add_child(hud)
 xp_bar = ProgressBar.new()
 xp_bar.show_percentage = false
 xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 xp_bar.offset_bottom = 20
 var xp_background := StyleBoxFlat.new()
 xp_background.bg_color = Color(0.025, 0.07, 0.14)
 var xp_fill := StyleBoxFlat.new()
 xp_fill.bg_color = XP_COLOR
 xp_bar.add_theme_stylebox_override("background", xp_background)
 xp_bar.add_theme_stylebox_override("fill", xp_fill)
 layer.add_child(xp_bar)
 xp_label = Label.new()
 xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 xp_label.add_theme_font_size_override("font_size", 16)
 xp_label.custom_minimum_size.y = 20
 xp_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08))
 xp_label.add_theme_constant_override("outline_size", 0)
 xp_label.add_theme_color_override("font_color", Color.WHITE)
 layer.add_child(xp_label)
 health_bar = ProgressBar.new()
 health_bar.show_percentage = false
 health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 health_bar.max_value = max_health
 var health_background := StyleBoxFlat.new()
 health_background.bg_color = Color(0.025, 0.12, 0.045)
 var health_fill := StyleBoxFlat.new()
 health_fill.bg_color = Color(0.2, 0.7, 0.32)
 health_bar.add_theme_stylebox_override("background", health_background)
 health_bar.add_theme_stylebox_override("fill", health_fill)
 layer.add_child(health_bar)
 health_label = Label.new()
 health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 health_label.add_theme_font_size_override("font_size", 16)
 health_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.02))
 health_label.add_theme_constant_override("outline_size", 0)
 health_label.add_theme_color_override("font_color", Color.WHITE)
 layer.add_child(health_label)
 fps_label = Label.new()
 fps_label.add_theme_font_size_override("font_size", 16)
 fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layer.add_child(fps_label)
 var ui_root := Control.new()
 layer.add_child(ui_root)
 ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var center := CenterContainer.new()
 ui_root.add_child(center)
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 center.mouse_filter = Control.MOUSE_FILTER_IGNORE
 modal_row = Control.new()
 ui_root.add_child(modal_row)
 modal_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay = PanelContainer.new()
 overlay.custom_minimum_size = Vector2(620, 0)
 var background := StyleBoxFlat.new()
 background.bg_color = Color(0.07, 0.09, 0.13, 0.98)
 background.border_color = Color(0.23, 0.32, 0.43)
 background.set_border_width_all(2)
 background.set_corner_radius_all(12)
 overlay.add_theme_stylebox_override("panel", background)
 modal_row.add_child(overlay)
 var padding := MarginContainer.new()
 for side in ["left", "right", "top", "bottom"]:
  padding.add_theme_constant_override("margin_" + side, 24)
 overlay.add_child(padding)
 panel = VBoxContainer.new()
 panel.add_theme_constant_override("separation", 16)
 padding.add_child(panel)
 setup_stats_panel()
 training = preload("res://scripts/training_room.gd").new()
 training.game = self
 add_child(training)
 cards = preload("res://scripts/cards.gd").new()
 cards.game = self
 add_child(cards)
 show_menu()

func setup_water() -> void:
 if not water_texture: return
 var noise := FastNoiseLite.new()
 noise.seed = 417
 noise.noise_type = FastNoiseLite.TYPE_CELLULAR
 noise.frequency = 0.02
 noise.fractal_type = FastNoiseLite.FRACTAL_NONE
 noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
 var cells := NoiseTexture2D.new()
 cells.width = 512
 cells.height = 512
 cells.seamless = true
 cells.noise = noise
 water_material = ShaderMaterial.new()
 water_material.shader = load("res://assets/water.gdshader")
 water_material.set_shader_parameter("cell_texture", cells)
 water_material.set_shader_parameter("river_texture", water_texture)
 water_surface = ColorRect.new()
 water_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
 water_surface.z_index = -10
 water_surface.material = water_material
 water_surface.size = get_viewport_rect().size
 add_child(water_surface)

func update_water(dt: float) -> void:
 if graphics_quality > 0 and state in ["playing", "menu"]: water_time += dt
 if water_surface:
  water_surface.size = get_viewport_rect().size
  water_material.set_shader_parameter("view_size", get_viewport_rect().size)
  water_material.set_shader_parameter("camera_world", camera_offset())
  water_material.set_shader_parameter("water_time", water_time)
 if state != "playing" or graphics_quality == 0: return
 for i in range(water_ripples.size() - 1, -1, -1):
  water_ripples[i].age += dt
  if water_ripples[i].age > 1.3: water_ripples.remove_at(i)
 wake_timer -= dt
 if not movement().is_zero_approx() and wake_timer <= 0:
  water_ripples.append({"pos": player - movement() * 20, "age": 0.0})
  wake_timer = 0.22 if graphics_quality == 2 else 0.5

func title(text: String, size: int = 28) -> void:
 var label := Label.new()
 label.text = text
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size", 32 if size >= 28 else (24 if size >= 22 else 16))
 panel.add_child(label)

func button(text: String, callback: Callable) -> Button:
 var item := Button.new()
 item.text = text
 item.custom_minimum_size = Vector2(0, 54)
 item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var normal := StyleBoxFlat.new()
 normal.bg_color = Color(0.15, 0.23, 0.33)
 normal.set_corner_radius_all(6)
 item.add_theme_stylebox_override("normal", normal)
 style_menu_button(item)
 item.pressed.connect(callback)
 panel.add_child(item)
 return item

func style_menu_button(item: Button) -> void:
 var normal := item.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
 if normal == null:
  normal = StyleBoxFlat.new()
  normal.bg_color = Color.TRANSPARENT
  normal.set_corner_radius_all(6)
 normal.set_border_width_all(3)
 normal.border_color = Color.TRANSPARENT
 item.add_theme_stylebox_override("normal", normal)
 var highlight := normal.duplicate() as StyleBoxFlat
 highlight.bg_color = Color(0.22, 0.36, 0.5)
 highlight.border_color = Color(0.3, 1.0, 0.45)
 for style in ["hover", "focus", "hover_pressed"]:
  item.add_theme_stylebox_override(style, highlight)
 # Toggle buttons stay pressed while enabled; selection belongs to focus/hover.
 item.add_theme_stylebox_override("pressed", normal if item.toggle_mode else highlight)

func collect_menu_controls(parent: Node) -> void:
 for child in parent.get_children():
  if child is BaseButton or child is Slider or child is LineEdit:
   child.focus_mode = Control.FOCUS_ALL
   menu_controls.append(child)
   if child is Button: style_menu_button(child)
   elif child is Slider or child is LineEdit:
    var highlight := StyleBoxFlat.new()
    highlight.bg_color = Color.TRANSPARENT
    highlight.set_border_width_all(3)
    highlight.border_color = Color(0.3, 1.0, 0.45)
    highlight.set_corner_radius_all(6)
    child.add_theme_stylebox_override("focus", highlight)
   var hover_callback := focus_menu_hover.bind(child)
   if not child.mouse_entered.is_connected(hover_callback):
    child.mouse_entered.connect(hover_callback)
  else:
   collect_menu_controls(child)

func focus_menu_hover(item: Control) -> void:
 if menu_mouse_navigation: item.grab_focus()

func setup_menu_navigation() -> void:
 menu_controls.clear()
 if not overlay.visible or state in ["playing", "upgrade"]: return
 collect_menu_controls(panel)
 for i in menu_controls.size():
  var item := menu_controls[i]
  var previous := item.get_path_to(menu_controls[posmod(i - 1, menu_controls.size())])
  var next := item.get_path_to(menu_controls[(i + 1) % menu_controls.size()])
  item.focus_neighbor_top = previous
  item.focus_neighbor_bottom = next
  item.focus_previous = previous
  item.focus_next = next
 if not menu_controls.is_empty(): menu_controls[0].grab_focus()

func move_menu_focus(direction: int) -> void:
 var enabled: Array[Control] = []
 for item in menu_controls:
  if is_instance_valid(item) and item.is_visible_in_tree() and not (item is BaseButton and item.disabled):
   enabled.append(item)
 if enabled.is_empty(): return
 var index := enabled.find(get_viewport().gui_get_focus_owner())
 if index < 0: index = -1 if direction > 0 else 0
 enabled[posmod(index + direction, enabled.size())].grab_focus()

func clear_panel() -> void:
 panel.add_theme_constant_override("separation", 16)
 for side in ["left", "right", "top", "bottom"]:
  panel.get_parent().add_theme_constant_override("margin_" + side, 24)
 menu_controls.clear()
 menu_mouse_navigation = false
 setup_menu_navigation.call_deferred()
 overlay.custom_minimum_size.x = 620
 stats_panel.hide()
 if records_panel: records_panel.hide()
 if boss_records_panel: boss_records_panel.hide()
 preview_upgrade = ""
 for child in panel.get_children():
  panel.remove_child(child)
  child.queue_free()
 overlay.show()

func setup_stats_panel() -> void:
 stats_panel = PanelContainer.new()
 stats_panel.custom_minimum_size.x = 380
 stats_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 stats_panel.add_theme_stylebox_override("panel", overlay.get_theme_stylebox("panel"))
 modal_row.add_child(stats_panel)
 var margin := MarginContainer.new()
 for side in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + side, 20)
 stats_panel.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 14)
 margin.add_child(column)
 stats_heading = Label.new()
 stats_heading.text = "ATRIBUTOS DO PESCADOR (lv%d)" % level
 stats_heading.add_theme_font_size_override("font_size", 24)
 column.add_child(stats_heading)
 var names := {"max_health": "Vida máxima", "damage": "Dano", "rate": "Ataques por segundo", "shots": "Projéteis por ataque", "speed": "Velocidade", "magnet": "Alcance de coleta", "xp_bonus": "Bônus de XP"}
 for id in names:
  var row := HBoxContainer.new()
  column.add_child(row)
  var name_label := Label.new()
  name_label.text = names[id]
  stat_names[id] = name_label
  stat_base_names[id] = names[id]
  name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(name_label)
  var value := Label.new()
  value.custom_minimum_size = Vector2(144, 24)
  value.clip_text = true
  value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  row.add_child(value)
  stat_values[id] = value
 var hint := Label.new()
 hint.text = "Passe o mouse em uma melhoria\npara comparar os valores."
 hint.add_theme_font_size_override("font_size", 16)
 column.add_child(hint)
 stats_panel.hide()

func layout_modals() -> void:
 if not overlay: return
 var viewport := get_viewport_rect().size
 overlay.size = overlay.get_combined_minimum_size()
 stats_panel.size = stats_panel.get_combined_minimum_size()
 var factor := minf(1.0, (viewport.y - 40) / maxf(overlay.size.y, stats_panel.size.y if stats_panel.visible else 0.0))
 if stats_panel.visible or (records_panel and records_panel.visible):
  factor = minf(factor, (viewport.x - 96) / (overlay.size.x + stats_panel.size.x * 2))
 else:
  factor = minf(factor, (viewport.x - 40) / overlay.size.x)
 if records_panel and records_panel.visible:
  records_panel.size = records_panel.get_combined_minimum_size()
  factor = minf(factor, (viewport.x - 96) / (overlay.size.x + records_panel.size.x * 2))
  records_panel.scale = Vector2.ONE * factor
  records_panel.position = Vector2(24, (viewport.y - records_panel.size.y * factor) / 2)
 if boss_records_panel and boss_records_panel.visible:
  boss_records_panel.size = boss_records_panel.get_combined_minimum_size()
  factor = minf(factor, (viewport.y - 40) / boss_records_panel.size.y)
  factor = minf(factor, (viewport.x - 96) / (overlay.size.x + boss_records_panel.size.x * 2))
 if records_panel and records_panel.visible:
  factor = minf(factor, (viewport.y - 40) / records_panel.size.y)
  records_panel.scale = Vector2.ONE * factor
  records_panel.position = Vector2(24, (viewport.y - records_panel.size.y * factor) / 2)
 if boss_records_panel and boss_records_panel.visible:
  boss_records_panel.scale = Vector2.ONE * factor
  boss_records_panel.position = Vector2(viewport.x - 24 - boss_records_panel.size.x * factor, (viewport.y - boss_records_panel.size.y * factor) / 2)
 overlay.scale = Vector2.ONE * factor
 overlay.position = (viewport - overlay.size * factor) / 2
 if state == "lost":
  overlay.position.y = viewport.y - overlay.size.y * factor - 20
 stats_panel.scale = Vector2.ONE * factor
 stats_panel.position = Vector2(viewport.x - 24 - stats_panel.size.x * factor, (viewport.y - stats_panel.size.y * factor) / 2)

func projected_stats(id: String = "") -> Dictionary:
 var values := {"damage": damage, "rate": 1.0 / attack_delay, "shots": shot_count, "speed": speed, "magnet": magnet, "max_health": max_health, "xp_bonus": xp_bonus}
 match id:
  "damage": values.damage = damage * 1.20
  "rate": values.rate = 1.2 / attack_delay
  "shots": values.shots = shot_count + 1
  "speed": values.speed = speed * 1.04
  "magnet": values.magnet = minf(MAX_COLLECTION_RANGE, magnet * 1.4)
  "max_health": values.max_health = maxf(max_health, minf(HEALTH_CAP, max_health * 1.20))
  "xp_bonus": values.xp_bonus = mini(XP_BONUS_CAP, xp_bonus + 10)
 return values

func format_stat(id: String, value: float) -> String:
 if id == "rate": return ("%.2f" % value).replace(".", ",")
 var text := ("+%d%%" % roundi(value)) if id == "xp_bonus" else str(roundi(value))
 if (id == "magnet" and value >= MAX_COLLECTION_RANGE) or (id == "max_health" and value >= HEALTH_CAP) or (id == "xp_bonus" and value >= XP_BONUS_CAP): text += " (MAX)"
 return text

func update_stats_preview(id: String = "") -> void:
 stats_heading.text = "ATRIBUTOS DO PESCADOR (lv%d)" % level
 preview_upgrade = id
 var current := projected_stats()
 var projected := projected_stats(id)
 for key in current:
  var ability_level := int(upgrade_levels.get(key, 0)) + 1
  stat_names[key].text = stat_base_names[key] + (" (%d)" % ability_level if ability_level > 1 else "")
  var label: Label = stat_values[key]
  label.text = format_stat(key, current[key])
  label.remove_theme_color_override("font_color")
  if label.text.ends_with(" (MAX)"):
   label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
  if key == id:
   label.text += " → " + format_stat(key, projected[key])
   label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0) if projected[key] >= current[key] and format_stat(key, projected[key]).ends_with(" (MAX)") else Color(0.4, 1, 0.65))

func clear_stats_preview(id: String) -> void:
 if preview_upgrade == id: update_stats_preview()

func setup_profile_panel() -> void:
 profile_panel = PanelContainer.new()
 profile_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 profile_panel.add_theme_stylebox_override("panel", overlay.get_theme_stylebox("panel"))
 modal_row.get_parent().add_child(profile_panel)
 var margin := MarginContainer.new()
 for side in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + side, 14)
 profile_panel.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 6)
 margin.add_child(column)
 var heading := HBoxContainer.new()
 heading.add_theme_constant_override("separation", 12)
 column.add_child(heading)
 profile_name_label = Label.new()
 profile_name_label.add_theme_font_size_override("font_size", 16)
 profile_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 heading.add_child(profile_name_label)
 var edit := TextureButton.new()
 edit.texture_normal = preload("res://assets/icons/edit-profile.svg")
 edit.custom_minimum_size = Vector2(24, 24)
 edit.ignore_texture_size = true
 edit.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
 edit.tooltip_text = "Editar perfil"
 edit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 edit.pressed.connect(show_nickname)
 heading.add_child(edit)
 profile_label = Label.new()
 profile_label.add_theme_font_size_override("font_size", 16)
 profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
 column.add_child(profile_label)

func show_menu() -> void:
 sounds.start_calm_music()
 record_run("menu")
 run_active = false
 state = "menu"
 if online.nickname().is_empty() and not online.endpoint.is_empty() and not bool(get_tree().get_meta("offline_session", false)):
  show_nickname()
  return
 player_totals = RUN_HISTORY.totals(run_history)
 sounds.reset()
 clear_panel()
 title("PESCA MORTAL")
 if bool(get_tree().get_meta("offline_session", false)): title("Jogando offline", 18)
 title("WASD / setas: mover · Ataque automático\nColete ventrechas para evoluir · ESC: pausar", 18)
 button("Modo infinito", start_run.bind("endless"))
 button("Modo por chefões", start_run.bind("bosses"))
 button("Sala de treino", start_run.bind("training"))
 records_personal = {"endless": false, "bosses": false}
 show_records_panel()
 show_boss_records_panel()
 button("Histórico de partidas", show_history)
 button("Configurações", show_settings)
 button("Fechar jogo", quit_game)
 online.synchronize()

func show_nickname() -> void:
 nickname_attempted = false
 state = "nickname"
 clear_panel()
 title("NOME DE JOGADOR")
 title("Escolha um nome único para aparecer no ranking.\n3 a 20 letras sem acentos, números ou _.", 18)
 online_status_label = Label.new()
 online_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 online_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 panel.add_child(online_status_label)
 nickname_edit = LineEdit.new()
 nickname_edit.max_length = 20
 nickname_edit.text = online.nickname()
 nickname_edit.placeholder_text = "Seu nome de jogador"
 nickname_edit.custom_minimum_size.y = 48
 panel.add_child(nickname_edit)
 nickname_save_button = button("Salvar nome", save_nickname)
 var actions := HBoxContainer.new()
 actions.add_theme_constant_override("separation", 14)
 panel.add_child(actions)
 panel.remove_child(nickname_save_button)
 nickname_save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var saving_style := StyleBoxFlat.new()
 saving_style.bg_color = Color(0.02, 0.02, 0.02)
 saving_style.set_corner_radius_all(6)
 nickname_save_button.add_theme_stylebox_override("disabled", saving_style)
 nickname_edit.text_submitted.connect(func(_text: String): save_nickname())
 if not online.nickname().is_empty() or online.endpoint.is_empty() or bool(get_tree().get_meta("offline_session", false)):
  var back := button("Voltar", show_menu)
  panel.remove_child(back)
  back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  actions.add_child(back)
 actions.add_child(nickname_save_button)
 online_changed()
 nickname_edit.grab_focus()

func save_nickname() -> void:
 if online.busy: return
 nickname_attempted = true
 online.set_nickname(nickname_edit.text)

func online_changed() -> void:
 if state == "nickname":
  if is_instance_valid(online_status_label):
   online_status_label.text = online.status
   online_status_label.visible = nickname_attempted and not online.busy and not online.status.is_empty() and online.status not in ["Nome salvo.", "Ranking atualizado.", "Recorde sincronizado."] and not online.status.begins_with("Atualizando ranking")
  if is_instance_valid(nickname_save_button):
   nickname_save_button.disabled = online.busy
   nickname_save_button.text = ("Salvando..." if online.action in ["register", "rename"] else "Carregando...") if online.busy else "Salvar nome"
  if nickname_attempted and not online.nickname().is_empty() and online.status == "Nome salvo.": show_menu()
 elif state == "menu":
  show_records_panel()
  show_boss_records_panel()

func show_records_panel() -> void:
 if records_panel:
  modal_row.remove_child(records_panel)
  records_panel.queue_free()
 records_panel = make_records_panel("RECORDES · INFINITO", "endless")

func show_boss_records_panel() -> void:
 if boss_records_panel:
  modal_row.remove_child(boss_records_panel)
  boss_records_panel.queue_free()
 boss_records_panel = make_records_panel("RECORDES · CHEFÕES", "bosses")

func select_records_tab(mode: String, personal: bool) -> void:
 records_personal[mode] = personal
 if mode == "endless": show_records_panel()
 else: show_boss_records_panel()

func make_records_panel(heading_text: String, mode: String) -> PanelContainer:
 var target := PanelContainer.new()
 target.custom_minimum_size.x = 380
 target.add_theme_stylebox_override("panel", overlay.get_theme_stylebox("panel"))
 modal_row.add_child(target)
 var margin := MarginContainer.new()
 for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
 target.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 14)
 margin.add_child(column)
 var heading := Label.new()
 heading.text = heading_text
 heading.add_theme_font_size_override("font_size", 24)
 column.add_child(heading)
 var tabs := HBoxContainer.new()
 column.add_child(tabs)
 for personal in [false, true]:
  var tab := Button.new()
  tab.text = "Pessoal" if personal else "Global"
  tab.toggle_mode = true
  tab.button_pressed = records_personal[mode] == personal
  tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tab.pressed.connect(select_records_tab.bind(mode, personal))
  tabs.add_child(tab)
 var personal: bool = records_personal[mode]
 var records: Array = (RUN_HISTORY.ranked(run_history) if mode == "endless" else RUN_HISTORY.boss_ranked(run_history)) if personal else online.rankings.get(mode, [])
 var grid := GridContainer.new()
 grid.columns = 4
 grid.add_theme_constant_override("h_separation", 16)
 grid.add_theme_constant_override("v_separation", 12)
 column.add_child(grid)
 for column_name in ["Jogador", "Level", "Tempo", "Eliminações"]: history_cell(grid, column_name)
 var ranked: Array = records
 for index in mini(10, ranked.size()):
  var record: Dictionary = ranked[index]
  history_cell(grid, online.nickname() if personal else str(record.get("nickname", "")))
  history_cell(grid, str(int(record.get("level", 0))))
  history_cell(grid, RUN_HISTORY.time_text(record.seconds))
  history_cell(grid, str(int(record.kills)))
 if ranked.is_empty():
  var empty := Label.new()
  empty.text = "Nenhuma partida registrada." if personal else "Nenhum recorde global recebido."
  empty.add_theme_font_size_override("font_size", 16)
  column.add_child(empty)
 if not personal:
  var reload_button := Button.new()
  reload_button.text = "Carregando..." if online.busy else "Recarregar"
  reload_button.disabled = online.busy
  reload_button.pressed.connect(online.synchronize)
  column.add_child(reload_button)

 return target

func history_cell(grid: GridContainer, text: String) -> void:
 var cell := Label.new()
 cell.text = text
 cell.add_theme_font_size_override("font_size", 16)
 cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 grid.add_child(cell)

func show_history() -> void:
 state = "history"
 clear_panel()
 overlay.custom_minimum_size.x = 860
 title("HISTÓRICO DE PARTIDAS")
 title("Partidas mais recentes primeiro", 18)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(0, 280)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(scroll)
 var grid := GridContainer.new()
 grid.columns = 5
 grid.add_theme_constant_override("h_separation", 20)
 grid.add_theme_constant_override("v_separation", 12)
 grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(grid)
 for heading in ["Data", "Personagem", "Modo", "Tempo total", "Eliminações"]: history_cell(grid, heading)
 for record in RUN_HISTORY.chronological(run_history):
  var date_parts: PackedStringArray = record.date.split("T")
  var date := str(date_parts[0])
  var parts := date.split("-")
  if parts.size() == 3: date = "%s/%s/%s" % [parts[2], parts[1], parts[0]]
  if date_parts.size() > 1: date += " " + date_parts[1]
  history_cell(grid, date)
  history_cell(grid, RUN_HISTORY.character_text(record))
  history_cell(grid, "Infinito" if record.mode == "endless" else "Chefão")
  history_cell(grid, RUN_HISTORY.time_text(record.seconds))
  history_cell(grid, str(record.kills))
 if run_history.is_empty(): title("Nenhuma partida registrada.", 18)
 button("Voltar à tela inicial", show_menu)

func record_run(reason: String) -> void:
 if not run_active or run_recorded or test_run: return
 run_recorded = true
 if elapsed <= 0: return
 var previous_rank: Array = RUN_HISTORY.ranked(run_history) if run_mode == "endless" else RUN_HISTORY.boss_ranked(run_history)
 var previous: Dictionary = previous_rank[0] if not previous_rank.is_empty() else {}
 var record := {"seconds": elapsed, "kills": kills, "date": Time.get_datetime_string_from_system(), "reason": reason, "character": "Pescador", "level": level, "mode": run_mode}
 run_history.append(record)
 run_history = RUN_HISTORY.chronological(run_history)
 player_totals = RUN_HISTORY.totals(run_history)
 if RUN_HISTORY.save_records(run_history, history_path) != OK:
  push_warning("Não foi possível salvar o histórico local.")
  return
 if (run_mode == "endless" or (run_mode == "bosses" and reason == "won")) and online.better(record, previous):
  online.queue_record(record)

func quit_game() -> void:
 record_run("quit")
 get_tree().quit()

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST: record_run("quit")

func _exit_tree() -> void:
 for path in test_artifact_paths:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func load_display_settings() -> void:
 var config := ConfigFile.new()
 if config.load("user://display.cfg") == OK:
  var saved: Vector2i = config.get_value("display", "resolution", selected_resolution)
  if saved in RESOLUTIONS: selected_resolution = saved
  fullscreen = bool(config.get_value("display", "fullscreen", false))
  show_fps = bool(config.get_value("display", "show_fps", false))
  graphics_quality = clampi(int(config.get_value("display", "quality", 2)), 0, 2)
 apply_graphics_quality()
 apply_display_settings(false)

func apply_display_settings(save: bool = true) -> void:
 var window := get_window()
 window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
 if not fullscreen:
  var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
  var target := selected_resolution
  if usable.size.x > 0 and usable.size.y > 0:
   target = target.min(usable.size - Vector2i(48, 80)).max(Vector2i(640, 400))
  window.size = target
  if usable.size.x > 0: window.position = usable.position + (usable.size - target) / 2
 if save:
  var config := ConfigFile.new()
  config.set_value("display", "resolution", selected_resolution)
  config.set_value("display", "fullscreen", fullscreen)
  config.set_value("display", "show_fps", show_fps)
  config.set_value("display", "quality", graphics_quality)
  config.save("user://display.cfg")

func apply_graphics_quality() -> void:
 if water_material: water_material.set_shader_parameter("quality", graphics_quality)
 water_ripples.clear()
 damage_numbers.clear()
 minimap_timer = 0.0
 if xp_renderer:
  xp_renderer.material = xp_outline_material if graphics_quality > 0 else null
  xp_renderer.queue_redraw()
 queue_redraw()

func floating_number_limit() -> int:
 return [0, 60, 180][graphics_quality]

func show_settings() -> void:
 settings_return = state
 state = "settings"
 clear_panel()
 title("CONFIGURAÇÕES")
 resolution_picker = OptionButton.new()
 resolution_picker.custom_minimum_size.y = 48
 for i in RESOLUTIONS.size():
  var resolution: Vector2i = RESOLUTIONS[i]
  resolution_picker.add_item("%d × %d" % [resolution.x, resolution.y])
  if resolution == selected_resolution: resolution_picker.select(i)
 panel.add_child(resolution_picker)
 quality_picker = OptionButton.new()
 for quality_name in ["Qualidade baixa", "Qualidade média", "Qualidade ultra"]:
  quality_picker.add_item(quality_name)
 quality_picker.select(graphics_quality)
 panel.add_child(quality_picker)
 fullscreen_toggle = CheckButton.new()
 fullscreen_toggle.text = "Tela cheia (resolução do monitor)"
 fullscreen_toggle.button_pressed = fullscreen
 panel.add_child(fullscreen_toggle)
 fps_toggle = CheckButton.new()
 fps_toggle.text = "Mostrar contador de FPS"
 fps_toggle.button_pressed = show_fps
 panel.add_child(fps_toggle)
 for id in sounds.VOLUME_NAMES:
  var row := HBoxContainer.new()
  var label := Label.new()
  label.text = sounds.VOLUME_NAMES[id]
  label.custom_minimum_size.x = 208
  label.add_theme_font_size_override("font_size", 16)
  row.add_child(label)
  var slider := HSlider.new()
  slider.min_value = 0
  slider.max_value = 100
  slider.step = 1
  slider.value = sounds.volumes[id] * 100
  slider.custom_minimum_size = Vector2(140, 24)
  slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(slider)
  var amount := Label.new()
  amount.custom_minimum_size.x = 48
  amount.add_theme_font_size_override("font_size", 16)
  amount.text = "%d%%" % slider.value
  row.add_child(amount)
  slider.value_changed.connect(func(value: float):
   sounds.set_volume(id, value / 100.0)
   amount.text = "%d%%" % value
  )
  if id not in ["master", "music"]:
   var preview := Button.new()
   preview.text = "Ouvir"
   preview.pressed.connect(sounds.play_effect.bind(id, 1.0, 1.0))
   row.add_child(preview)
  panel.add_child(row)
 var actions := HBoxContainer.new()
 actions.add_theme_constant_override("separation", 14)
 panel.add_child(actions)
 var save := button("Salvar", save_settings_from_ui)
 var back := button("Voltar", leave_settings)
 for item in [save, back]:
  panel.remove_child(item)
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  actions.add_child(item)

func save_settings_from_ui() -> void:
 graphics_quality = quality_picker.selected
 apply_graphics_quality()
 selected_resolution = RESOLUTIONS[resolution_picker.selected]
 fullscreen = fullscreen_toggle.button_pressed
 show_fps = fps_toggle.button_pressed
 apply_display_settings()
 leave_settings()

func leave_settings() -> void:
 if settings_return == "paused": show_pause()
 else: show_menu()

func show_pause() -> void:
 state = "paused"
 update_cursor_visibility()
 clear_panel()
 overlay.custom_minimum_size.x = 480
 stats_panel.show()
 update_stats_preview()
 title("Pausado")
 if run_mode == "training":
  stats_panel.hide()
  training.select_tab(training.selected_tab)
 button("Continuar", resume)
 button("Configurações", show_settings)
 button("Recomeçar", restart_run)
 button("Voltar à tela inicial", show_menu)

func restart_run() -> void:
 start_run(run_mode)

func start_run(mode: String = "bosses") -> void:
 if mode not in ["endless", "bosses", "training"]: return
 sounds.start_calm_music()
 record_run("restart")
 run_mode = mode
 run_active = true
 run_recorded = false
 test_run = mode == "training"
 bosses_defeated = 0
 next_boss_time = ENDLESS_FIRST_BOSS_TIME
 endless_wave = 0
 stats_panel.hide()
 sounds.reset()
 player = ARENA / 2
 enemies.clear()
 crowd_refresh_timer = 0.0
 crowd_cursor = 0
 crowd_batch_enabled = false
 minimap_timer = 0.0
 bullets.clear()
 cards.reset()
 damage_numbers.clear()
 water_ripples.clear()
 wake_timer = 0.0
 gems.clear()
 max_health = MAX_HEALTH
 health = max_health
 xp_bonus = 0
 xp_remainder = 0
 prevent_player_death = false
 knockback_velocity = Vector2.ZERO
 elapsed = 0.0
 level = 1
 level_healing = 0
 xp = 0
 kills = 0
 damage = 20.0
 attack_delay = 0.65
 shot_count = 1
 speed = BASE_PLAYER_SPEED
 magnet = 85.0
 invulnerability = 0.0
 spawn_timer = 0.0
 spawn_remainder = 0.0
 attack_timer = 0.0
 boss_spawned = false
 upgrade_levels.clear()
 state = "playing"
 if records_panel: records_panel.hide()
 if boss_records_panel: boss_records_panel.hide()
 overlay.hide()

 if mode == "training":
  prevent_player_death = true
  training.reset()

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  menu_mouse_navigation = true
 elif event is InputEventKey and event.pressed:
  menu_mouse_navigation = false
 if event is InputEventKey and event.pressed and not event.echo and event.alt_pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
  fullscreen = not fullscreen
  apply_display_settings()
  if state == "settings" and is_instance_valid(fullscreen_toggle): fullscreen_toggle.button_pressed = fullscreen
  get_viewport().set_input_as_handled()
  return
 if overlay.visible and state != "upgrade" and event is InputEventKey and event.pressed:
  var focused := get_viewport().gui_get_focus_owner()
  var popup_open: bool = focused is OptionButton and focused.get_popup().visible
  if not popup_open and event.keycode in [KEY_UP, KEY_DOWN]:
   move_menu_focus(-1 if event.keycode == KEY_UP else 1)
   get_viewport().set_input_as_handled()
   return
 if state != "upgrade" or not event is InputEventKey or not event.pressed or event.echo or event.ctrl_pressed: return
 var key: int = event.keycode
 if key in [KEY_UP, KEY_LEFT]:
  select_upgrade(posmod(selected_upgrade - 1, choices.size()))
 elif key in [KEY_DOWN, KEY_RIGHT]:
  select_upgrade((selected_upgrade + 1) % choices.size())
 elif key in [KEY_ENTER, KEY_KP_ENTER]:
  choose_upgrade(choices[selected_upgrade])
 elif key in [KEY_1, KEY_2, KEY_3]:
  var index := key - KEY_1
  if index < choices.size(): choose_upgrade(choices[index])
 else: return
 get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:
  return
 if event.keycode == KEY_ESCAPE:
  if state == "playing":
   show_pause()
  elif state == "paused":
   resume()
  elif state == "settings":
   leave_settings()
 if state == "upgrade" and not event.ctrl_pressed:
  var index := -1
  if event.keycode == KEY_1: index = 0
  if event.keycode == KEY_2: index = 1
  if event.keycode == KEY_3: index = 2
  if index >= 0 and index < choices.size():
   choose_upgrade(choices[index])

func resume() -> void:
 state = "playing"
 update_cursor_visibility()
 if training: training.update_interaction(false)
 if records_panel: records_panel.hide()
 if boss_records_panel: boss_records_panel.hide()
 overlay.hide()
 stats_panel.hide()

func xp_needed() -> int:
 return ceili((5 + (level - 1) * 3) * pow(XP_GROWTH_PER_LEVEL, level - 1))

func movement() -> Vector2:
 var direction := Vector2.ZERO
 if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): direction.x -= 1
 if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): direction.x += 1
 if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): direction.y -= 1
 if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): direction.y += 1
 return direction.normalized()

func update_cursor_visibility() -> void:
 var desired := Input.MOUSE_MODE_HIDDEN
 if Input.mouse_mode != desired: Input.mouse_mode = desired

func _process(delta: float) -> void:
 update_cursor_visibility()
 update_minimap(delta)
 if xp_renderer: xp_renderer.queue_redraw()
 layout_modals()
 if state == "playing":
  update_game(minf(delta, 0.05))
 cards.refresh()
 update_water(minf(delta, 0.05))
 var show_player_bars := run_active or state in ["won", "lost"]
 for item in [health_bar, health_label, xp_bar, xp_label]:
  item.visible = show_player_bars
 xp_bar.position = Vector2(0, 20)
 xp_bar.size = Vector2(get_viewport_rect().size.x, 20)
 xp_bar.max_value = xp_needed()
 xp_bar.value = current_xp()
 xp_label.size = xp_bar.size
 xp_label.position = xp_bar.position
 xp_label.text = "%s / %d XP" % [format_xp(current_xp()), xp_needed()]
 health_bar.size = xp_bar.size
 health_bar.value = maxf(0, health)
 health_label.size = health_bar.size
 health_bar.max_value = max_health
 health_label.text = "%d / %d HP" % [maxi(0, int(health)), roundi(max_health)]
 hud.text = "%02d:%02d    ELIMINAÇÕES %d" % [int(elapsed) / 60, int(elapsed) % 60, kills]
 if run_mode == "endless" and state in ["playing", "upgrade", "paused"]:
  var remaining := maxi(0, ceili(next_boss_time - elapsed))
  hud.text += "\nINFINITO · PRÓXIMOS CHEFÕES EM %02d:%02d" % [floori(remaining / 60.0), remaining % 60]
 if not profile_panel: setup_profile_panel()
 profile_panel.visible = not run_active and state not in ["nickname", "lost"]
 hud.visible = run_active
 if not run_active:
  hud.text = "ELIMINAÇÕES TOTAIS %d\nTEMPO TOTAL %s\nNÍVEIS CONQUISTADOS %d" % [player_totals.kills, RUN_HISTORY.time_text(player_totals.seconds), player_totals.levels]
  hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  hud.size = hud.get_minimum_size()
  hud.position = Vector2(get_viewport_rect().size.x - hud.size.x - 22, 70)
  profile_name_label.text = online.nickname()
  profile_label.text = hud.text
  profile_panel.size = profile_panel.get_combined_minimum_size()
  var profile_scale := minf(1.0, (get_viewport_rect().size.x - 44) / profile_panel.size.x)
  profile_panel.scale = Vector2.ONE * profile_scale
  profile_panel.position = Vector2(22, 22)
 else:
  hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  hud.position = Vector2(22, 46)
 if run_active:
  var fish_count := 0
  var visible_fish := 0
  var visible_area := Rect2(camera_offset(), get_viewport_rect().size)
  for enemy in enemies:
   if enemy.boss or enemy.hp <= 0: continue
   fish_count += 1
   if test_run and visible_area.grow(enemy.radius + 2).has_point(enemy.pos): visible_fish += 1
  hud.text += "\nPEIXES %d" % fish_count
  if test_run: hud.text += "\nPEIXES VISÍVEIS %d" % visible_fish
 fps_label.visible = show_fps
 fps_label.text = "%d FPS" % Engine.get_frames_per_second()
 var map_area := minimap_world_rect()
 var map_shown := minimap_renderer != null and minimap_renderer.visible
 fps_label.position = Vector2(map_area.position.x - 22 - 150 if map_shown else get_viewport_rect().size.x - 172, 46)
 fps_label.size.x = 150
 if boss_spawned and run_active and state in ["playing", "paused", "upgrade", "settings"]:
  var count := 0
  var action := ""
  for enemy in enemies:
   if enemy.boss:
    count += 1
    if action.is_empty(): action = {"burrow": "MERGULHOU", "tracking": "SAIA DA MARCA", "emerge_warning": "VAI EMERGIR!", "dash_warning": "SAIA DA FAIXA!", "dash": "INVESTIDA", "exposed": "EXPOSTO — ATAQUE!"}[enemy.phase]
  if count > 0:
   hud.text += "\nMINHOCÃO x%d" % count
   if run_mode == "bosses": hud.text += " · " + action
 queue_redraw()

func update_game(dt: float) -> void:
 cards.tick_effects(dt)
 update_damage_numbers(dt)
 elapsed += dt
 if not boss_spawned and run_mode in ["bosses", "endless"]:
  var first_boss_time: float = RUN_SECONDS if run_mode == "bosses" else next_boss_time
  sounds.prepare_boss_music(first_boss_time - elapsed)
 invulnerability = maxf(0.0, invulnerability - dt)
 player += (movement() * effective_speed() + knockback_velocity) * dt
 if absf(movement().x) > 0.1: facing_left = movement().x < 0
 knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECELERATION * dt)
 player = player.clamp(Vector2(18, 18), ARENA - Vector2(18, 18))
 if run_mode == "bosses" and elapsed >= RUN_SECONDS and not boss_spawned:
  boss_spawned = true
  spawn_enemy(true)
 if run_mode != "training" or training.auto_spawn: spawn_timer -= dt
 if spawn_timer <= 0 and (run_mode != "training" or training.auto_spawn):
  spawn_timer += 1.0
  var amount := fish_spawn_rate() + spawn_remainder
  var count := floori(amount)
  spawn_remainder = amount - count
  for spawn_index in mini(count, maxi(0, MAX_ENEMIES - enemies.size())): spawn_enemy(false)
 attack_timer -= dt
 if attack_timer <= 0 and not enemies.is_empty():
  fire()
  attack_timer = effective_attack_delay()
 update_crowd_snapshot(dt)
 begin_crowd_step()
 for enemy_index in enemies.size():
  var enemy: Dictionary = enemies[enemy_index]
  var old_position: Vector2 = enemy.pos
  var special_boss_movement := false
  if enemy.boss:
   var previous_phase: String = enemy.phase
   var emerged: bool = MINHOCAO.update(enemy, dt, player, ARENA)
   if emerged: sounds.play_boss_emergence()
   if enemy.phase == "dash" and previous_phase != "dash": sounds.play_boss_dash()
   special_boss_movement = emerged or previous_phase != "exposed" or enemy.phase != "exposed"
   if emerged and player.distance_to(enemy.pos) < MINHOCAO.EMERGENCE_RADIUS + 14:
    receive_hit(enemy.contact, enemy.pos)
   if not MINHOCAO.vulnerable(enemy): continue
  var toward: Vector2 = player - enemy.pos
  enemy.facing_left = toward.x < 0
  var desired_position: Vector2 = enemy.pos if enemy.boss else enemy.pos + toward.normalized() * enemy.speed * dt
  enemy.pos = old_position
  if enemy.boss:
   if special_boss_movement: enemy.pos = desired_position
   else: move_enemy_if_free(enemy_index, desired_position)
  else: pursue_player(enemy_index, dt)
  if invulnerability <= 0 and enemy_overlaps(enemy, player, 14):
   receive_hit(enemy.contact, enemy.pos)
  if state != "playing": return
 rebuild_projectile_grid()
 for i in range(bullets.size() - 1, -1, -1):
  var projectile := bullets[i]
  var previous_position: Vector2 = projectile.pos
  projectile.pos += projectile.velocity * dt
  projectile.life -= dt
  var hit := false
  if bool(projectile.get("piercing", false)):
   if not projectile.has("remaining_damage"): projectile.remaining_damage = effective_damage()
   var steps := maxi(1, ceili(previous_position.distance_to(projectile.pos) / 8.0))
   for step in range(steps + 1):
    var point := previous_position.lerp(projectile.pos, float(step) / steps)
    var target := projectile_target(point, projectile.hit_enemies)
    while target >= 0 and projectile.remaining_damage > 0.0:
     var enemy := enemies[target]
     var consumed: float = minf(projectile.remaining_damage, enemy.hp)
     hit_with_spear(enemy, consumed)
     projectile.remaining_damage = maxf(0.0, projectile.remaining_damage - consumed)
     projectile.hit_enemies.append(enemy)
     target = projectile_target(point, projectile.hit_enemies)
    if projectile.remaining_damage <= 0.0:
     hit = true
     break
  else:
   var target := projectile_target(projectile.pos)
   if target >= 0:
    hit_with_spear(enemies[target])
    hit = true
  var outside: bool = not Rect2(Vector2.ZERO, ARENA).has_point(projectile.pos)
  if hit or projectile.life <= 0 or outside: bullets.remove_at(i)
 for i in range(enemies.size() - 1, -1, -1):
  var enemy := enemies[i]
  enemy.flash = maxf(0, enemy.flash - dt)
  if enemy.hp <= 0:
   sounds.play_death()
   if enemy.boss:
    if run_mode == "bosses":
     finish(true)
     return
    buff_endless_enemies()
   gems.append({"pos": enemy.pos, "xp": enemy_xp_reward(enemy)})
   cards.drop(enemy)
   kills += 1
   enemies.remove_at(i)
 if run_mode == "endless": spawn_endless_bosses()
 for i in range(gems.size() - 1, -1, -1):
  var distance: float = gems[i].pos.distance_to(player)
  if distance < magnet or bool(gems[i].get("magnetized", false)):
   gems[i].pos = gems[i].pos.move_toward(player, XP_ATTRACTION_SPEED * dt)
  if gems[i].pos.distance_to(player) < 20:
   var reward := float(gems[i].xp) * (100 + xp_bonus) / 100.0
   collect_xp(int(gems[i].xp))
   add_xp_number(gems[i].pos, reward)
   gems.remove_at(i)
 cards.update_pickups(dt)
 show_pending_level_up()

func effective_speed() -> float:
 return speed * (1.2 if cards.active("furia") else 1.0)

func effective_attack_delay() -> float:
 return attack_delay / (1.5 if cards.active("furia") else 1.0)

func effective_damage() -> float:
 return damage * (1.5 if cards.active("furia") else 1.0)

func hit_with_spear(enemy: Dictionary, amount: float = -1.0) -> void:
 if amount < 0.0: amount = effective_damage()
 enemy.hp -= amount
 add_damage_number(enemy.pos - Vector2(0, enemy.radius + 8), amount)
 enemy.flash = 0.12

func show_pending_level_up() -> void:
 if state == "playing" and xp >= xp_needed():
  xp -= xp_needed()
  level += 1
  level_healing = roundi(max_health - health)
  health = max_health
  sounds.play_effect("level", 1.0, 1.0)
  show_upgrades()

func fish_spawn_rate() -> float:
 return floorf(maxf(2.0, elapsed / 60.0) * 1.5)

func spawn_endless_bosses() -> void:
 while elapsed >= next_boss_time:
  endless_wave += 1
  var count := endless_wave
  for index in count: spawn_enemy(true)
  boss_spawned = true
  next_boss_time += ENDLESS_BOSS_INTERVAL

func buff_endless_enemies() -> void:
 bosses_defeated += 1
 for enemy in enemies:
  if enemy.hp <= 0: continue
  enemy.hp *= 1.05
  enemy.max_hp *= 1.05
  enemy.speed *= 1.05
  enemy.contact *= 1.05
  enemy["stat_multiplier"] = float(enemy.get("stat_multiplier", 1.0)) * 1.05

func separation_radius(enemy: Dictionary) -> float:
 # Boss sprite is 140 px wide; fish sprites use radius * 2.
 return (70.0 if enemy.boss else float(enemy.radius)) * ENEMY_SEPARATION_SCALE

func update_crowd_snapshot(dt: float) -> void:
 crowd_refresh_timer -= dt
 if crowd_refresh_timer <= 0 or crowd_positions.size() != enemies.size():
  rebuild_crowd_grid()
  crowd_refresh_timer = 1.0 / 30.0

func begin_crowd_step() -> void:
 crowd_recalculations = 0
 crowd_batch_enabled = true
 if enemies.is_empty(): return
 crowd_window_start = crowd_cursor % enemies.size()
 crowd_cursor = (crowd_window_start + mini(CROWD_UPDATES_PER_FRAME, enemies.size())) % enemies.size()

func pursue_player(index: int, dt: float) -> void:
 var enemy: Dictionary = enemies[index]
 if dt <= 0: return
 var fish_speed: float = enemy.speed
 var remaining: float = float(enemy.get("separation_timer", 0.0)) - dt
 var desired: Vector2
 if enemy.has("desired_velocity"): desired = enemy.desired_velocity
 else: desired = (player - enemy.pos).normalized() * fish_speed
 var eligible := not crowd_batch_enabled or posmod(index - crowd_window_start, enemies.size()) < CROWD_UPDATES_PER_FRAME
 if remaining <= 0 and eligible:
  crowd_recalculations += 1
  var direction: Vector2 = (player - enemy.pos).normalized()
  var separation := crowd_separation(index, direction)
  desired = ((direction + separation * 1.4) * fish_speed).limit_length(fish_speed)
  enemy["desired_velocity"] = desired
  enemy["separation_timer"] = 0.06 + (index % 5) * 0.004
 else:
  enemy["separation_timer"] = remaining
 var velocity: Vector2
 if enemy.has("crowd_velocity"): velocity = enemy.crowd_velocity
 else: velocity = (player - enemy.pos).normalized() * fish_speed
 velocity = velocity.move_toward(desired, maxf(1.0, fish_speed) * 5.0 * dt).limit_length(fish_speed)
 enemy["crowd_velocity"] = velocity
 enemy.pos = (Vector2(enemy.pos) + velocity * dt).clamp(Vector2(6, 6), ARENA - Vector2(6, 6))
 if absf(velocity.x) > 2: enemy.facing_left = velocity.x < 0

func crowd_separation(index: int, direction: Vector2) -> Vector2:
 var origin: Vector2 = enemies[index].pos
 var positions := crowd_positions
 var radii := crowd_radii
 var active := crowd_active
 var bosses := crowd_bosses
 var boss_group := bosses[index]
 var radius: float = radii[index]
 var base_influence := radius + 6.0
 var padding := radius + crowd_max_radius + 6.0
 var minimum := Vector2i(((origin - Vector2.ONE * padding) / CROWD_CELL_SIZE).floor())
 var maximum := Vector2i(((origin + Vector2.ONE * padding) / CROWD_CELL_SIZE).floor())
 var force := Vector2.ZERO
 var checked := 0
 var skipped := 0
 var count := 0
 var sideways := direction.orthogonal() * (0.45 if index % 2 == 0 else -0.45)
 for y in range(minimum.y, maximum.y + 1):
  for x in range(minimum.x, maximum.x + 1):
   var cell := Vector2i(x, y)
   if not crowd_grid.has(cell): continue
   var reach: float = radius + float(crowd_cell_radius.get(cell, crowd_max_radius)) + 6.0
   var cell_start := Vector2(cell) * CROWD_CELL_SIZE
   var closest := origin.clamp(cell_start, cell_start + Vector2.ONE * CROWD_CELL_SIZE)
   if origin.distance_squared_to(closest) > reach * reach + 0.0001:
    skipped += 1
    continue
   for other_index: int in crowd_grid[cell]:
    checked += 1
    if other_index == index or active[other_index] == 0 or bosses[other_index] != boss_group: continue
    var difference := origin - positions[other_index]
    var influence := base_influence + radii[other_index]
    var distance_squared := difference.length_squared()
    if distance_squared >= influence * influence: continue
    var distance := sqrt(distance_squared)
    var away := difference / distance if distance > 0.01 else Vector2.from_angle(fmod(float(index * 127), TAU))
    var pressure := 1.0 - distance / influence
    force += away * pressure
    if away.dot(direction) < -0.7: force += sideways * pressure
    count += 1
    if count >= 16:
     crowd_candidates_checked += checked
     crowd_cells_skipped += skipped
     return force.limit_length(1.5)
 crowd_candidates_checked += checked
 crowd_cells_skipped += skipped
 return force.limit_length(1.5)

func crowd_neighbors(index: int, destination: Vector2, extra: float = 0.0, max_count: int = 0) -> PackedVector3Array:
 var result := PackedVector3Array()
 var enemy: Dictionary = enemies[index]
 var origin: Vector2 = enemy.pos
 var radius := separation_radius(enemy)
 var travel := origin.distance_to(destination)
 var padding := radius + 21.0 + extra
 var minimum := Vector2i(((origin.min(destination) - Vector2.ONE * padding) / CROWD_CELL_SIZE).floor())
 var maximum := Vector2i(((origin.max(destination) + Vector2.ONE * padding) / CROWD_CELL_SIZE).floor())
 for y in range(minimum.y, maximum.y + 1):
  for x in range(minimum.x, maximum.x + 1):
   for other_index: int in crowd_grid.get(Vector2i(x, y), []):
    if other_index == index: continue
    if crowd_active[other_index] == 0 or crowd_bosses[other_index] != crowd_bosses[index]: continue
    var distance := radius + crowd_radii[other_index]
    var other_pos: Vector2 = crowd_positions[other_index]
    if absf(other_pos.x - origin.x) > distance + extra + travel or absf(other_pos.y - origin.y) > distance + extra + travel: continue
    result.append(Vector3(other_pos.x, other_pos.y, distance))
    if max_count > 0 and result.size() >= max_count: return result
 return result

func move_enemy_if_free(index: int, destination: Vector2, neighbors: PackedVector3Array = PackedVector3Array(), prepared: bool = false) -> bool:
 var enemy: Dictionary = enemies[index]
 var origin: Vector2 = enemy.pos
 if destination.x < 6 or destination.y < 6 or destination.x > ARENA.x - 6 or destination.y > ARENA.y - 6: return false
 if destination.is_equal_approx(origin): return true
 if not prepared and neighbors.is_empty(): neighbors = crowd_neighbors(index, destination)
 for neighbor in neighbors:
  var other_pos := Vector2(neighbor.x, neighbor.y)
  var distance_squared := neighbor.z * neighbor.z
  var start_distance := origin.distance_squared_to(other_pos)
  if start_distance < distance_squared - 0.001:
   if destination.distance_squared_to(other_pos) <= start_distance: return false
   continue
  var closest := Geometry2D.get_closest_point_to_segment(other_pos, origin, destination)
  if closest.distance_squared_to(other_pos) < distance_squared - 0.001: return false
 var old_cell := Vector2i((origin / CROWD_CELL_SIZE).floor())
 var new_cell := Vector2i((destination / CROWD_CELL_SIZE).floor())
 if old_cell != new_cell:
  if crowd_grid.has(old_cell): crowd_grid[old_cell].erase(index)
  if not crowd_grid.has(new_cell): crowd_grid[new_cell] = []
  crowd_grid[new_cell].append(index)
  crowd_cell_radius[new_cell] = maxf(float(crowd_cell_radius.get(new_cell, 0.0)), crowd_radii[index])
 enemy.pos = destination
 crowd_positions[index] = destination
 return true

func rebuild_enemy_grid() -> void:
 rebuild_crowd_grid()
 rebuild_projectile_grid()

func rebuild_projectile_grid() -> void:
 enemy_grid.clear()
 for index in enemies.size():
  var cell := Vector2i((Vector2(enemies[index].pos) / COLLISION_CELL_SIZE).floor())
  if not enemy_grid.has(cell): enemy_grid[cell] = []
  enemy_grid[cell].append(index)

func rebuild_crowd_grid() -> void:
 crowd_grid.clear()
 crowd_cell_radius.clear()
 crowd_max_radius = 0.0
 crowd_positions.resize(enemies.size())
 crowd_radii.resize(enemies.size())
 crowd_active.resize(enemies.size())
 crowd_bosses.resize(enemies.size())
 for index in enemies.size():
  crowd_bosses[index] = int(enemies[index].boss)
  crowd_positions[index] = enemies[index].pos
  crowd_radii[index] = separation_radius(enemies[index])
  crowd_max_radius = maxf(crowd_max_radius, crowd_radii[index])
  crowd_active[index] = int(enemies[index].hp > 0 and (not enemies[index].boss or MINHOCAO.vulnerable(enemies[index])))
  var cell := Vector2i((crowd_positions[index] / CROWD_CELL_SIZE).floor())
  if not crowd_grid.has(cell): crowd_grid[cell] = []
  crowd_grid[cell].append(index)
  crowd_cell_radius[cell] = maxf(float(crowd_cell_radius.get(cell, 0.0)), crowd_radii[index])

func projectile_target(point: Vector2, excluded: Array = []) -> int:
 var cell := Vector2i((point / COLLISION_CELL_SIZE).floor())
 var best := enemies.size()
 # The largest hitbox plus spear padding fits inside one neighboring cell.
 for y in range(cell.y - 1, cell.y + 2):
  for x in range(cell.x - 1, cell.x + 2):
   for index in enemy_grid.get(Vector2i(x, y), []):
    if index >= best: continue
    var enemy := enemies[index]
    if enemy in excluded: continue
    if enemy.hp <= 0 or (enemy.boss and not MINHOCAO.vulnerable(enemy)): continue
    if enemy_overlaps(enemy, point, 5): best = index
 return best if best < enemies.size() else -1

func enemy_overlaps(enemy: Dictionary, point: Vector2, padding: float) -> bool:
 if enemy.boss:
  var reach: float = enemy.radius + padding
  return point.distance_squared_to(enemy.pos) < reach * reach
 return FISH_VISUALS.overlaps(pintado_art if enemy.tank else piranha_art, enemy, point, padding)

func current_xp() -> float:
 return xp + xp_remainder / 100.0

func format_xp(amount: float) -> String:
 return ("%.1f" % amount).trim_suffix(".0")

func collect_xp(base_amount: int) -> int:
 # Keep fractional XP across pickups: ten 1-XP pickups at +10% grant 11 XP.
 var scaled := base_amount * (100 + xp_bonus) + xp_remainder
 var gained := floori(float(scaled) / 100.0)
 xp_remainder = scaled % 100
 xp += gained
 return gained

func enemy_xp_reward(enemy: Dictionary) -> int:
 if enemy.get("tank", false): return 5
 return maxi(1, roundi(pow(float(enemy.radius) / 13.0, 2)))

func add_damage_number(position: Vector2, amount: float) -> void:
 var limit := floating_number_limit()
 if limit == 0: return
 if damage_numbers.size() >= limit: damage_numbers.pop_front()
 var text := str(roundi(amount))
 damage_numbers.append({"pos": position + Vector2((damage_numbers.size() % 5 - 2) * 8, 0), "text": text, "life": 0.7})

func add_xp_number(position: Vector2, amount: float) -> void:
 var limit := floating_number_limit()
 if limit == 0: return
 if damage_numbers.size() >= limit: damage_numbers.pop_front()
 damage_numbers.append({"pos": position + Vector2((damage_numbers.size() % 5 - 2) * 8, -24), "text": "+%d XP" % floori(amount), "life": 0.7, "color": XP_COLOR, "font_size": 12})

func update_damage_numbers(dt: float) -> void:
 for i in range(damage_numbers.size() - 1, -1, -1):
  damage_numbers[i].life -= dt
  damage_numbers[i].pos.y -= 42 * dt
  if damage_numbers[i].life <= 0: damage_numbers.remove_at(i)

func receive_hit(amount: float, source: Vector2) -> void:
 if invulnerability > 0 or cards.active("intangivel"): return
 health -= amount
 if prevent_player_death: health = maxf(1.0, health)
 sounds.play_hurt()
 invulnerability = 0.8
 var away := (player - source).normalized()
 if away.is_zero_approx(): away = Vector2.LEFT
 knockback_velocity = away * KNOCKBACK_SPEED
 if health <= 0: finish(false)

func spawn_enemy(boss: bool) -> void:
 var angle := rng.randf_range(0, TAU)
 var position := (player + Vector2.from_angle(angle) * 680).clamp(Vector2(30, 30), ARENA - Vector2(30, 30))
 var tank := not boss and elapsed > 30 and rng.randf() < 0.25
 var hp := (100.0 if tank else 30.0) * (1 + elapsed / 300.0)
 if boss: hp = 32000.0
 var enemy := {"pos": position, "hp": hp, "max_hp": hp, "radius": 38.0 if boss else (44.0 if tank else 13.0), "speed": 120.0 if boss else (65.0 * MOVEMENT_MULTIPLIER * 1.1 if tank else (105.0 + elapsed * 0.1) * MOVEMENT_MULTIPLIER), "contact": 25.0 if boss else (15.0 if tank else 10.0), "boss": boss, "tank": tank, "flash": 0.0}
 var multiplier := pow(1.05, bosses_defeated) if run_mode == "endless" else 1.0
 enemy["stat_multiplier"] = multiplier
 for stat in ["hp", "max_hp", "speed", "contact"]: enemy[stat] *= multiplier
 if boss: MINHOCAO.initialize(enemy)
 enemies.append(enemy)
 if boss: sounds.announce_boss()

func fire() -> void:
 var nearest := player
 var best := INF
 for enemy in enemies:
  if enemy.boss and not MINHOCAO.vulnerable(enemy): continue
  var distance := player.distance_squared_to(enemy.pos)
  if distance < best:
   best = distance
   nearest = enemy.pos
 if best == INF: return
 sounds.play_shot()
 var direction := (nearest - player).normalized()
 if direction.is_zero_approx(): direction = Vector2.RIGHT
 for i in shot_count:
  var angle := (i - (shot_count - 1) / 2.0) * 0.13
  var piercing: bool = cards.active("perfurante")
  bullets.append({"pos": player, "velocity": direction.rotated(angle) * 650, "life": ARENA.length() / 650.0 + 0.1 if piercing else 1.6, "piercing": piercing, "remaining_damage": effective_damage(), "hit_enemies": []})

func show_upgrades() -> void:
 state = "upgrade"
 clear_panel()
 overlay.custom_minimum_size.x = 480
 title("NÍVEL %d" % level)
 title("Escolha uma melhoria", 20)
 stats_panel.show()
 update_stats_preview()
 choices.clear()
 upgrade_buttons.clear()
 var available: Array[String] = []
 for id in UPGRADES:
  if id == "magnet" and magnet >= MAX_COLLECTION_RANGE: continue
  if id == "max_health" and max_health >= HEALTH_CAP: continue
  if id == "xp_bonus" and xp_bonus >= XP_BONUS_CAP: continue
  available.append(id)
 while choices.size() < 3 and not available.is_empty():
  var index := rng.randi_range(0, available.size() - 1)
  choices.append(available[index])
  available.remove_at(index)
 if choices.is_empty():
  health = minf(max_health, health + 25)
  resume()
  return
 for i in choices.size():
  var id := choices[i]
  var option := button("%d · %s — %s" % [i + 1, LABELS[id][0], LABELS[id][1]], choose_upgrade.bind(id))
  upgrade_buttons.append(option)
  option.mouse_entered.connect(select_upgrade.bind(i))
  option.focus_entered.connect(update_stats_preview.bind(id))
 select_upgrade(0)

func select_upgrade(index: int) -> void:
 if state != "upgrade" or upgrade_buttons.is_empty(): return
 selected_upgrade = index
 upgrade_buttons[index].grab_focus()
 update_stats_preview(choices[index])

func choose_upgrade(id: String) -> void:
 upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
 var next := projected_stats(id)
 damage = next.damage
 attack_delay = 1.0 / next.rate
 shot_count = next.shots
 speed = next.speed
 magnet = next.magnet
 health = minf(next.max_health, health + next.max_health - max_health)
 max_health = next.max_health
 xp_bonus = int(next.xp_bonus)
 health_bar.max_value = max_health
 resume()
 show_pending_level_up()

func finish(won: bool) -> void:
 record_run("death" if not won else "won")
 run_active = false
 state = "won" if won else "lost"
 clear_panel()
 title("VITÓRIA!" if won else "FIM DE PARTIDA")
 if not won:
  var living_fish := 0
  var living_bosses := 0
  for enemy in enemies:
   if enemy.hp <= 0: continue
   if enemy.boss: living_bosses += 1
   else: living_fish += 1
  panel.add_theme_constant_override("separation", 8)
  overlay.custom_minimum_size.x = 480
  for side in ["left", "right"]:
   panel.get_parent().add_theme_constant_override("margin_" + side, 16)
  for side in ["top", "bottom"]:
   panel.get_parent().add_theme_constant_override("margin_" + side, 8)
  title("%s · Tempo: %02d:%02d" % [online.nickname(), int(elapsed) / 60, int(elapsed) % 60], 16)
  title("Nível: %d · Eliminações: %d" % [level, kills], 16)
  title("Peixes vivos: %d · Chefes vivos: %d" % [living_fish, living_bosses], 16)
  var actions := HBoxContainer.new()
  actions.add_theme_constant_override("separation", 12)
  panel.add_child(actions)
  for item in [button("Jogar novamente", restart_run), button("Voltar à tela inicial", show_menu)]:
   panel.remove_child(item)
   actions.add_child(item)
   item.custom_minimum_size.y = 48
   item.add_theme_font_size_override("font_size", 16)
   item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  profile_panel.hide()
  layout_modals()
  queue_redraw()
  return
 title("Tempo: %02d:%02d\nNível: %d · Eliminações: %d" % [int(elapsed) / 60, int(elapsed) % 60, level, kills], 22)
 button("Jogar novamente", restart_run)
 button("Voltar à tela inicial", show_menu)

func camera_offset() -> Vector2:
 return player - get_viewport_rect().size / 2

func minimap_rect() -> Rect2:
 var side := minf(180.0, get_viewport_rect().size.x * 0.18)
 return Rect2(Vector2(get_viewport_rect().size.x - side - 22, 74), Vector2.ONE * side)

func minimap_world_rect() -> Rect2:
 var outer := minimap_rect().grow(-10)
 var dimensions := ARENA * minf(outer.size.x / ARENA.x, outer.size.y / ARENA.y)
 return Rect2(Vector2(get_viewport_rect().size.x - dimensions.x - 22, 46), dimensions)

func minimap_point(world: Vector2) -> Vector2:
 var area := minimap_world_rect()
 return area.position + world.clamp(Vector2.ZERO, ARENA) / ARENA * area.size

func update_minimap(dt: float) -> void:
 if not minimap_renderer:
  minimap_renderer = preload("res://scripts/minimap.gd").new()
  minimap_renderer.z_index = 20
  add_child(minimap_renderer)
 var show_map := state in ["playing", "paused", "upgrade", "won", "lost"]
 var was_visible: bool = minimap_renderer.visible
 minimap_renderer.visible = show_map
 if not show_map: return
 minimap_timer -= dt
 var view_size := get_viewport_rect().size
 if minimap_timer <= 0 or not was_visible or view_size != minimap_view_size:
  minimap_timer = [0.2, 0.1, 0.05][graphics_quality]
  minimap_view_size = view_size
  minimap_renderer.refresh(self)

func draw_spear(canvas: CanvasItem, tip: Vector2, direction: Vector2) -> void:
 var side := direction.orthogonal()
 canvas.draw_line(tip - direction * 18.75, tip - direction * 3.75, Color(0.7, 0.44, 0.19), 2.25)
 canvas.draw_colored_polygon(PackedVector2Array([tip + direction * 5.25, tip - direction * 4.5 + side * 3, tip - direction * 2.25, tip - direction * 4.5 - side * 3]), Color(0.85, 0.93, 0.89))

func _draw() -> void:
 var offset := camera_offset()
 var viewport := get_viewport_rect().size
 var visible_world := Rect2(offset, viewport)
 if water_texture and not water_surface:
  const TILE_SIZE := 256
  for x in range(int(floor(offset.x / TILE_SIZE)), int(ceil((offset.x + viewport.x) / TILE_SIZE))):
   for y in range(int(floor(offset.y / TILE_SIZE)), int(ceil((offset.y + viewport.y) / TILE_SIZE))):
    draw_texture_rect(water_texture, Rect2(Vector2(x, y) * TILE_SIZE - offset, Vector2.ONE * TILE_SIZE), false, Color(0.65, 0.65, 0.65))
 elif not water_surface:
  for x in range(0, int(ARENA.x) + 1, 80):
   draw_line(Vector2(x, 0) - offset, Vector2(x, ARENA.y) - offset, Color(0.09, 0.11, 0.14))
  for y in range(0, int(ARENA.y) + 1, 80):
   draw_line(Vector2(0, y) - offset, Vector2(ARENA.x, y) - offset, Color(0.09, 0.11, 0.14))
 draw_rect(Rect2(-offset, ARENA), Color(0.3, 0.4, 0.5), false, 3)
 for ripple in water_ripples:
  draw_arc(ripple.pos - offset, 12 + ripple.age * 27, 0, TAU, 32, Color(0.18, 0.35, 0.33, (1.0 - ripple.age / 1.3) * 0.25), 1.5)
 for projectile in bullets:
  if not visible_world.grow(26).has_point(projectile.pos): continue
  var tip: Vector2 = projectile.pos - offset
  var direction: Vector2 = projectile.velocity.normalized()
  draw_spear(self, tip, direction)
 if graphics_quality < 2: character_quality.draw_fish(self, visible_world, offset)
 for enemy in enemies:
  if graphics_quality < 2 and character_quality.fish_batches.size() == 2 and not enemy.boss: continue
  if not enemy.boss and not visible_world.grow(enemy.radius + 2).has_point(enemy.pos): continue
  var position: Vector2 = enemy.pos - offset
  var radius: float = enemy.radius
  var color := Color(0.7, 0.3, 1) if enemy.boss else (Color(1, 0.55, 0.15) if enemy.tank else Color(0.95, 0.25, 0.3))
  if enemy.flash > 0: color = Color.WHITE
  if enemy.boss:
   if enemy.phase in ["tracking", "emerge_warning"]:
    var mark: Vector2 = enemy.target - offset
    var mark_color := Color(1, 0.68, 0.1) if enemy.phase == "tracking" else Color(1, 0.25, 0.15)
    draw_circle(mark, MINHOCAO.EMERGENCE_RADIUS, Color(mark_color, 0.18))
    draw_arc(mark, MINHOCAO.EMERGENCE_RADIUS, 0, TAU, 64, mark_color, 4)
    var progress: float = 1.0 - enemy.timer / float(enemy.get("phase_duration", MINHOCAO.EMERGENCE_WARNING_TIME))
    draw_arc(mark, MINHOCAO.EMERGENCE_RADIUS * clampf(progress, 0.05, 1), 0, TAU, 48, mark_color, 2)
   if enemy.phase in ["dash_warning", "dash"]:
    var start: Vector2 = enemy.dash_start - offset
    var end: Vector2 = enemy.dash_end - offset
    var side: Vector2 = (end - start).normalized().orthogonal() * MINHOCAO.DASH_WIDTH
    draw_colored_polygon(PackedVector2Array([start + side, end + side, end - side, start - side]), Color(1, 0.35, 0.12, 0.22))
    draw_line(start + side, end + side, Color(1, 0.55, 0.1), 3)
    draw_line(start - side, end - side, Color(1, 0.55, 0.1), 3)
   if MINHOCAO.vulnerable(enemy):
    if boss_texture:
     draw_texture_rect(character_quality.texture_for("boss", graphics_quality, boss_texture), Rect2(position - Vector2(70, 85), Vector2(140, 140)), false, Color.WHITE if enemy.flash <= 0 else Color(1.7, 1.7, 1.7))
    else: draw_rect(Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2), color)
    if run_mode in ["endless", "training"]:
     var bar_position := (position + Vector2(-50, maxf(60, radius + 8))).round()
     draw_rect(Rect2(bar_position - Vector2.ONE, Vector2(102, 8)), Color(0.05, 0.04, 0.08))
     draw_rect(Rect2(bar_position, Vector2(100, 6)), Color(0.2, 0.1, 0.25))
     draw_rect(Rect2(bar_position, Vector2(100 * clampf(enemy.hp / enemy.max_hp, 0, 1), 6)), Color(0.7, 0.3, 1))
     var hp_text := "%d / %d" % [ceili(maxf(0, enemy.hp)), ceili(enemy.max_hp)]
     var hp_position := bar_position + Vector2(50 - game_font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x / 2, 18)
     draw_string(game_font, hp_position.round(), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
  else:
   var art: Dictionary = pintado_art if enemy.tank else piranha_art
   if not art.is_empty():
    var sprite_size: Vector2 = FISH_VISUALS.size_for(art, radius)
    draw_set_transform(position, 0, Vector2(-1 if enemy.get("facing_left", false) else 1, 1))
    draw_texture_rect_region(art.texture, Rect2(-sprite_size / 2, sprite_size), Rect2(art.region), Color(1.7, 1.7, 1.7) if enemy.flash > 0 else Color.WHITE)
    draw_set_transform(Vector2.ZERO)
   else: draw_rect(Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2), color)
 var boss_health := 0.0
 var boss_max_health := 0.0
 for enemy in enemies:
  if enemy.boss:
   boss_health += maxf(0, enemy.hp)
   boss_max_health += enemy.max_hp
 if run_mode == "bosses" and boss_max_health > 0:
  draw_rect(Rect2(Vector2(230, viewport.y - 35), Vector2(viewport.x - 460, 14)), Color(0.2, 0.1, 0.25))
  draw_rect(Rect2(Vector2(230, viewport.y - 35), Vector2((viewport.x - 460) * boss_health / boss_max_health, 14)), Color(0.7, 0.3, 1))
 var number_font: Font = game_font
 for number in damage_numbers:
  if not visible_world.grow(80).has_point(number.pos): continue
  var alpha: float = clampf(number.life / 0.25, 0, 1)
  var text_position: Vector2 = number.pos - offset
  var font_size: int = number.get("font_size", 24)
  text_position.x -= number_font.get_string_size(number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2
  if graphics_quality == 2: draw_string_outline(number_font, text_position, number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2 if font_size == 12 else 4, Color(0.03, 0.02, 0.01, alpha))
  var tint: Color = number.get("color", Color(1, 0.88, 0.45))
  tint.a = alpha
  draw_string(number_font, text_position, number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
 var player_color := Color(0.3, 0.75, 1)
 if invulnerability > 0 and int(invulnerability * 15) % 2 == 0: player_color = Color.WHITE
 if canoe_texture:
  var canoe_size := canoe_region.size / maxf(canoe_region.size.x, canoe_region.size.y) * 72
  draw_set_transform(viewport / 2, 0, Vector2(-1 if facing_left else 1, 1))
  var canoe_art: Texture2D = character_quality.texture_for("canoe", graphics_quality, canoe_texture)
  var region := canoe_region if graphics_quality == 2 else Rect2(Vector2.ZERO, canoe_art.get_size())
  draw_texture_rect_region(canoe_art, Rect2(-canoe_size / 2, canoe_size), region, Color(2, 2, 2) if player_color == Color.WHITE else Color.WHITE)
  draw_set_transform(Vector2.ZERO)
 elif player_texture:
  draw_set_transform(viewport / 2, 0, Vector2(-1 if facing_left else 1, 1))
  draw_texture_rect(character_quality.texture_for("player", graphics_quality, player_texture), Rect2(Vector2(-32, -32), Vector2(64, 64)), false, Color(2, 2, 2) if player_color == Color.WHITE else Color.WHITE)
  draw_set_transform(Vector2.ZERO)
 else: draw_rect(Rect2(viewport / 2 - Vector2(14, 14), Vector2(28, 28)), player_color)
 if state == "lost":
  draw_arc(viewport / 2, 44, 0, TAU, 48, Color(1, 0.45, 0.35), 2, true)
