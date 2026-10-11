extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 game.show_menu()
 var modes: Array[String] = []
 for item in game.panel.get_children():
  if item is Button:
   modes.append(item.text)
   assert(not item.text.begins_with("Testar") and item.text != "Teste de hordas")
 assert("Sala de treino" in modes and "Modo infinito" in modes and "Modo por chefões" in modes, str(modes))
 game.show_settings()
 for item in game.panel.get_children():
  if item is BaseButton: assert(not item.text.to_lower().contains("teste"))
 for method in ["start_boss_test", "start_ten_bosses_test", "start_endless_test", "start_horde_test", "prepare_level_30_test", "test_modes_available"]:
  assert(not game.has_method(method), "Modos antigos devem ser removidos: " + method)
 game.start_run("horde")
 assert(not game.run_active)
 for mode in ["training", "endless", "bosses"]:
  game.start_run(mode)
  assert(game.run_active and game.run_mode == mode)
  assert(game.test_run == (mode == "training"))
  game.run_recorded = true
 game.start_run("bosses")
 game.training._process(0.0)
 assert(game.training.development_debug_frame.visible == (OS.has_feature("editor") and OS.is_debug_build()))
 if game.training.development_debug_available():
  var event := InputEventKey.new()
  event.pressed = true
  event.keycode = KEY_F1
  game.training._input(event)
  assert(game.elapsed == 60.0 and game.test_run)
  event.echo = true
  game.training._input(event)
  assert(game.elapsed == 60.0)
  event.echo = false
  for index in 4: game.training._input(event)
  game.update_game(0.0)
  assert(game.boss_spawned)
  event.keycode = KEY_F2
  game.training._input(event)
  assert(game.level == 2 and game.state == "upgrade")
  game.training._input(event)
  assert(game.level == 2)
 game.start_run("endless")
 game.training._process(0.0)
 assert(game.training.development_debug_frame.visible == (OS.has_feature("editor") and OS.is_debug_build()))
 if game.training.development_debug_available():
  var event := InputEventKey.new()
  event.pressed = true
  event.keycode = KEY_F1
  game.training._input(event)
  assert(game.elapsed == 60.0 and game.test_run)
  for index in 2: game.training._input(event)
  game.update_game(0.0)
  assert(game.boss_spawned and game.endless_wave == 1)
  event.keycode = KEY_F2
  game.training._input(event)
  assert(game.level == 2 and game.state == "upgrade")
 game.start_run("training")
 game.training._process(0.0)
 assert(not game.training.development_debug_available() and not game.training.development_debug_frame.visible)
 game.training.act_development_debug("time")
 assert(game.elapsed == 0.0)
 game.run_recorded = true
 game.free()
 print("GAME MODES PASS: somente treino, infinito e chefões; configurações sem testes; modos antigos removidos")
 quit()
