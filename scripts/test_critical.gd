extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.start_run()
 game.set_process(false)
 assert(game.crit_chance == 1)
 game.crit_chance = 0
 game.spawn_enemy(false)
 var enemy = game.enemies.back()
 enemy.hp = 100000.0
 game.hit_with_spear(enemy, 100.0)
 assert(enemy.hp == 99900.0)
 game.crit_chance = 100
 game.hit_with_spear(enemy, 70.0)
 assert(enemy.hp == 99760.0)
 assert(game.damage_numbers.back().font_size == 48)
 assert(game.damage_numbers.back().critical)
 assert(game.damage_numbers.back().color == Color(1.0, 0.5, 0.1))
 game.cards.activate("furia")
 var before = enemy.hp
 game.hit_with_spear(enemy)
 assert(is_equal_approx(before - enemy.hp, game.damage * 3.0))
 game.cards.reset()
 game.crit_chance = 50
 game.rng.seed = 987654
 var normal := 0
 var critical := 0
 for index in 1000:
  before = enemy.hp
  game.hit_with_spear(enemy, 10.0)
  if before - enemy.hp == 20: critical += 1
  else: normal += 1
 assert(critical > 400 and critical < 600 and normal > 0)
 game.start_run("endless")
 game.set_process(false)
 game.crit_chance = 100
 game.cards.activate("perfurante")
 game.spawn_enemy(false)
 game.enemies.back().pos = game.player + Vector2(100, 0)
 game.fire()
 game.enemies.clear()
 var spear = game.bullets[0]
 spear.velocity = Vector2.ZERO
 for index in 3:
  game.spawn_enemy(false)
  var target = game.enemies.back()
  target.hp = 1000.0
  target.pos = game.player + Vector2(100 + index * 100, 0)
  spear.pos = target.pos
  game.crit_chance = 0 if index == 1 else 100
  game.update_game(0.0)
  var expected = [40.0, 14.0, 20.0][index]
  assert(is_equal_approx(1000.0 - target.hp, expected))
  game.update_game(0.0)
  assert(is_equal_approx(1000.0 - target.hp, expected))
 game.spawn_enemy(true)
 var boss = game.enemies.back()
 boss.phase = "hidden"
 before = boss.hp
 game.hit_with_spear(boss, 100.0)
 assert(boss.hp == before)
 game.crit_chance = 98
 game.choose_upgrade("crit_chance")
 assert(game.crit_chance == 100)
 for index in 30:
  game.show_upgrades()
  assert(not "crit_chance" in game.choices)
 game.start_run()
 assert(game.crit_chance == 1)
 print("CRITICAL PASS: 0/50/100%, fury, independent piercing hits, repeat overlap, boss immunity, cap and reset")
 quit()
