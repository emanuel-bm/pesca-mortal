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
 game.free()
 print("GAME MODES PASS: somente treino, infinito e chefões; configurações sem testes; modos antigos removidos")
 quit()
