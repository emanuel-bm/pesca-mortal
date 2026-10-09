extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var sounds: Node = load("res://scripts/sound_effects.gd").new()
 root.add_child(sounds)
 sounds.set_process(false)
 var music: AudioStreamPlayer = sounds.music_player
 assert(sounds.music_track == "calm" and not sounds.battle_requested)
 for stream: AudioStreamWAV in sounds.music_streams.values():
  assert(is_equal_approx(stream.get_length(), 30.0), "Both themes must last exactly 30 seconds")
  assert(stream.stereo and stream.mix_rate == 44100)
  assert(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
  assert(stream.loop_begin == 0 and stream.loop_end == 1323000)
 sounds.volumes.master = 1.0
 sounds.volumes.music = 0.7
 sounds.apply_volumes()
 assert(is_equal_approx(music.volume_linear, 0.315))
 # Explicit playback exercises the audio server even with the headless driver.
 music.play(29.7)
 await create_timer(0.7).timeout
 assert(music.playing, "Theme must continue across the end of the file")
 assert(music.get_playback_position() < 1.5, "Playback must wrap to the beginning")
 sounds.reset()
 assert(music.playing, "Restarting effects must not interrupt music")
 sounds.volumes.music = 0.0
 sounds.apply_volumes()
 assert(not music.playing and sounds.effect_enabled("shot"))
 sounds.volumes.music = 1.0
 sounds.volumes.master = 0.0
 music.play()
 sounds.apply_volumes()
 assert(not music.playing and not sounds.effect_enabled("music"))
 # Calm's four-second fade begins two seconds before the boss.
 sounds.prepare_boss_music(3.0)
 assert(sounds.music_gain == 1.0 and sounds.music_track == "calm")
 sounds.prepare_boss_music(2.0)
 assert(sounds.music_gain == 1.0)
 sounds.prepare_boss_music(1.0)
 assert(is_equal_approx(sounds.music_gain, 0.84375))
 sounds.update_music(1.0)
 assert(is_equal_approx(sounds.music_gain, 0.84375), "Pre-boss fade must follow game time, not wall time")
 sounds.prepare_boss_music(0.0)
 assert(sounds.music_gain == 0.5 and sounds.music_track == "calm")
 # At spawn: calm is half faded, battle starts at zero, with a 2s overlap.
 sounds.music_clock = 0.1
 sounds.request_battle_music()
 music = sounds.music_player
 var wait_time: float = sounds.transition_remaining
 assert(is_equal_approx(wait_time, 4.0))
 assert(sounds.music_track == "battle" and music.stream == sounds.music_streams.battle)
 assert(sounds.music_gain == 0.0)
 assert(sounds.outgoing_music_gain == 0.5 and sounds.outgoing_music_player.stream == sounds.music_streams.calm)
 sounds.request_battle_music()
 assert(sounds.transition_remaining == wait_time)
 sounds.update_music(1.0)
 assert(is_equal_approx(sounds.music_gain, 0.15625))
 assert(is_equal_approx(sounds.outgoing_music_gain, 0.15625))
 assert(not music.playing and not sounds.outgoing_music_player.playing, "Master mute must affect both tracks")
 sounds.volumes.master = 1.0
 sounds.volumes.music = 0.7
 music.play()
 sounds.outgoing_music_player.play()
 sounds.apply_volumes()
 assert(music.playing and sounds.outgoing_music_player.playing)
 assert(is_equal_approx(music.volume_linear, 0.315 * 0.15625))
 assert(is_equal_approx(sounds.outgoing_music_player.volume_linear, 0.315 * 0.15625))
 sounds.volumes.music = 0.0
 sounds.apply_volumes()
 assert(not music.playing and not sounds.outgoing_music_player.playing, "Music mute must stop both tracks")
 sounds.update_music(1.0)
 assert(sounds.outgoing_music_gain == 0.0 and not sounds.outgoing_music_player.playing)
 assert(sounds.music_gain == 0.5 and sounds.transition_remaining == 2.0)
 sounds.update_music(2.0)
 assert(sounds.music_gain == 1.0 and not music.playing)
 assert(sounds.transition_remaining == -1.0)
 sounds.prepare_boss_music(0.0)
 assert(sounds.music_gain == 1.0, "Later boss countdowns must not fade the battle track")
 music.play(29.7)
 await create_timer(0.7).timeout
 assert(music.playing and music.get_playback_position() < 1.5, "Battle theme must also loop")
 music.stop()
 sounds.request_battle_music()
 assert(sounds.transition_remaining == -1.0)
 sounds.start_calm_music()
 assert(sounds.music_track == "calm" and not sounds.battle_requested)
 sounds.request_battle_music()
 sounds.start_calm_music()
 sounds.update_music(1.0)
 assert(sounds.music_track == "calm", "Returning to menu must cancel a pending boss transition")
 # Two-second roar, synchronized music trigger, simultaneous-boss suppression.
 assert(is_equal_approx(sounds.players.boss.stream.get_length(), 2.0))
 sounds.volumes.master = 1.0
 sounds.volumes.boss = 1.0
 sounds.announce_boss()
 assert(sounds.music_track == "battle" and sounds.transition_remaining == 4.0)
 var announcement_time: int = sounds.last_boss_ms
 sounds.announce_boss()
 assert(sounds.last_boss_ms == announcement_time)
 sounds.players.boss.play()
 sounds.volumes.boss = 0.0
 sounds.apply_volumes()
 assert(not sounds.players.boss.playing)
 sounds.announce_boss()
 assert(sounds.last_boss_ms == announcement_time)
 sounds.volumes.boss = 1.0
 sounds.volumes.master = 0.0
 sounds.players.boss.play()
 sounds.apply_volumes()
 assert(not sounds.players.boss.playing)
 sounds.announce_boss()
 assert(sounds.last_boss_ms == announcement_time)
 sounds.free()
 await create_timer(0.1).timeout
 await check_game_music()
 print("MUSIC PASS: 4s fades, 2s post-boss overlap, both-track mute, loops/roar, both modes, pause/restart/menu/settings")
 quit(0)

func check_game_music() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 game.history_path = "user://music_transition_test_%d.json" % Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.sounds.set_process(false)
 var sounds: Node = game.sounds
 assert(sounds.music_track == "calm")
 sounds.music_clock = 12.3
 game.start_run()
 assert(sounds.music_clock == 12.3, "Starting from menu must preserve the calm phrase")
 game.elapsed = game.RUN_SECONDS - 3.01
 game.update_game(0.01)
 assert(sounds.music_gain == 1.0 and not sounds.battle_requested)
 game.elapsed = game.RUN_SECONDS - 1.01
 game.update_game(0.01)
 assert(is_equal_approx(sounds.music_gain, 0.84375) and not sounds.battle_requested)
 game.show_pause()
 sounds.update_music(1.0)
 assert(is_equal_approx(sounds.music_gain, 0.84375), "Pause freezes pre-boss fade")
 game.resume()
 game.elapsed = game.RUN_SECONDS - 0.51
 game.update_game(0.01)
 assert(sounds.music_gain < 0.84375 and sounds.music_gain > 0.5 and not sounds.battle_requested)
 game.elapsed = game.RUN_SECONDS
 game.update_game(0.01)
 assert(sounds.battle_requested, "Normal boss appearance must trigger the music")
 assert(sounds.last_boss_ms >= 0, "Normal boss must announce its appearance")
 assert(sounds.music_gain == 0.0)
 sounds.update_music(4.0)
 game.finish(true)
 assert(sounds.music_track == "battle", "Battle theme must remain on the end screen")
 game.show_pause()
 game.show_settings()
 assert(sounds.music_track == "battle")
 # Verify the visible music slider controls the same preference and persists it.
 var original: float = sounds.volumes.music
 var found := false
 for child in game.panel.get_children():
  if child is HBoxContainer and child.get_child(0) is Label and child.get_child(0).text == "Música":
   var slider: HSlider = child.get_child(1)
   slider.value = 37
   assert(is_equal_approx(sounds.volumes.music, 0.37))
   var config := ConfigFile.new()
   assert(config.load("user://audio.cfg") == OK)
   assert(is_equal_approx(float(config.get_value("audio", "music")), 0.37))
   slider.value = original * 100.0
   # Restore exact original preference even if it was not an integer percent.
   sounds.set_volume("music", original)
   found = true
 assert(found, "Settings must expose a music volume slider")
 game.show_menu()
 assert(sounds.music_track == "calm" and not sounds.battle_requested)
 game.start_run("endless")
 game.elapsed = game.next_boss_time - 1.01
 game.update_game(0.01)
 assert(is_equal_approx(sounds.music_gain, 0.84375) and not sounds.battle_requested)
 game.elapsed = game.next_boss_time
 game.update_game(0.01)
 assert(sounds.battle_requested, "Endless boss appearance must also trigger music")
 assert(sounds.music_gain == 0.0)
 sounds.update_music(4.0)
 game.spawn_enemy(true)
 assert(sounds.music_track == "battle" and sounds.transition_remaining == -1.0)
 game.start_run()
 assert(sounds.music_track == "calm" and not sounds.battle_requested)
 game.start_boss_test()
 assert(sounds.battle_requested, "Boss test must also trigger the music")
 game.show_menu()
 sounds.update_music(1.0)
 assert(sounds.music_track == "calm", "Menu must cancel a pending transition")
 var temporary_history: String = ProjectSettings.globalize_path(game.history_path)
 game.free()
 if FileAccess.file_exists(temporary_history): DirAccess.remove_absolute(temporary_history)
 await create_timer(0.1).timeout
