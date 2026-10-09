extends SceneTree

class SoundProbe extends "res://scripts/sound_effects.gd":
 var attacks: Array[String] = []

 func play_boss_emergence() -> void:
  attacks.append("emerge")
  super.play_boss_emergence()

 func play_boss_dash() -> void:
  attacks.append("dash")
  super.play_boss_dash()

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 game.history_path = "user://boss_audio_test_%d.json" % Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.sounds.free()
 var sounds := SoundProbe.new()
 game.add_child(sounds)
 game.sounds = sounds
 game.start_boss_test()
 game.spawn_timer = 1000
 game.attack_timer = 1000
 game.invulnerability = 1000
 var boss: Dictionary = game.enemies[0]
 assert(sounds.attacks.is_empty())
 # Walk through the real game update: buried -> tracking -> warning -> emerge.
 for expected in ["tracking", "emerge_warning", "exposed"]:
  boss.timer = 0.0
  game.update_game(0.01)
  assert(boss.phase == expected)
  if expected != "exposed": assert(sounds.attacks.is_empty(), "Warnings must not trigger attack audio")
 assert(sounds.attacks == ["emerge"])
 game.update_game(0.01)
 assert(sounds.attacks == ["emerge"], "Emergence audio must not repeat every frame")
 boss.phase = "dash_warning"
 boss.timer = 0.0
 boss.dash_start = game.player - Vector2(250, 0)
 boss.dash_end = game.player + Vector2(250, 0)
 game.update_game(0.01)
 assert(boss.phase == "dash" and sounds.attacks == ["emerge", "dash"])
 game.update_game(0.01)
 assert(sounds.attacks == ["emerge", "dash"], "Dash audio must not repeat every frame")
 for id in ["emerge", "dash"]:
  sounds.players[id].play()
  sounds.volumes[id] = 0.0
  sounds.apply_volumes()
  assert(not sounds.players[id].playing and not sounds.effect_enabled(id))
 assert(is_equal_approx(sounds.players.boss.stream.get_length(), 2.0))
 print("BOSS AUDIO PASS: first emergence, attack sounds at action start, no per-frame repeats, per-effect mute, 2s roar")
 game.free()
 await create_timer(0.1).timeout
 quit(0)
