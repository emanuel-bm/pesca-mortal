extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.set_process(false)
 game.update_stats_preview()
 for frame in 3: await process_frame
 var heights := {}
 for id in game.stat_values:
  heights[id] = game.stat_values[id].get_parent().get_combined_minimum_size().y
 for selected in game.stat_values:
  game.update_stats_preview(selected)
  for frame in 3: await process_frame
  for id in game.stat_values:
   assert(is_equal_approx(heights[id], game.stat_values[id].get_parent().get_combined_minimum_size().y), "Highlight must not change attribute row height: " + id)
 print("STATS PREVIEW LAYOUT PASS: all attribute rows keep their height when highlighted")
 game.free()
 quit()
