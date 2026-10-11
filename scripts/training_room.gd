extends CanvasLayer

var game: Node
var development_debug_frame: PanelContainer
var frame: PanelContainer
var auto_spawn := false
var cards_enabled := false
var controls: PanelContainer
var editor: PanelContainer
var values: Dictionary = {}
var stat_buttons: Array[Button] = []
var tabs: HBoxContainer
var tab_buttons: Array[Button] = []
var selected_tab := 0
var automatic: CheckButton
var immortality: CheckButton
var cards_toggle: CheckButton
const STATS := {
 "health": ["Vida atual", 10.0, 1.0, 500.0],
 "max_health": ["Vida máxima", 10.0, 1.0, 500.0],
 "damage": ["Dano", 5.0, 1.0, 10000.0],
 "rate": ["Ataques / segundo", 0.2, 0.2, 20.0],
 "shot_count": ["Projéteis", 1.0, 1.0, 100.0],
 "speed": ["Velocidade", 10.0, 10.0, 1000.0],
 "magnet": ["Alcance de coleta", 20.0, 0.0, 2400.0],
 "xp_bonus": ["Bônus de XP (%)", 10.0, 0.0, 1000.0],
 "level": ["Nível", 1.0, 1.0, 100.0]
}
const ACTIONS := {
 KEY_F1: ["F1 · +100 Piranhas", "piranha"],
 KEY_F2: ["F2 · +100 Pintados", "pintado"],
 KEY_F3: ["F3 · Invocar Minhocão", "boss"],
 KEY_F4: ["F4 · Matar todos os peixes", "fish_clear"],
 KEY_F5: ["F5 · Limpar todos os inimigos", "clear"],
 KEY_F6: ["F6 · Avançar 1 minuto", "time"],
 KEY_F7: ["F7 · Subir um nível", "level"],
 KEY_F8: ["F8 · Restaurar vida", "heal"],
 KEY_F9: ["F9 · Invocar quatro cartas", "cards"],
 KEY_F10: ["F10 · +10 Dourados", "dourado"],
 KEY_F11: ["F11 · +10 Pacus", "pacu"]
}
const CARD_KEYS := {KEY_1: "ima", KEY_2: "furia", KEY_3: "intangivel", KEY_4: "perfurante"}

func _ready() -> void:
 layer = 2
 frame = PanelContainer.new()
 add_child(frame)
 var background := StyleBoxFlat.new()
 background.bg_color = Color(0.06, 0.08, 0.09, 0.94)
 background.set_corner_radius_all(8)
 background.content_margin_left = 12
 background.content_margin_right = 12
 background.content_margin_top = 10
 background.content_margin_bottom = 10
 frame.add_theme_stylebox_override("panel", background)
 development_debug_frame = PanelContainer.new()
 development_debug_frame.add_theme_stylebox_override("panel", background)
 add_child(development_debug_frame)
 var development_debug_contents := VBoxContainer.new()
 development_debug_frame.add_child(development_debug_contents)
 for caption in ["ATALHOS · DEBUG", "F1 · Avançar 1 minuto", "F2 · Subir um nível"]:
  var label := Label.new()
  label.text = caption
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  development_debug_contents.add_child(label)
 development_debug_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 development_debug_contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
 development_debug_frame.hide()
 var contents := VBoxContainer.new()
 contents.add_theme_constant_override("separation", 8)
 frame.add_child(contents)
 var heading := Label.new()
 heading.text = "SALA DE TREINO"
 contents.add_child(heading)
 tabs = HBoxContainer.new()
 tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 contents.add_child(tabs)
 var group := ButtonGroup.new()
 for caption in ["Treino", "Atributos"]:
  var tab := Button.new()
  tab.text = caption
  tab.toggle_mode = true
  tab.button_group = group
  tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var normal_style := StyleBoxFlat.new()
  normal_style.bg_color = Color(0.09, 0.12, 0.13)
  normal_style.set_corner_radius_all(4)
  normal_style.set_content_margin_all(4)
  tab.add_theme_stylebox_override("normal", normal_style)
  var selected_style := StyleBoxFlat.new()
  selected_style.bg_color = Color(0.15, 0.22, 0.24)
  selected_style.border_color = Color(0.4, 0.65, 0.67)
  selected_style.border_width_bottom = 2
  selected_style.set_corner_radius_all(4)
  selected_style.set_content_margin_all(4)
  tab.add_theme_stylebox_override("pressed", selected_style)
  tab.pressed.connect(select_tab.bind(tab_buttons.size()))
  tab_buttons.append(tab)
  tabs.add_child(tab)
 select_tab(0)
 var hint := Label.new()
 hint.text = "Tab: alternar"
 hint.add_theme_font_size_override("font_size", 13)
 hint.add_theme_color_override("font_color", Color(0.6, 0.7, 0.72))
 contents.add_child(hint)
 controls = PanelContainer.new()
 controls.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
 contents.add_child(controls)
 var column := VBoxContainer.new()
 controls.add_child(column)
 for key in ACTIONS:
  var item := Button.new()
  item.text = ACTIONS[key][0]
  item.alignment = HORIZONTAL_ALIGNMENT_LEFT
  item.pressed.connect(act.bind(ACTIONS[key][1]))
  column.add_child(item)
 for key in CARD_KEYS:
  var id: String = CARD_KEYS[key]
  var item := Button.new()
  item.text = "Ctrl+%d · %s" % [key - KEY_1 + 1, {"ima": "Ímã", "furia": "Fúria", "intangivel": "Intangível", "perfurante": "Perfurante"}[id]]
  item.alignment = HORIZONTAL_ALIGNMENT_LEFT
  item.pressed.connect(activate_card.bind(id))
  column.add_child(item)
 automatic = CheckButton.new()
 automatic.text = "Spawn automático"
 automatic.toggled.connect(func(enabled: bool): auto_spawn = enabled; game.spawn_timer = 0.0)
 column.add_child(automatic)
 immortality = CheckButton.new()
 immortality.text = "Personagem imortal"
 immortality.toggled.connect(func(enabled: bool): game.prevent_player_death = enabled)
 column.add_child(immortality)
 cards_toggle = CheckButton.new()
 cards_toggle.text = "Habilitar cartas"
 cards_toggle.toggled.connect(func(enabled: bool): cards_enabled = enabled)
 column.add_child(cards_toggle)
 editor = PanelContainer.new()
 editor.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
 contents.add_child(editor)
 var rows := VBoxContainer.new()
 editor.add_child(rows)
 var title := Label.new()
 title.text = "ATRIBUTOS"
 rows.add_child(title)
 for id in STATS:
  var row := HBoxContainer.new()
  rows.add_child(row)
  var label := Label.new()
  label.text = STATS[id][0]
  label.custom_minimum_size.x = 180
  row.add_child(label)
  for direction in [-1, 0, 1]:
   if direction == 0:
    var value := SpinBox.new()
    value.min_value = STATS[id][2]
    value.max_value = STATS[id][3]
    value.step = 0.1 if id == "rate" else 1.0
    value.custom_minimum_size.x = 110
    value.value_changed.connect(set_stat.bind(id))
    values[id] = value
    row.add_child(value)
   else:
    var button := Button.new()
    button.text = "−" if direction < 0 else "+"
    button.custom_minimum_size.x = 40
    button.pressed.connect(change_stat.bind(id, direction))
    stat_buttons.append(button)
    row.add_child(button)
 editor.hide()
 controls.hide()
 frame.hide()

