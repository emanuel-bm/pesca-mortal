extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var numbers = preload("res://scripts/number_format.gd")
 assert(numbers.integer(999) == "999")
 assert(numbers.integer(1000) == "1.000")
 assert(numbers.integer(640000) == "640.000")
 assert(numbers.integer(90885) == "90.885")
 assert(numbers.integer(1234567890) == "1.234.567.890")
 assert(numbers.integer(-1234) == "-1.234")
 assert(numbers.decimal(1234.5) == "1.234,5")
 assert(numbers.decimal(999.96) == "1.000")
 assert(numbers.decimal(1234.567, 2, false) == "1.234,57")
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 game.kills = 90885
 game.max_health = 200000
 game.health = 190000
 game.xp = 1234
 game.xp_remainder = 50
 game.level = 1000
 game.state = "paused"
 game._process(0)
 assert(game.health_label.text == "190.000 / 200.000 HP")
 assert(game.xp_label.text.begins_with("1.234,5 /"))
 assert(game.hud.text.contains("ELIMINAÇÕES 90.885"))
 assert(game.xp_current_level_label.text == "NÍVEL 1.000")
 assert(game.format_stat("max_health", 200000) == "200.000")
 assert(game.format_stat("damage", 640000) == "640.000")
 game.update_stats_preview()
 assert(game.stat_values.max_health.text == "200.000")
 game.add_damage_number(game.player, 12345)
 assert(game.damage_numbers[-1].text == "12.345")
 game.add_xp_number(game.player, 12345)
 assert(game.damage_numbers[-1].text == "+12.345 XP")
 var values: Array = game.legend_values({"nickname": "Test", "level": 1000, "seconds": 10, "kills": 50413}, "1")
 assert(values[2] == "1.000" and values[4] == "50.413")
 game.match_damage_dealt = 200000.5
 game.match_damage_taken = 640000
 game.show_match_details()
 assert(game.panel.find_children("*", "Label", true, false).any(func(label: Node): return label.text == "Dano causado: 200.000,5 · Dano recebido: 640.000"))
 print("NUMBER FORMAT PASS: thousands, decimals, HP, XP, kills, attributes, indicators, rankings and match statistics")
 game.queue_free()
 await process_frame
 quit(0)
