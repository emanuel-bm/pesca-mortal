extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, message: String) -> void:
 if not condition:
  push_error(message)
  quit(1)
  assert(condition, message)

func key(code: Key) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.pressed = true
 Input.parse_input_event(event)
 await process_frame
 event = InputEventKey.new()
 event.keycode = code
 event.pressed = false
 Input.parse_input_event(event)
 await process_frame

func focus_button(game: Node, text: String) -> void:
 for item in game.menu_controls:
  if item is Button and item.text == text:
   item.grab_focus()
   return
 check(false, "Botão não encontrado: " + text)

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.online.profile = {"nickname": "Teste"}
 game.show_menu()
 for frame in 5: await process_frame
 check(root.gui_get_focus_owner().text == "Modo infinito", "Menu deve selecionar a primeira opção")
 var highlight: StyleBoxFlat = root.gui_get_focus_owner().get_theme_stylebox("focus")
 check(highlight.border_color == Color(0.3, 1.0, 0.45), "Foco deve usar o destaque verde do menu de nível")
 await key(KEY_DOWN)
 check(root.gui_get_focus_owner().text == "Modo por chefões", "Seta para baixo deve selecionar a próxima opção")
 await key(KEY_UP)
 await key(KEY_UP)
 check(root.gui_get_focus_owner().text == "Fechar jogo", "Seta para cima deve voltar ao fim do menu")
 await key(KEY_DOWN)
 check(root.gui_get_focus_owner().text == "Modo infinito", "Seta para baixo deve voltar ao início")
 focus_button(game, "Configurações")
 await key(KEY_ENTER)
 check(game.state == "settings", "Enter deve abrir configurações")
 check(root.gui_get_focus_owner() == game.resolution_picker, "Configurações devem focar resolução")
 await key(KEY_ENTER)
 check(game.resolution_picker.get_popup().visible, "Enter deve abrir a lista de resolução")
 await key(KEY_DOWN)
 check(root.gui_get_focus_owner() == game.resolution_picker, "Lista aberta deve manter foco no seletor")
 await key(KEY_ENTER)
 check(not game.resolution_picker.get_popup().visible, "Enter deve confirmar a opção da lista")
 await key(KEY_DOWN)
 check(root.gui_get_focus_owner() == game.quality_picker, "Seta deve avançar entre seletores")
 await key(KEY_DOWN)
 check(root.gui_get_focus_owner() == game.fullscreen_toggle, "Seta deve selecionar interruptores")
 var toggled: bool = game.fullscreen_toggle.button_pressed
 await key(KEY_ENTER)
 check(game.fullscreen_toggle.button_pressed != toggled, "Enter deve alternar interruptor")
 await key(KEY_DOWN)
 await key(KEY_DOWN)
 await key(KEY_DOWN)
 var slider: HSlider = root.gui_get_focus_owner()
 check(slider != null, "Seta deve alcançar volume")
 var previous_volume := slider.value
 slider.value = 50
 await key(KEY_RIGHT)
 check(slider.value == 51, "Seta direita deve ajustar volume")
 slider.value = previous_volume
 await key(KEY_DOWN)
 check(root.gui_get_focus_owner() != slider, "Seta para baixo deve sair do volume")
 focus_button(game, "Voltar")
 await key(KEY_ENTER)
 check(game.state == "menu", "Enter deve voltar ao menu")
 await key(KEY_ENTER)
 check(game.state == "playing", "Enter deve iniciar partida")
 await key(KEY_ESCAPE)
 check(game.state == "paused", "Esc deve pausar")
 check(root.gui_get_focus_owner().text == "Continuar", "Pausa deve focar Continuar")
 await key(KEY_DOWN)
 await key(KEY_ENTER)
 check(game.state == "settings" and game.settings_return == "paused", "Pausa deve abrir configurações")
 await key(KEY_ESCAPE)
 check(game.state == "paused", "Esc deve voltar à pausa")
 await key(KEY_ENTER)
 check(game.state == "playing", "Enter deve continuar partida")
 game.show_upgrades()
 await process_frame
 await key(KEY_DOWN)
 check(game.selected_upgrade == 1, "Navegação do nível deve continuar funcionando")
 await key(KEY_ENTER)
 check(game.state == "playing", "Enter deve confirmar melhoria")
 print("MENU KEYBOARD PASS: setas, Enter, listas, interruptores, volume, pausa e melhorias")
 quit(0)