func reset() -> void:
 cards_enabled = false
 cards_toggle.set_pressed_no_signal(false)
 auto_spawn = false
 automatic.set_pressed_no_signal(false)
 immortality.set_pressed_no_signal(true)
 select_tab(0)
 editor.hide()

func _process(_dt: float) -> void:
 development_debug_frame.visible = development_debug_available() and game.state in ["playing", "paused"]
 development_debug_frame.scale = Vector2.ONE * 0.5
 development_debug_frame.position = Vector2(16, 140)
 var active: bool = game.run_active and game.run_mode == "training"
 var paused: bool = active and game.state == "paused"
 update_interaction(paused)
 frame.visible = active and game.state in ["playing", "paused"]
 tabs.visible = true
 controls.visible = frame.visible and selected_tab == 0
 editor.visible = frame.visible and selected_tab == 1
 for index in tab_buttons.size():
  tab_buttons[index].set_pressed_no_signal(index == selected_tab)
 for button in stat_buttons: button.disabled = not paused
 if editor.visible and not paused: refresh()
 var viewport := get_viewport().get_visible_rect().size
 # Only the visible tab determines the panel's width.
 frame.size = Vector2.ZERO
 frame.size = frame.get_combined_minimum_size()
 var factor := minf(0.5, minf((viewport.y - 160.0) / frame.size.y, (viewport.x - 32.0) / frame.size.x))
 frame.scale = Vector2.ONE * factor
 frame.position = Vector2(16, 140)

func update_interaction(paused: bool) -> void:
 var focused := get_viewport().gui_get_focus_owner()
 if not paused and focused and frame.is_ancestor_of(focused):
  focused.release_focus()
 for value in values.values():
  if not paused:
   value.get_line_edit().deselect()
  value.editable = paused
 set_mouse_interaction(frame, paused)

func set_mouse_interaction(node: Node, enabled: bool) -> void:
 if node is Control:
  if not node.has_meta("training_mouse_filter"):
   node.set_meta("training_mouse_filter", node.mouse_filter)
   node.set_meta("training_focus_mode", node.focus_mode)
  node.mouse_filter = int(node.get_meta("training_mouse_filter")) if enabled else Control.MOUSE_FILTER_IGNORE
  node.focus_mode = int(node.get_meta("training_focus_mode")) if enabled else Control.FOCUS_NONE
 for child in node.get_children(true):
  set_mouse_interaction(child, enabled)

func select_tab(index: int) -> void:
 selected_tab = index
 for tab_index in tab_buttons.size():
  tab_buttons[tab_index].set_pressed_no_signal(tab_index == index)
 if is_instance_valid(editor):
  if index == 1: refresh()
  _process(0.0)

