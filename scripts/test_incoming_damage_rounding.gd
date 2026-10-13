extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 var hits := [
  {"species": "piranha", "attack": "Contato"},
  {"species": "pintado", "attack": "Contato"},
  {"species": "pacu", "attack": "Contato"},
  {"species": "dourado", "attack": "Investida"},
  {"species": "minhocao", "attack": "Emergência"},
  {"species": "minhocao", "attack": "Investida"},
  {"species": "pai_do_mato", "attack": "Mãozona"},
  {"species": "pai_do_mato", "attack": "Tronco arremessado"}
 ]
 for hit in hits:
  for sample in [[10.8, 11.0], [10.4, 10.0], [10.5, 11.0]]:
   game.start_run("training")
   var attacker := {"species": hit.species, "tank": hit.species == "pintado", "boss": hit.species in ["minhocao", "pai_do_mato"]}
   game.receive_hit(sample[0], game.player, attacker, hit.attack)
   assert(game.health == 100.0 - sample[1], "HP loss must use nearest integer for every enemy attack")
   assert(game.match_damage_taken == sample[1])
   assert(game.match_enemy_stats(attacker).damage == sample[1])
   assert(game.damage_numbers[-1].text == str(int(sample[1])))
   assert(game.incoming_damage_feed.entries[0].damage == str(int(sample[1])))
   game._process(0.0)
   assert(game.health_label.text == "%d / 100 HP" % int(game.health))
 game.prevent_player_death = false
 game.health = 11.0
 game.invulnerability = 0.0
 game.receive_hit(10.8, game.player, {"species": "piranha", "tank": false, "boss": false})
 assert(game.state == "lost" and game.fatal_hit.damage == 11.0)
 print("INCOMING ROUNDING PASS: all enemy species, boss attacks, logs, thresholds, HP, indicators, feed, stats and fatal damage")
 game.queue_free()
 await process_frame
 quit(0)
