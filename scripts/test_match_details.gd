extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 await process_frame
 game.set_process(false)
 game.start_run()
 game.test_run = true
 game.crit_chance = 0
 game.spawn_enemy(false)
 var enemy: Dictionary = game.enemies.back()
 enemy.hp = 10.0
 game.hit_with_spear(enemy, 50.0)
 game.hit_with_spear(enemy, 50.0)
 assert(game.match_damage_dealt == 10.0)
 game.spawn_timer = 1000.0
 game.attack_timer = 1000.0
 game.update_game(0.01)
 var enemy_id: String = game.RUN_HISTORY.killer_details(enemy).killer_id
 assert(game.match_enemies[enemy_id].kills == 1)
 game.cards.activate("furia")
 game.cards.tick_effects(2.0)
 game.cards.activate("furia")
 game.cards.tick_effects(8.0)
 assert(game.match_card_uses.furia == 2)
 assert(game.match_card_seconds.furia == 8.0)
 game.cards.blocked_seconds = 1.0
 game.cards.activate("ima")
 assert(game.match_card_uses.ima == 0)
 game.cards.blocked_seconds = 0.0
 game.cards.activate("ima")
 assert(game.match_card_uses.ima == 1 and game.match_card_seconds.ima == 0.0)
 game.cards.activate("intangivel")
 game.receive_hit(20.0, game.player)
 assert(game.match_damage_taken == 0.0)
 game.cards.tick_effects(6.0)
 game.health = 15.0
 game.receive_hit(50.0, game.player, enemy)
 assert(game.match_damage_taken == 15.0 and game.state == "lost")
 assert(game.match_enemies[enemy_id].damage == 15.0)
 assert(game.match_details_button.text == "Estatísticas")
 game.match_details_button.pressed.emit()
 assert(game.state == "match_details")
 assert(not game.run_active)
 game.finish(game.match_won)
 assert(game.state == "lost" and game.match_card_uses.furia == 2)
 assert(game.match_details_button.text == "Estatísticas")
 game.start_run()
 game.test_run = true
 assert(game.match_damage_dealt == 0.0 and game.match_damage_taken == 0.0)
 assert(game.match_card_uses.furia == 0 and game.match_card_seconds.furia == 0.0)
 assert(game.match_enemies.is_empty())
 game.run_active = false
 game.queue_free()
 await process_frame
 print("MATCH DETAILS PASS: damage, card uses, active duration, blocked effects, navigation and reset")
 quit(0)
