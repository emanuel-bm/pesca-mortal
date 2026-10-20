extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.set_process(false)
 for species in ["piranha", "pintado", "pacu", "dourado"]:
  game.start_run("training")
  game.prevent_player_death = false
  var enemy := {"species": species, "tank": species == "pintado", "boss": false}
  game.receive_hit(500.0, game.player, enemy)
  assert(game.health == 10.0 and game.state == "playing")
  assert(game.match_damage_taken == 90.0)
  assert(game.damage_numbers[-1].text == "90")
  game.invulnerability = 0.0
  game.receive_hit(500.0, game.player, enemy)
  assert(game.state == "lost" and game.fatal_hit.damage == 90.0)
  assert(game.match_damage_taken == 100.0)
 game.start_run("training")
 var fish := {"species": "piranha", "tank": false, "boss": false}
 game.max_health = 200.0
 game.health = 200.0
 game.receive_hit(500.0, game.player, fish)
 assert(game.health == 20.0, "Cap follows upgraded maximum health")
 game.invulnerability = 0.0
 game.health = 200.0
 game.receive_hit(15.0, game.player, fish)
 assert(game.health == 185.0, "Smaller hits retain their damage")
 game.invulnerability = 0.0
 game.max_health = 101.0
 game.health = 101.0
 game.receive_hit(500.0, game.player, fish)
 assert(game.health == 11.0, "Integer rounding must never exceed 90%")
 for species in ["minhocao", "pai_do_mato"]:
  for attack in ["Contato", "Investida", "Emergência", "Mãozona", "Tronco arremessado"]:
   game.start_run("training")
   game.prevent_player_death = false
   game.receive_hit(500.0, game.player, {"species": species, "boss": true}, attack)
   assert(game.state == "lost" and game.fatal_hit.damage == 500.0)
 print("NORMAL HIT CAP PASS: species, repeated lethal hit, upgraded HP, rounding, stats and uncapped boss attacks")
 game.queue_free()
 await process_frame
 quit(0)
