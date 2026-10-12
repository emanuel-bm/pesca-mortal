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
 assert(fish.speed == 125 and fish.hp == 80)
 game.enemies.clear()
 game.enemies.append(fish)
 game.cards.activate("furia")
 game.cards.activate("perfurante")
 game.gems.append({"pos": game.player + Vector2(500, 0), "xp": 1, "magnetized": false})
 game.cards.activate("ima")
 game.cards.attack_feedback()
 fish.pos = game.player
 game.update_game(0)
 assert(game.cards.blocked_seconds == 5)
 game.cards.spawn("ima", game.player)
 game.cards.refresh()
 assert(game.cards.pickups[0].sprite.material.get_shader_parameter("blocked"))
 assert(game.cards.indicators.furia.icon.material.get_shader_parameter("blocked"))
 game.cards.activate("perfurante")
 assert(not game.cards.active("perfurante"))
 for id in game.cards.effects:
  assert(not game.cards.active(id), "Pacu removes every active timed card")
  assert(not game.cards.indicators[id].item.visible, "Removed effects hide their indicators")
 assert(game.cards.magnet_visual_seconds == 0 and game.cards.fury_burst_seconds == 0 and game.cards.shield_impact_seconds == 0)
 assert(not game.gems[0].magnetized, "Pacu cancels magnet attraction")
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
 assert(game.cards.active("intangivel") and game.cards.active("perfurante"), "Protected hits preserve active cards")
 game.cards.block_activation()
 assert(not game.cards.active("intangivel"), "Blocking clears Intangible too")
 game.cards.reset()
 assert(game.cards.blocked_seconds == 0)
 print("PACU BLOCK PASS: spawn, damage, card removal, magnet cancellation, card lock, grayscale, preserved pickup, pause, renewal, immunity and reset")
 quit()
