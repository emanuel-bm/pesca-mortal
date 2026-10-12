extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.show_menu()
 game.sounds.music_player.play()
 game.sounds.players.level.play()
 game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 assert(game.state == "menu", "Focus loss must preserve the main menu")
 assert_audio_paused(game, true)
 var music_clock: float = game.sounds.music_clock
 game.sounds._process(1.0)
 assert(game.sounds.music_clock == music_clock, "Music transitions must freeze without focus")
 game.sounds.request_battle_music()
 assert_audio_paused(game, true)
 game.sounds.play_roar_voice()
 assert_audio_paused(game, true)
 game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 assert_audio_paused(game, false)
 game.start_run("endless")
 for child in game.get_children():
  if child.get_script():
   assert(child.get_script().resource_path != "res://scripts/window_visibility.gd", "PiP and notifications must not start an overlap detector")
 assert(game.state == "playing")
 assert_audio_paused(game, false)
 game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 game.resume()
 assert(game.state == "paused", "Continue must not resume while another application has focus")
 assert_audio_paused(game, true)
 game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 assert_audio_paused(game, false)
 assert(game.state == "paused", "Returning focus must require explicit resume")
 for mode in ["endless", "bosses", "training"]:
  game.start_run(mode)
  game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
  assert_audio_paused(game, true)
  assert(game.state == "paused" and game.overlay.visible, "Focus loss must open the pause menu in every mode")
  var elapsed: float = game.elapsed
  var player: Vector2 = game.player
  var health: float = game.health
  for frame in 3: await process_frame
  assert(game.elapsed == elapsed and game.player == player and game.health == health, "The paused run must not advance")
  var continue_button: Node = root.gui_get_focus_owner()
  game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
  assert(root.gui_get_focus_owner() == continue_button, "Repeated focus loss must preserve the pause menu")
  game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
  assert_audio_paused(game, false)
  assert(game.state == "paused", "Returning focus must leave the run paused")
  game.resume()
  assert(game.state == "playing" and not game.overlay.visible, "Continue must resume the run")
 for state in ["upgrade", "settings", "won", "lost"]:
  game.state = state
  game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
  assert(game.state == state, "Focus loss must preserve existing modal states")
  assert_audio_paused(game, true)
  game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
  assert_audio_paused(game, false)
 game.run_active = false
 game.queue_free()
 await process_frame
 print("Focus pause checks passed: all modes, frozen gameplay, explicit resume and preserved menus.")
 quit()

func assert_audio_paused(game: Node, expected: bool) -> void:
 assert(game.sounds.focus_paused == expected)
 for child in game.sounds.get_children():
  if child is AudioStreamPlayer and child.has_stream_playback():
   assert(child.stream_paused == expected, "Music and effects must follow window focus")
