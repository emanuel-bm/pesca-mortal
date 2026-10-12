extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.start_run("endless")
 game.set_process(false)
 for count in 5:
  game._apply_upgrade("luck")
  game._apply_upgrade("persistence")
 assert(game.luck == 50 and game.persistence == 25)
 for elapsed in [0.0, 120.0, 240.0, 400.0]:
  game.elapsed = elapsed
  for tank in [false, true]:
   var enemy = {"boss": false, "tank": tank}
   game.luck = 0
   var base = game.cards.drop_chance(enemy)
   game.luck = 50
   assert(is_equal_approx(game.cards.drop_chance(enemy), base * 1.5))
 assert(game.cards.drop_chance({"boss": true}) == 1.0)
 for id in ["furia", "intangivel", "perfurante"]:
  game.cards.activate(id)
  assert(is_equal_approx(game.cards.effects[id], 7.5))
  game.cards.tick_effects(1.0)
  game.cards.activate(id)
  assert(is_equal_approx(game.cards.effects[id], 7.5))
 game.gems.append({"magnetized": false})
 game.cards.activate("ima")
 assert(game.gems.back().magnetized)
 assert(not game.cards.effects.has("ima"))
 game.gems.clear()
 game.start_run()
 assert(game.luck == 0 and game.persistence == 0)
 print("LUCK/PERSISTENCE PASS: additive upgrades, progressive drops, bosses, renewal, magnet and reset")
 quit()
