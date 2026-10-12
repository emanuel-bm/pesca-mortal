extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var found := {}
 for item in game.find_children("*", "Button", true, false):
  if item.is_visible_in_tree(): found[item.text] = true
 for label in ["Modo infinito", "Modo por chefões", "Sala de treino", "Configurações"]:
  if not found.has(label):
   push_error("Startup menu has no selectable option: " + label)
   game.free()
   quit(1)
   return
 game.free()
 print("STARTUP MENU PASS: game initialization creates visible mode, training and settings buttons")
 quit(0)
