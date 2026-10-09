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
 for id in ["emerge", "dash"]: sounds.players[id].play()
 sounds.volumes.boss = 0.0
 sounds.apply_volumes()
 for id in ["boss", "emerge", "dash"]:
  assert(not sounds.players[id].playing and not sounds.effect_enabled(id))
 assert(sounds.pending_roars.is_empty() and sounds.roar_voices.is_empty())
 sounds.volumes.boss = 1.0
 sounds.set_process(false)
 game.start_ten_bosses_test()
 game.spawn_timer = 1000
 game.attack_timer = 1000
 game.update_game(2.01)
 var bosses: Array = game.enemies.filter(func(enemy): return enemy.boss)
 assert(bosses.size() == 10)
 assert(sounds.roar_voices.size() == 1 and sounds.pending_roars.size() == 9)
 var previous_delay := 0.0
 for delay in sounds.pending_roars:
  assert(delay > previous_delay)
  previous_delay = delay
 for enemy in bosses:
  assert(enemy.first_emergence_pending and enemy.phase == "burrow")
 bosses[0].timer = 0.0
 game.update_game(0.01)
 assert(bosses[0].phase == "tracking" and not bosses[0].first_emergence_pending)
 for index in range(1, bosses.size()):
  assert(bosses[index].first_emergence_pending)
 sounds.update_roars(0.3)
 assert(sounds.roar_voices.size() == 2 and sounds.pending_roars.size() == 8)
 sounds.update_roars(3.0)
 assert(sounds.roar_voices.size() == 10 and sounds.pending_roars.is_empty())
 var transition: float = sounds.transition_remaining
 sounds.announce_boss()
 assert(sounds.transition_remaining == transition)
 sounds.reset()
 assert(sounds.roar_voices.is_empty() and sounds.pending_roars.is_empty())
 game.start_run("endless")
 game.elapsed = game.ENDLESS_BOSS_INTERVAL
 game.spawn_endless_bosses()
 assert(game.enemies.filter(func(enemy): return enemy.boss).size() == 1)
 assert(is_equal_approx(sounds.players.boss.stream.get_length(), 2.0))
 print("BOSS AUDIO PASS: first emergence, attack sounds at action start, no per-frame repeats, shared boss mute, 10 staggered voices, per-boss emergence, reset, normal first wave, 2s roar")
 game.free()
 await create_timer(0.1).timeout
 call_deferred("quit", 0)
