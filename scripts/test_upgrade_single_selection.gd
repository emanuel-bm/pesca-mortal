extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func offer_xp(game: Node) -> void:
 game.show_upgrades()
 while "xp_bonus" not in game.choices: game.show_upgrades()

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 await process_frame
 game.set_process(false)
 game.rng.seed = 42
 for scenario in [["none", false], ["none", true], ["focus", false], ["focus", true]]:
  var block_reason: String = scenario[0]
  var use_mouse: bool = scenario[1]
  game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
  game.start_run("endless")
  game.test_run = true
  game.xp_bonus = 80
  game.level = 10
  game.xp = game.xp_needed()
  game.show_pending_level_up()
  offer_xp(game)
  var selected: int = game.choices.find("xp_bonus")
  var old_button: Button = game.upgrade_buttons[selected]
  var key := InputEventKey.new()
  key.keycode = KEY_1 + selected
  key.pressed = true
  if block_reason == "focus": game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
  if use_mouse: old_button.pressed.emit()
  else: game._input(key)
  for repeat in 20:
   game._input(key)
   old_button.pressed.emit()
  if game.xp_bonus != 100 or game.upgrade_levels.get("xp_bonus", 0) != 1 or game.level != 11:
   push_error("Repeated keyboard/mouse input applied one upgrade more than once: bonus=%d level=%d block=%s" % [game.xp_bonus, game.level, block_reason])
   game.run_active = false
   game.free()
   quit(1)
   return
  if block_reason != "none":
   assert(game.state == "paused", "A consumed upgrade must leave a pause menu while blocked")
   game.resume()
   assert(game.state == "paused", "Continue must stay blocked until focus is restored")
   game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
   game.resume()
  assert(game.state == "playing")
  game.choose_upgrade("xp_bonus")
  assert(game.xp_bonus == 100, "An upgrade cannot be applied without an active choice screen")
 # A callback from a previous screen must not consume a newly queued level.
 game.start_run("endless")
 game.test_run = true
 game.xp = 1000
 game.show_pending_level_up()
 offer_xp(game)
 var old_button: Button = game.upgrade_buttons[game.choices.find("xp_bonus")]
 old_button.pressed.emit()
 assert(game.state == "upgrade" and game.upgrade_levels.xp_bonus == 1)
 offer_xp(game)
 var pending_level: int = game.level
 old_button.pressed.emit()
 assert(game.upgrade_levels.xp_bonus == 1 and game.level == pending_level, "Stale button callbacks must be rejected across upgrade screens")
 var next_id: String = game.choices[0]
 var old_rank: int = game.upgrade_levels.get(next_id, 0)
 game.choose_upgrade(next_id)
 assert(game.upgrade_levels[next_id] == old_rank + 1 and game.level == pending_level + 1, "A fresh choice must still consume the next queued level")
 game.run_active = false
 game.free()
 print("UPGRADE SINGLE SELECTION PASS: keyboard, mouse, focus loss and queued levels")
 quit(0)