func open_attributes() -> void:
 if game.run_mode != "training" or game.state not in ["playing", "paused"]: return
 select_tab(1)

func _input(event: InputEvent) -> void:
 if development_debug_available() and game.state == "playing" and event is InputEventKey and event.pressed and not event.echo:
  if event.keycode in [KEY_F1, KEY_F2]:
   act_development_debug("time" if event.keycode == KEY_F1 else "level")
   get_viewport().set_input_as_handled()
   return
 if not game.run_active or game.run_mode != "training": return
 if not event is InputEventKey or not event.pressed or event.echo: return
 if game.state in ["playing", "paused"] and event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed and CARD_KEYS.has(event.keycode):
  activate_card(CARD_KEYS[event.keycode])
 elif game.state in ["playing", "paused"] and event.keycode == KEY_TAB:
  select_tab(1 - selected_tab)
 elif game.state == "paused" and event.keycode == KEY_ESCAPE:
  game.resume()
 elif game.state == "playing" and ACTIONS.has(event.keycode):
  act(ACTIONS[event.keycode][1])
 else: return
 get_viewport().set_input_as_handled()

func activate_card(id: String) -> void:
 if not game.run_active or game.run_mode != "training" or game.state not in ["playing", "paused"]: return
 game.cards.activate(id)
 game.show_pending_level_up()

func refresh() -> void:
 for id in values:
  var value: float = 1.0 / game.attack_delay if id == "rate" else float(game.get(id))
  values[id].set_value_no_signal(value)

func set_stat(requested: float, id: String) -> void:
 if game.run_mode != "training" or game.state != "paused" or selected_tab != 1: return
 var data: Array = STATS[id]
 var value := clampf(requested, float(data[2]), float(data[3]))
 if id == "rate": game.attack_delay = 1.0 / value
 elif id in ["level", "shot_count", "xp_bonus"]: game.set(id, roundi(value))
 else: game.set(id, value)
 game.health = minf(game.health, game.max_health)
 if id == "level": game.xp = 0
 refresh()

func change_stat(id: String, direction: int) -> void:
 if game.run_mode != "training" or game.state != "paused" or selected_tab != 1: return
 var data: Array = STATS[id]
 var current: float = 1.0 / game.attack_delay if id == "rate" else float(game.get(id))
 set_stat(current + direction * float(data[1]), id)

func development_debug_available() -> bool:
 return OS.has_feature("editor") and OS.is_debug_build() and game.run_active and game.run_mode in ["bosses", "endless"]

func act_development_debug(action: String) -> void:
 if not development_debug_available() or game.state != "playing" or action not in ["time", "level"]: return
 game.test_run = true
 act_progression(action)

func act_progression(action: String) -> void:
 if action == "time":
  game.elapsed += 60.0
 elif action == "level":
  game.level = mini(100, game.level + 1)
  game.xp = 0
  game.health = game.max_health
  game.show_upgrades()

func act(action: String) -> void:
 if game.run_mode != "training" or game.state not in ["playing", "paused"]: return
 match action:
  "dourado", "pacu":
   var start_angle: float = game.rng.randf_range(0, TAU)
   for index in mini(10, maxi(0, game.MAX_ENEMIES - game.enemies.size())):
    game.spawn_enemy(false, action)
    game.enemies.back().pos = (game.player + Vector2.from_angle(start_angle + index * TAU / 10.0) * 300).clamp(Vector2(50, 50), game.ARENA - Vector2(50, 50))
  "piranha", "pintado", "boss":
   for index in mini(1 if action == "boss" else 100, maxi(0, game.MAX_ENEMIES - game.enemies.size())):
    game.spawn_enemy(action == "boss", "" if action == "boss" else action)
    var enemy: Dictionary = game.enemies.back()
    enemy.pos = (game.player + Vector2.from_angle(game.rng.randf_range(0, TAU)) * 300).clamp(Vector2(50, 50), game.ARENA - Vector2(50, 50))
    if action != "boss":
     enemy.tank = action == "pintado"
     enemy.radius = 44.0 if enemy.tank else 13.0
     enemy.hp = (200.0 if enemy.tank else 30.0) * game.fish_stat_multiplier()
     enemy.max_hp = enemy.hp
     enemy.speed = (80.0 if enemy.tank else 125.0) * game.fish_stat_multiplier()
     enemy.contact = (20.0 if enemy.tank else 10.0) * game.fish_stat_multiplier()
    else: game.boss_spawned = true
  "fish_clear", "clear":
   for index in range(game.enemies.size() - 1, -1, -1):
    if action == "clear" or not game.enemies[index].boss:
     game.enemies.remove_at(index)
     game.kills += 1
   if action == "clear": game.boss_spawned = false
   game.crowd_refresh_timer = 0.0
  "time":
   act_progression(action)
  "level":
   act_progression(action)
  "heal": game.health = game.max_health
  "cards":
   for index in game.cards.IDS.size():
    game.cards.spawn(game.cards.IDS[index], game.player + Vector2(-120 + index * 80, -80))
