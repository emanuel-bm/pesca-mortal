extends SceneTree

class SoundProbe extends "res://scripts/sound_effects.gd":
 var events: Array[String] = []
 func play_effect(id: String, _pitch_min: float = 1.0, _pitch_max: float = 1.0) -> void:
  events.append(id)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 root.set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.set_process(false)
 game.sounds.free()
 var sounds := SoundProbe.new()
 game.add_child(sounds)
 game.sounds = sounds
 game.start_run("training")
 for id in ["shield_block", "ui_upgrade_confirm"]:
  assert(sounds.players[id].stream != null)
  assert(sounds.players[id].stream.get_length() > 0.0)
  assert(sounds.volume_group(id) == "character")
 game.cards.activate("intangivel")
 sounds.events.clear()
 game.receive_hit(500.0, game.player + Vector2.RIGHT)
 game.receive_hit(500.0, game.player + Vector2.RIGHT)
 assert(sounds.events == ["shield_block"], "Sustained shield contact plays once per feedback interval")
 assert(game.health == game.max_health)
 game.show_upgrades()
 sounds.events.clear()
 var choice: String = game.choices[0]
 var generation: int = game.upgrade_generation
 game.choose_upgrade(choice, generation - 1)
 assert(sounds.events.is_empty(), "Stale upgrade selections must stay silent")
 game.choose_upgrade(choice, generation)
 game.choose_upgrade(choice, generation)
 assert(sounds.events == ["ui_upgrade_confirm"], "A confirmed upgrade plays once")
 game.queue_free()
 await process_frame
 print("SHIELD/UPGRADE AUDIO PASS: streams, volume group, blocked hit, sustained contact and valid upgrade selection")
 quit(0)
