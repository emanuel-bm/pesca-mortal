extends SceneTree

var failures := 0

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, message: String) -> void:
 if not condition:
  failures += 1
  push_error(message)

func check_bars(game: Node, expected: bool) -> void:
 for item in [game.health_bar, game.health_label, game.xp_bar, game.xp_label]:
  check(item.visible == expected, "Vida e XP: visibilidade incorreta em " + game.state)

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.online.profile = {"nickname": "Teste"}
 game.show_menu()
 for frame in 3: await process_frame
 check_bars(game, false)
 game.show_settings()
 for frame in 3: await process_frame
 check_bars(game, false)
 game.fullscreen_toggle.set_pressed_no_signal(true)
 check(game.fullscreen_toggle.button_pressed, "Interruptor deve manter o valor habilitado")
 check(root.gui_get_focus_owner() == game.resolution_picker, "Resolução deve ter o foco inicial")
 var pressed := game.fullscreen_toggle.get_theme_stylebox("pressed") as StyleBoxFlat
 check(pressed != null and pressed.border_color.a == 0, "Interruptor habilitado sem foco não deve ter borda de seleção")
 game.fullscreen_toggle.grab_focus()
 check(game.fullscreen_toggle.get_theme_stylebox("focus").border_color == Color(0.3, 1.0, 0.45), "Interruptor focado deve ter borda verde")
 game.resolution_picker.grab_focus()
 check(not game.fullscreen_toggle.has_focus(), "Interruptor deve perder foco ao selecionar resolução")
 game.leave_settings()
 game.start_run()
 for frame in 3: await process_frame
 check_bars(game, true)
 game.show_pause()
 for frame in 3: await process_frame
 check_bars(game, true)
 game.show_settings()
 for frame in 3: await process_frame
 check_bars(game, true)
 game.show_menu()
 for frame in 3: await process_frame
 check_bars(game, false)
 if failures == 0: print("MENU VISUAL STATE PASS: foco de interruptores e vida/XP por contexto")
 quit(1 if failures > 0 else 0)
