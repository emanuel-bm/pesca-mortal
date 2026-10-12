extends SceneTree

class SoundProbe extends "res://scripts/sound_effects.gd":
 var effects: Array[String] = []
 func play_effect(id: String, low: float, high: float) -> void:
  if effect_enabled(id): effects.append(id)
  super.play_effect(id, low, high)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.sounds.free()
 var sounds := SoundProbe.new()
 game.add_child(sounds)
 game.sounds = sounds
 sounds.set_process(false)
 sounds.volumes.master = 1
 sounds.volumes.boss = 1
 sounds.volumes.pai_do_mato = 1
 sounds.apply_volumes()
 for pair in [["pai_log_throw", .325], ["pai_log_splash", 1.05], ["pai_hand", 1.15], ["pai_do_mato", 2.4]]:
  assert(absf(sounds.players[pair[0]].stream.get_length() - pair[1]) < 1.0 / 44100.0)
  assert(sounds.volume_group(pair[0]) == "pai_do_mato")
 game.start_run("training")
 game.training.act("pai_do_mato")
 assert(sounds.roar_voices.size() == 1 and sounds.roar_voices[0].stream == sounds.players.pai_do_mato.stream)
 sounds.announce_boss()
 sounds.announce_boss("pai_do_mato")
 assert(sounds.pending_roar_ids == ["boss", "pai_do_mato"])
 sounds.update_roars(1)
 assert(sounds.roar_voices.size() == 3)
 sounds.volumes.boss = 0
 sounds.apply_volumes()
 assert(sounds.roar_voices.size() == 2 and sounds.roar_voices.all(func(voice): return voice.get_meta("effect_id") == "pai_do_mato"))
 sounds.volumes.pai_do_mato = 0
 sounds.apply_volumes()
 assert(sounds.roar_voices.is_empty())
 sounds.volumes.pai_do_mato = 1
 sounds.apply_volumes()
 var boss: Dictionary = game.enemies[0]
 boss.pos = Vector2(800, 900)
 boss.target = Vector2(1400, 900)
 game.player = Vector2(1200, 300)
 game.execute_forest_attack(boss, "log")
 var log: Dictionary = game.enemies.back()
 assert(sounds.effects.count("pai_log_throw") == 1)
 game.update_log(log, .1625)
 assert(is_equal_approx(log.flight, .5) and log.pos.is_equal_approx(Vector2(1100, 900)))
 game.update_log(log, .1625)
 assert(log.landed and sounds.effects.count("pai_log_splash") == 1)
 assert(game.water_ripples.size() == 1 and game.water_ripples[0].kind == "log_impact")
 assert(game.water_ripples[0].pos == log.pos)
 game.update_log(log, 1)
 assert(sounds.effects.count("pai_log_splash") == 1, "Landing sound fires once")
 assert(game.water_ripples.size() == 1, "Landing visual fires once")
 game.state = "paused"
 game.update_water(.5)
 assert(game.water_ripples[0].age == 0)
 game.state = "playing"
 var quality: int = game.graphics_quality
 game.graphics_quality = 0
 game.update_water(3)
 assert(game.water_ripples.is_empty(), "Water impact expires even at low graphics quality")
 game.graphics_quality = quality
 var distance_logs: Array[Dictionary] = []
 for length in [300.0, 900.0]:
  boss.pos = Vector2(800, 900)
  boss.target = boss.pos + Vector2(length, 0)
  game.execute_forest_attack(boss, "log")
  var moving_log: Dictionary = game.enemies.back()
  game.update_log(moving_log, .1)
  assert(is_equal_approx(moving_log.pos.x - 800, game.PAI_DO_MATO.LOG_SPEED * .1), "Same pixels/second at every range")
  distance_logs.append(moving_log)
 game.update_log(distance_logs[0], .1)
 game.update_log(distance_logs[1], .1)
 assert(distance_logs[0].landed and not distance_logs[1].landed, "Nearby logs land sooner")
 game.execute_forest_attack(boss, "hand")
 assert(sounds.effects.count("pai_hand") == 1 and not "emerge" in sounds.effects)
 var hand_splashes: Array = game.water_ripples.filter(func(effect: Dictionary): return effect.kind == "hand_impact")
 assert(hand_splashes.size() == 1 and hand_splashes[0].pos == boss.target)
 assert(is_equal_approx(hand_splashes[0].angle, boss.hand_angle - PI / 2))
 sounds.volumes.master = 0
 sounds.apply_volumes()
 for id in sounds.FOREST_AUDIO: assert(not sounds.effect_enabled(id))
 sounds.reset()
 assert(sounds.pending_roars.is_empty() and sounds.pending_roar_ids.is_empty())
 game.free()
 print("PAI AUDIO PASS: distinct roar, mixed queues, independent mute, throw, half flight time, one-shot landing and palm impact")
 quit()
