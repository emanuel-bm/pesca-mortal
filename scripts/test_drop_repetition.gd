extends SceneTree

var game: Node

func _initialize() -> void:
 call_deferred("run")

func fresh(mode: String = "bosses") -> void:
 game.start_run(mode)
 game.test_run = true
 game.spawn_timer = 1000.0
 game.attack_timer = 1000.0

func test_drop_repetition() -> void:
 fresh("training")
 game.training.cards_enabled = true
 assert(game.cards.draw_drop_card(0.20) == "ima")
 assert(game.cards.draw_drop_card(0.20) == "furia", "The previous card must become less likely")
 fresh("training")
 for weight in [0.5, 0.25, 0.125]:
  assert(game.cards.draw_drop_card(0.0) == "ima", "Repeated drops must remain possible")
  assert(is_equal_approx(game.cards.drop_card_weight("ima"), weight))
 assert(game.cards.draw_drop_card(0.5) == "intangivel")
 assert(game.cards.drop_streak == 1 and game.cards.drop_card_weight("ima") == 1.0)
 var previous: String = game.cards.last_drop_id
 game.cards.spawn("perfurante", game.player)
 game.cards.activate("furia")
 assert(game.cards.last_drop_id == previous and game.cards.drop_streak == 1, "Manual cards must not affect history")
 game.training.cards_enabled = false
 game.cards.drop({"boss": true, "pos": game.player})
 assert(game.cards.last_drop_id == previous, "Failed drops must not affect history")
 game.training.cards_enabled = true
 for excluded in game.cards.IDS:
  for roll in [0.0, 0.25, 0.5, 0.75, 1.0]:
   assert(game.cards.draw_drop_card(roll, excluded) != excluded, "Excluded card must never be selected, including endpoints")
 for seed_value in 64:
  game.cards.reset()
  game.rng.seed = seed_value
  game.cards.drop({"boss": true, "species": "pai_do_mato", "pos": game.player})
  assert(game.cards.pickups.size() == 2)
  assert(game.cards.pickups[0].id != game.cards.pickups[1].id, "Pai do Mato must always drop two different cards")
  assert(game.cards.last_drop_id == game.cards.pickups.back().id)
  assert(game.cards.drop_streak == 1, "Double drops must update history sequentially")
 fresh()
 assert(game.cards.last_drop_id == "" and game.cards.drop_streak == 0)
 for index in 1100: game.cards.draw_drop_card(0.0)
 assert(game.cards.drop_card_weight("ima") > 0.0, "Long streaks must never remove a card")
 fresh()
 print("DROP REPETITION PASS: progressive penalty, repeats, switch, manual cards, failed drops, double drops and reset")

func run() -> void:
 root.set_meta("offline_session", true)
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.online.disabled = true
 test_drop_repetition()
 game.queue_free()
 await process_frame
 quit()
