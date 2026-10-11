extends SceneTree

var game: Node

func _initialize() -> void:
 call_deferred("run")

func fresh(mode: String = "bosses") -> void:
 game.start_run(mode)
 game.test_run = true
 game.spawn_timer = 1000.0
 game.attack_timer = 1000.0

func fish(position: Vector2, hp: float = 100.0) -> Dictionary:
 game.spawn_enemy(false)
 var enemy: Dictionary = game.enemies.back()
 enemy.pos = position
 enemy.speed = 0.0
 enemy.hp = hp
 enemy.max_hp = hp
 return enemy

func test_same_frame_piercing() -> void:
 # Both spears follow the same trajectory in a single update_game call.
 for hp in [30.0, 70.0, 100.0, 120.0]:
  fresh()
  game.magnet = 0.0
  var target := fish(game.player + Vector2(80, 0), hp)
  var next_target := fish(game.player + Vector2(150, 0), 200.0)
  game.damage = 50.0
  game.cards.activate("perfurante")
  game.fire()
  game.fire()
  assert(game.bullets.size() == 2)
  var first: Dictionary = game.bullets[1]
  var second: Dictionary = game.bullets[0]
  for spear in [first, second]:
   spear.pos = game.player + Vector2(50, 0)
   spear.velocity = Vector2(650, 0)
  game.attack_timer = 1000.0
  game.update_game(0.1)
  assert(target.hp == hp - (50.0 if hp <= 50.0 else 100.0), "Same-frame spears must use updated target health")
  assert(first.base_damage == 50.0 and second.base_damage == 50.0)
  assert(game.bullets.size() == 2, "Piercing must continue regardless of target health")
  if hp == 30.0:
   assert(game.bullets.size() == 2)
   assert(target in first.hit_enemies and second.hit_enemies.is_empty(), "The second spear must skip the already dead fish without spending damage")
  elif hp == 70.0:
   assert(target in first.hit_enemies and target in second.hit_enemies)
  assert(game.kills == (1 if hp <= 100.0 else 0), "A same-frame kill must count only once")
  assert(game.gems.size() == (1 if hp <= 100.0 else 0), "A same-frame kill must award XP only once")
  game.update_game(0.0)
  assert(first.hit_enemies.size() == 1)
  assert(second.hit_enemies.size() == (0 if hp == 30.0 else 1), "Repeated overlap must not advance damage tiers")
  game.update_game(0.1)
  assert(next_target.hp == (115.0 if hp == 30.0 else 130.0), "Each spear must maintain its own hit tier, skipping dead targets")
 print("SAME-FRAME PIERCING PASS: 30, 70, 100 and 120 HP; independent hit tiers; single kill and XP")

func test_piercing_through_boss() -> void:
 fresh()
 game.spawn_enemy(true)
 var boss: Dictionary = game.enemies[0]
 boss.pos = game.player + Vector2(150, 0)
 boss.phase = "exposed"
 boss.timer = 100.0
 var targets: Array = [boss]
 for index in 4:
  targets.append(fish(game.player + Vector2(250 + index * 80, 0), 1000.0))
 game.damage = 100.0
 game.cards.activate("perfurante")
 game.fire()
 var spear: Dictionary = game.bullets[0]
 spear.velocity = Vector2.ZERO
 var damage_steps := [100.0, 70.0, 50.0, 20.0, 20.0]
 for index in targets.size():
  var target: Dictionary = targets[index]
  var before: float = target.hp
  spear.pos = target.pos
  game.update_game(0.0)
  assert(target.hp == before - damage_steps[index], "Boss and following targets must receive 100/70/50/20/20 percent")
  assert(game.bullets.size() == 1, "A surviving boss must not stop the spear")
  game.update_game(0.0)
  assert(target.hp == before - damage_steps[index], "Each spear must hit each target only once")
 game.cards.effects.perfurante = 0.0
 var last := fish(game.player + Vector2(650, 0), 1000.0)
 spear.pos = last.pos
 game.update_game(0.0)
 assert(last.hp == 980.0, "In-flight spears must retain piercing after card expiry")
 spear.pos = Vector2(-1, 0)
 game.update_game(0.0)
 assert(game.bullets.is_empty(), "Piercing must still disappear outside the arena")
 fresh()
 game.spawn_enemy(true)
 boss = game.enemies[0]
 boss.pos = game.player + Vector2(150, 0)
 var behind := fish(game.player + Vector2(250, 0), 1000.0)
 game.damage = 100.0
 game.cards.activate("perfurante")
 game.fire()
 spear = game.bullets[0]
 spear.pos = boss.pos
 spear.velocity = Vector2.ZERO
 game.update_game(0.0)
 assert(boss.hp == 32000.0 and spear.hit_enemies.is_empty(), "An immune boss must not consume a hit tier")
 spear.pos = behind.pos
 game.update_game(0.0)
 assert(behind.hp == 900.0)
 print("BOSS PIERCING PASS: 100/70/50/20/20 percent, repeated overlap, expiry, edge and immunity")

