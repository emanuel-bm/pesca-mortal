extends SceneTree

class ExportedGame:
 extends "res://scripts/game.gd"

 func test_modes_available() -> bool:
  return false

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game := ExportedGame.new()
 root.set_meta("offline_session", true)
 root.add_child(game)
 game.online.disabled = true
 game.set_process(false)
 assert(not game.test_modes_enabled, "Testes devem iniciar desligados")
 game.test_modes_enabled = true
 game.show_menu()
 for item in game.menu_controls:
  if item is Button:
   assert(not item.text.begins_with("Testar") and item.text != "Teste de hordas", "Exportação não deve mostrar testes")
 game.show_settings()
 assert(game.test_mode_toggle == null, "Exportação não deve criar o interruptor")
 var settings_path := "user://display.cfg"
 var had_settings := FileAccess.file_exists(settings_path)
 var saved_settings := FileAccess.get_file_as_bytes(settings_path) if had_settings else PackedByteArray()
 game.save_settings_from_ui()
 if had_settings:
  var settings_file := FileAccess.open(settings_path, FileAccess.WRITE)
  settings_file.store_buffer(saved_settings)
  settings_file.close()
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
 assert(not game.test_modes_enabled, "Salvar configurações deve manter testes bloqueados")
 game.start_boss_test()
 game.start_ten_bosses_test()
 game.start_endless_test()
 game.start_horde_test()
 game.prepare_level_30_test("bosses")
 game.start_run("horde")
 assert(not game.run_active and not game.test_run, "Chamadas diretas não devem iniciar testes")
 game.start_run("endless")
 assert(game.run_active and game.run_mode == "endless", "Modo infinito deve continuar disponível")
 game.start_run("bosses")
 assert(game.run_active and game.run_mode == "bosses", "Modo por chefões deve continuar disponível")
 game.run_recorded = true
 print("DEVELOPMENT MODES PASS: exportação bloqueada e modos básicos disponíveis")
 quit()
