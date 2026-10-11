extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 game.spawn_timer = 1000
 game.attack_timer = 1000
 game.training.act("pacu")
 assert(game.enemies.size() == 10)
 var fish: Dictionary = game.enemies.back()
 assert(fish.speed == 80 and fish.hp == 80)
 game.enemies.clear()
 game.enemies.append(fish)
 game.cards.activate("furia")
 fish.pos = game.player
 game.update_game(0)
 assert(game.cards.blocked_seconds == 5)
 game.cards.spawn("ima", game.player)
 game.cards.refresh()
 assert(game.cards.pickups[0].sprite.material.get_shader_parameter("blocked"))
 assert(game.cards.indicators.furia.icon.material.get_shader_parameter("blocked"))
 game.cards.activate("perfurante")
 assert(not game.cards.active("perfurante"))
 assert(game.cards.active("furia"), "Existing effects continue")
 game.cards.update_pickups(0)
 assert(game.cards.pickups.size() == 1, "Blocked pickup must remain on the floor")
 game.state = "paused"
 game._process(2)
 assert(game.cards.blocked_seconds == 5, "Pause freezes blocking")
 game.state = "playing"
 game.cards.tick_effects(4)
 game.cards.block_activation()
 assert(game.cards.blocked_seconds == 5, "New hit refreshes duration")
 game.cards.tick_effects(5)
 game.cards.refresh()
 assert(not game.cards.pickups[0].sprite.material.get_shader_parameter("blocked"))
 game.cards.activate("perfurante")
 assert(game.cards.active("perfurante"))
 game.cards.update_pickups(0)
 assert(game.cards.pickups.is_empty())
 game.cards.activate("intangivel")
 game.invulnerability = 0
 fish.pos = game.player
 game.update_game(0)
 assert(game.cards.blocked_seconds == 0, "Protected hits must not block")
 game.cards.block_activation()
 game.cards.reset()
 assert(game.cards.blocked_seconds == 0)
 print("PACU BLOCK PASS: slow spawn, damage, card lock, grayscale, preserved pickup, pause, renewal, immunity and reset")
 quit()