func run() -> void:
 root.set_meta("offline_session", true)
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.online.disabled = true
 game.sounds.volumes.master = 0.0
 game.sounds.apply_volumes()
 for id in game.cards.IDS:
  var sound_id: String = "card_" + id
  var stream: AudioStreamWAV = game.sounds.players[sound_id].stream
  assert(is_equal_approx(stream.get_length(), 1.0))
  assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED)
  assert(game.sounds.volume_group(sound_id) == "cards")
  assert(not game.sounds.effect_enabled(sound_id), "Master mute must mute card sounds")
 fresh()
 for sample in [[0.0, 0.01, 0.05], [60.0, 0.008125, 0.04], [120.0, 0.00625, 0.03], [240.0, 0.0025, 0.01], [600.0, 0.0025, 0.01]]:
  game.elapsed = sample[0]
  assert(is_equal_approx(game.cards.drop_chance({"boss": false, "tank": false}), sample[1]), "Piranha drop must decrease linearly and stop at its base")
  assert(is_equal_approx(game.cards.drop_chance({"boss": false, "tank": true}), sample[2]), "Pintado drop must decrease linearly and stop at its base")
 fresh()
 assert(game.cards.drop_chance({"boss": true}) == 0.0)
 fresh("endless")
 assert(game.cards.drop_chance({"boss": true}) == 1.0)
 game.spawn_enemy(true)
 game.enemies.back().hp = 0.0
 game.update_game(0.0)
 assert(game.cards.pickups.size() == 1, "An endless boss must leave exactly one card")
 assert(game.cards.pickups[0].id in game.cards.IDS)
 fresh()
 var floor_position: Vector2 = game.player + Vector2(100, 0)
 game.magnet = 500.0
 game.cards.spawn("furia", floor_position)
 game.update_game(0.25)
 assert(game.cards.pickups.size() == 1 and not game.cards.active("furia"), "XP attraction must not collect cards")
 var pickup: Dictionary = game.cards.pickups[0]
 assert(not is_equal_approx(pickup.sprite.position.y, floor_position.y - game.camera_offset().y), "Card must bob vertically")
 assert(is_equal_approx(pickup.sprite.material.get_shader_parameter("age"), 0.25))
 game.player = floor_position
 game.update_game(0.0)
 assert(game.cards.pickups.is_empty() and game.cards.active("furia"))
 assert(game.speed == 190.0 and game.damage == 20.0 and game.attack_delay == 0.65)
 assert(is_equal_approx(game.effective_speed(), 228.0))
 assert(is_equal_approx(game.effective_damage(), 30.0))
 assert(is_equal_approx(game.effective_attack_delay(), 0.65 / 1.5))
 game.cards.activate("perfurante")
 game.cards.activate("intangivel")
 game.receive_hit(25.0, game.player + Vector2.RIGHT)
 assert(game.health == game.MAX_HEALTH and game.knockback_velocity == Vector2.ZERO)
 game.update_game(5.0)
 game.cards.activate("furia")
 assert(game.cards.effects.furia == 6.0, "Repeat refreshes duration without stacking")
 game.choose_upgrade("speed")
 assert(is_equal_approx(game.effective_speed(), 190.0 * 1.04 * 1.2))
 game.update_game(1.0)
 assert(not game.cards.active("intangivel") and not game.cards.active("perfurante"))
 game.invulnerability = 0.4
 game.receive_hit(10.0, game.player + Vector2.RIGHT)
 assert(game.health == game.MAX_HEALTH, "Card expiry must not cancel post-hit invulnerability")
 game.update_game(5.0)
 assert(not game.cards.active("furia") and is_equal_approx(game.effective_speed(), game.speed))
 fresh()
 var first_cost: int = game.xp_needed()
 game.level = 2
 var second_cost: int = game.xp_needed()
 game.level = 1
 game.gems.append({"pos": game.player + Vector2(-600, 0), "xp": first_cost})
 game.gems.append({"pos": game.player + Vector2(600, 0), "xp": second_cost + 2})
 game.cards.spawn("ima", game.player)
 game.update_game(0.0)
 assert(game.gems.size() == 2 and game.xp == 0 and game.level == 1)
 game.update_game(0.1)
 assert(is_equal_approx(game.gems[0].pos.distance_to(game.player), 537.0), "Global pull must move XP at 630 px/s")
 assert(game.xp == 0, "XP is granted only on arrival")
 game.show_pause()
 var paused_position: Vector2 = game.gems[0].pos
 game._process(0.5)
 assert(game.gems[0].pos == paused_position)
 game.resume()
 game.gems.append({"pos": game.player + Vector2(1000, 0), "xp": 1})
 var screens := 0
 for frame in 30:
  if game.state == "playing": game.update_game(0.05)
  while game.state == "upgrade":
   screens += 1
   game.choose_upgrade(game.choices[0])
 assert(screens == 2 and game.level == 3 and game.gems.size() == 1)
 assert(game.gems[0].pos == game.player + Vector2(1000, 0), "XP created after activation must not inherit global pull")
 assert(game.state == "playing" and game.xp == 2)
 game.cards.activate("ima")
 assert(game.xp == 2 and not game.cards.active("ima"), "Magnet marks existing XP without granting it immediately")
 fresh()
 game.xp_bonus = 10
 for index in 10: game.gems.append({"pos": game.player + Vector2(100, 0), "xp": 1})
 game.cards.activate("ima")
 assert(game.xp == 0)
 game.update_game(0.2)
 while game.state == "upgrade": game.choose_upgrade(game.choices[0])
 assert(game.level == 2 and game.xp == 11 - first_cost and game.xp_remainder == 0, "Magnet must preserve fractional XP bonuses across pickups")
 test_same_frame_piercing()
 test_piercing_through_boss()
 fresh()
 var one := fish(game.player + Vector2(80, 0))
 var two := fish(game.player + Vector2(100, 0))
 one.hp = 10.0
 two.hp = 10.0
 fish(game.player + Vector2(200, 0))
 game.cards.activate("furia")
 game.cards.activate("perfurante")
 game.fire()
 assert(game.bullets[0].piercing and game.bullets[0].life > 4.0)
 game.attack_timer = 1000.0
 game.bullets[0].pos = game.player + Vector2(50, 0)
 game.update_game(0.1)
 assert(one.hp == -20.0 and two.hp == -11.0, "Piercing applies full tier damage even to low-health targets")
 assert(game.bullets.size() == 1)
 assert(game.bullets[0].base_damage == 30.0 and game.bullets[0].hit_enemies.size() == 2)
 game.bullets[0].velocity = Vector2.ZERO
 game.update_game(0.01)
 assert(game.bullets[0].hit_enemies.size() == 2, "Repeated overlap must not advance damage tiers")
 game.cards.effects.perfurante = 0.0
 game.fire()
 assert(not game.bullets.back().piercing and game.bullets[0].piercing)
 game.bullets[0].pos = Vector2(-1, 0)
 game.update_game(0.0)
 assert(game.bullets.size() == 1, "Piercing spear disappears at the arena edge")
 fresh()
 one = fish(game.player + Vector2(80, 0), 30.0)
 two = fish(game.player + Vector2(100, 0), 30.0)
 var third := fish(game.player + Vector2(120, 0), 30.0)
 game.damage = 50.0
 game.cards.activate("perfurante")
 game.fire()
 game.attack_timer = 1000.0
 game.bullets[0].pos = game.player + Vector2(50, 0)
 game.update_game(0.15)
 assert(one.hp == -20.0 and two.hp == -5.0 and third.hp == 5.0)
 assert(game.bullets.size() == 1, "Piercing must continue after its third target")
 fresh()
 one = fish(game.player + Vector2(80, 0), 50.0)
 two = fish(game.player + Vector2(100, 0), 30.0)
 game.damage = 50.0
 game.cards.activate("perfurante")
 game.fire()
 game.attack_timer = 1000.0
 game.cards.activate("furia")
 game.bullets[0].pos = game.player + Vector2(50, 0)
 game.update_game(0.1)
 assert(one.hp == 0.0 and two.hp == -5.0 and game.bullets.size() == 1, "In-flight base damage must stay fixed when Fury activates")
 fresh()
 game.spawn_enemy(true)
 var boss: Dictionary = game.enemies[0]
 boss.pos = game.player + Vector2(150, 0)
 game.cards.activate("furia")
 game.cards.activate("perfurante")
 game.rebuild_projectile_grid()
 assert(game.projectile_target(boss.pos) == -1, "Burrowed boss stays immune")
 boss.phase = "exposed"
 game.rebuild_projectile_grid()
 assert(game.projectile_target(boss.pos) == 0)
 game.hit_with_spear(boss)
 assert(boss.hp == 31970.0)
 fresh()
 game.cards.spawn("ima", game.player + Vector2(200, 0))
 game.cards.activate("furia")
 game.show_pause()
 game._process(0.5)
 assert(game.cards.pickups[0].age == 0.0 and game.cards.effects.furia == 6.0)
 game.resume()
 game.show_upgrades()
 game._process(0.5)
 assert(game.cards.pickups[0].age == 0.0 and game.cards.effects.furia == 6.0)
 game.resume()
 game.cards.update_pickups(25.0)
 assert(game.cards.blink_visible(24.99) and game.cards.blink_visible(25.0))
 assert(not game.cards.blink_visible(25.5) and game.cards.blink_visible(26.0))
 game.cards.update_pickups(4.99)
 assert(game.cards.pickups.size() == 1)
 game.cards.update_pickups(0.02)
 assert(game.cards.pickups.is_empty())
 game.cards.spawn("furia", game.player + Vector2(200, 0))
 fresh()
 assert(game.cards.pickups.is_empty() and not game.cards.active("furia"))
 game.start_run("training")
 assert(not game.training.cards_enabled and not game.training.cards_toggle.button_pressed)
 assert(game.cards.drop_chance({"boss": false, "tank": false}) == 0.0)
 assert(game.cards.drop_chance({"boss": true}) == 0.0)
 game.training.cards_toggle.button_pressed = true
 assert(game.training.cards_enabled)
 assert(is_equal_approx(game.cards.drop_chance({"boss": false, "tank": false}), 0.01))
 assert(is_equal_approx(game.cards.drop_chance({"boss": false, "tank": true}), 0.05))
 game.spawn_enemy(true)
 game.enemies.back().hp = 0.0
 game.update_game(0.0)
 assert(game.cards.pickups.size() == 1, "Enabled training boss must drop a card")
 game.training.cards_toggle.button_pressed = false
 game.spawn_enemy(true)
 game.enemies.back().hp = 0.0
 game.update_game(0.0)
 assert(game.cards.pickups.size() == 1, "Disabled training must not create drops or erase existing cards")
 game.restart_run()
 assert(not game.training.cards_enabled and game.cards.pickups.is_empty())
 game.training.act("cards")
 assert(game.cards.pickups.size() == 4)
 var key := InputEventKey.new()
 key.keycode = KEY_F9
 key.pressed = true
 game.training._input(key)
 assert(game.cards.pickups.size() == 8, "F9 must invoke four test cards")
 game.cards.reset()
 game.gems.append({"pos": game.player + Vector2(100, 0), "xp": 1})
 key.keycode = KEY_1
 key.ctrl_pressed = true
 game.training._input(key)
 assert(game.gems.size() == 1 and game.gems[0].magnetized and game.xp == 0)
 game.update_game(0.2)
 assert(game.gems.is_empty() and game.xp == 1)
 for entry in [[KEY_2, "furia"], [KEY_3, "intangivel"], [KEY_4, "perfurante"]]:
  key.keycode = entry[0]
  game.training._input(key)
  assert(game.cards.effects[entry[1]] == 6.0)
 game.cards.effects.furia = 2.0
 key.keycode = KEY_2
 key.echo = true
 game.training._input(key)
 assert(game.cards.effects.furia == 2.0)
 key.echo = false
 game.show_pause()
 game.training._input(key)
 assert(game.state == "paused" and game.cards.effects.furia == 6.0)
 game.resume()
 game.show_upgrades()
 var chosen_level: int = game.upgrade_levels.get(game.choices[0], 0)
 key.keycode = KEY_1
 game._input(key)
 game._unhandled_key_input(key)
 assert(game.state == "upgrade" and game.upgrade_levels.get(game.choices[0], 0) == chosen_level, "Ctrl+1 must not choose a level upgrade")
 game.start_run("bosses")
 key.keycode = KEY_2
 game.training._input(key)
 assert(not game.cards.active("furia"), "Card shortcuts must be exclusive to training")
 if "--capture" in OS.get_cmdline_user_args():
  game.start_run("training")
  game.training.frame.hide()
  game.training.set_process(false)
  game.set_process(false)
  for index in game.cards.IDS.size():
   game.cards.spawn(game.cards.IDS[index], game.player + Vector2(-150 + index * 100, -60))
  game.cards.activate("furia")
  game.cards.activate("intangivel")
  game.cards.activate("perfurante")
  game.cards.pickups[1].age = 0.85
  game.cards.pickups[2].age = 1.25
  game.cards.refresh()
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/cards-game-preview.png")
 print("CARDS PASS: drops, contact, bob/shine/blink, buffs, XP choices, swept piercing, boss immunity, pause and restart")
 game.queue_free()
 await process_frame
 quit()
