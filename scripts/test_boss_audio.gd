extends SceneTree

class SoundProbe extends "res://scripts/sound_effects.gd":
 var attacks: Array[String] = []
 var boss_deaths := 0
 var fish_deaths := 0

 func play_boss_death() -> void:
  boss_deaths += 1
  super.play_boss_death()

 func play_death() -> void:
  fish_deaths += 1
  super.play_death()

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
 game.start_run("bosses")
 game.test_run = true
 for id in ["damage", "rate", "shots", "speed", "magnet"]:
  for rank in (5 if id == "speed" else 6): game.choose_upgrade(id)
 game.level = 30
 game.elapsed = game.RUN_SECONDS
 game.boss_spawned = true
 game.spawn_enemy(true)
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
 assert(sounds.players.emerge.stream.resource_path == "res://assets/audio/minhocao_emerge_v1.wav")
 assert(is_equal_approx(sounds.players.emerge.stream.get_length(), 1.15))
 game.update_game(0.01)
 assert(sounds.attacks == ["emerge"], "Emergence audio must not repeat every frame")
 boss.phase = "dash_warning"
 boss.timer = 0.0
 boss.dash_start = game.player - Vector2(250, 0)
 boss.dash_end = game.player + Vector2(250, 0)
 game.update_game(0.01)
 assert(boss.phase == "dash" and sounds.attacks == ["emerge", "dash"])
 assert(sounds.players.dash.stream.resource_path == "res://assets/audio/minhocao_dash_v3.wav")
 assert(is_equal_approx(sounds.players.dash.stream.get_length(), 0.7))
 game.update_game(0.01)
 assert(sounds.attacks == ["emerge", "dash"], "Dash audio must not repeat every frame")
 boss.hp = 0.0
 game.update_game(0.01)
 assert(game.state == "won" and sounds.boss_deaths == 1 and sounds.fish_deaths == 0)
 assert(is_equal_approx(sounds.players.boss_death.stream.get_length(), 2.2))
 for id in ["emerge", "dash", "boss_death"]: sounds.players[id].play()
 sounds.volumes.boss = 0.0
 sounds.apply_volumes()
 for id in ["boss", "emerge", "dash", "boss_death"]:
  assert(not sounds.players[id].playing and not sounds.effect_enabled(id))
 assert(sounds.pending_roars.is_empty() and sounds.roar_voices.is_empty())
 sounds.volumes.boss = 1.0
 sounds.set_process(false)
 game.start_run("endless")
 game.test_run = true
 game.prevent_player_death = true
 game.elapsed = game.ENDLESS_BOSS_INTERVAL - 2.0
 game.next_boss_time = INF
 for index in 10: game.spawn_enemy(true)
 game.boss_spawned = true
 for enemy in game.enemies: enemy.timer += 2.01
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
 game.elapsed = game.ENDLESS_FIRST_BOSS_TIME
 game.spawn_endless_bosses()
 assert(game.enemies.filter(func(enemy): return enemy.boss).size() == 1)
 assert(is_equal_approx(sounds.players.boss.stream.get_length(), 2.0))
 game.test_run = true
 game.spawn_timer = 1000
 game.attack_timer = 1000
 game.invulnerability = 1000
 var defeated: Dictionary = game.enemies.filter(func(enemy): return enemy.boss)[0]
 defeated.hp = 0.0
 game.update_game(0.01)
 assert(sounds.boss_deaths == 2 and not game.enemies.has(defeated))
 game.update_game(0.01)
 assert(sounds.boss_deaths == 2, "Death sound must trigger once per defeated boss")
 print("BOSS AUDIO PASS: emergence, dash, shared mute, staggered roars, reset, 2.2s V0 death sound once per boss in both modes")
 game.free()
 await create_timer(0.1).timeout
 call_deferred("quit", 0)
