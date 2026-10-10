extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var games: Array[Node] = []
 for index in 4:
  var viewport := SubViewport.new()
  viewport.name = "Peer%d" % index
  root.add_child(viewport)
  var api := SceneMultiplayer.new()
  set_multiplayer(api, viewport.get_path())
  var game: Node = load("res://main.tscn").instantiate()
  game.name = "Game"
  viewport.add_child(game)
  game.set_process(false)
  games.append(game)
 await process_frame
 games[0].coop.host()
 assert(games[0].coop.active)
 for index in range(1, 4): games[index].coop.join("127.0.0.1")
 for step in 100:
  await create_timer(0.01).timeout
  if games[0].coop.positions.size() == 4: break
 assert(games[0].coop.positions.size() == 4, "All three clients must join")
 games[0].coop.begin("endless")
 await create_timer(0.1).timeout
 for game in games:
  assert(game.coop.running and game.test_run, "Start must reach every peer and exclude solo ranking")
 var id: int = games[1].multiplayer.get_unique_id()
 var before: Vector2 = games[0].coop.positions[id]
 games[1].coop.submit_input.rpc_id(1, Vector2.RIGHT)
 await create_timer(0.1).timeout
 games[0].spawn_timer = 100
 games[0].update_game(0.01)
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 assert(games[0].coop.positions[id].x > before.x, "Client input must move its own canoe")
 assert(games[1].player == games[0].coop.positions[id], "Snapshot must center client camera on its canoe")
 assert(games[1].enemies.size() == games[0].enemies.size())
 games[0].health = 23
 games[0].show_pause()
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 assert(games[1].health == 23 and games[1].state == "paused")
 games[0].resume()
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 assert(games[1].state == "playing" and not games[1].overlay.visible)
 games[3].coop.leave()
 await create_timer(0.1).timeout
 assert(games[0].coop.positions.size() == 3)
 games[0].coop.leave()
 await create_timer(0.1).timeout
 assert(not games[1].coop.active and not games[1].run_active)
 for game in games: game.get_parent().queue_free()
 await process_frame
 print("CO-OP PASS: four peers, start, input, snapshots, pause, disconnect and solo ranking isolation")
 quit()
