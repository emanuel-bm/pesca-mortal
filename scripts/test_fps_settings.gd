extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var mode := int(ProjectSettings.get_setting("display/window/vsync/vsync_mode", 1))
 print("Configured VSync mode: ", mode, " (0 = disabled, 1 = monitor synchronized)")
 if mode != 0:
  push_error("Default VSync ties rendering FPS to monitor refresh rate")
  quit(1)
  return
 var path := "user://display.cfg"
 var existed := FileAccess.file_exists(path)
 var original := FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
 var config := ConfigFile.new()
 config.save(path)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 var passed: bool = game.fps_limit == 360 and Engine.max_fps == 360
 passed = passed and int(ProjectSettings.get_setting("application/run/max_fps")) == 360
 for limit in [60, 61, 100, 143, 180, 250, 359, 360]:
  game.show_settings()
  game.fps_limit_slider.value = limit
  passed = passed and int(game.fps_limit_input.value) == limit
  game.fps_limit_input.get_line_edit().text = str(limit)
  game.save_settings_from_ui()
  passed = passed and Engine.max_fps == limit
  config.load(path)
  passed = passed and int(config.get_value("display", "fps_limit", -1)) == limit
  game.fps_limit = -1
  game.load_display_settings()
  passed = passed and game.fps_limit == limit and Engine.max_fps == limit
  if DisplayServer.get_name() != "headless":
   passed = passed and DisplayServer.window_get_vsync_mode(root.get_window_id()) == DisplayServer.VSYNC_DISABLED
 game.show_settings()
 game.fps_limit_input.value = 60
 passed = passed and int(game.fps_limit_slider.value) == 60
 game.leave_settings()
 passed = passed and game.fps_limit == 360 and Engine.max_fps == 360
 for values in [[0, 360], [-1, 360], [30, 60], [999, 360], [143, 143]]:
  config.set_value("display", "fps_limit", values[0])
  config.save(path)
  game.load_display_settings()
  passed = passed and game.fps_limit == values[1] and Engine.max_fps == values[1]
 game.show_settings()
 game.fps_limit_input.get_line_edit().text = "999"
 game.save_settings_from_ui()
 passed = passed and game.fps_limit == 360 and Engine.max_fps == 360
 game.show_settings()
 game.fps_limit_input.get_line_edit().text = "30"
 game.save_settings_from_ui()
 passed = passed and game.fps_limit == 60 and Engine.max_fps == 60
 config.set_value("display", "fps_limit", -20)
 config.save(path)
 game.load_display_settings()
 passed = passed and game.fps_limit == 360 and Engine.max_fps == 360
 game.fullscreen = true
 game.apply_display_settings(false)
 game.fullscreen = false
 game.apply_display_settings(false)
 passed = passed and Engine.max_fps == 360
 if DisplayServer.get_name() != "headless":
  passed = passed and DisplayServer.window_get_vsync_mode(root.get_window_id()) == DisplayServer.VSYNC_DISABLED
 game.free()
 if existed:
  var file := FileAccess.open(path, FileAccess.WRITE)
  file.store_buffer(original)
  file.close()
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 if not passed:
  push_error("FPS settings failed: defaults, save/reload, cancel, invalid value or window mode")
  quit(1)
  return
 print("FPS SETTINGS PASS: 360 default, slider/input synchronization, typed limits, persistence, cancel, invalid value and window modes")
 quit()
