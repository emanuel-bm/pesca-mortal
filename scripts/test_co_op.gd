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
 var visual_before: Vector2 = games[1].player
 games[1].coop.submit_input.rpc_id(1, Vector2.RIGHT)
 await create_timer(0.05).timeout
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 assert(games[1].player == visual_before, "Receiving a later snapshot must not teleport the camera")
 games[1].coop.tick(0.01)
 assert(games[1].player.x > visual_before.x, "Client movement must advance between network snapshots")
 assert(games[1].player.x < games[0].coop.positions[id].x, "A render frame must interpolate instead of jumping to the target")
 games[1].coop.smooth_snapshot(0.2)
 assert(games[1].player == games[0].coop.positions[id], "Interpolation must stop at the latest host position when packets are late")
 var entities: Array[Dictionary] = [{"net_id": 1, "pos": Vector2.ZERO}, {"net_id": 2, "pos": Vector2(100, 0)}]
 games[1].coop.receive_entities(entities, [{"net_id": 2, "pos": Vector2(110, 0)}, {"net_id": 1, "pos": Vector2(10, 0)}, {"net_id": 3, "pos": Vector2(500, 0)}], false)
 assert(entities[0].pos == Vector2(100, 0) and entities[1].pos == Vector2.ZERO, "Reordered entities must interpolate from their own previous positions")
 assert(entities[2].pos == Vector2(500, 0), "New entities must appear at their spawn position")
 games[1].coop.receive_entities(entities, [{"net_id": 2, "pos": Vector2(1000, 0)}], false)
 assert(entities.size() == 1 and entities[0].pos == Vector2(1000, 0), "Removed entities must disappear and teleports must snap")
 games[0].cards.spawn("furia", Vector2(200, 200))
 games[0].show_pause()
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 var card_sprite: Sprite2D = games[1].cards.pickups[0].sprite
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 assert(games[1].cards.pickups[0].sprite == card_sprite, "Unchanged cards must reuse sprites across snapshots")
 games[0].health = 23
 games[0].show_pause()
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 assert(games[1].health == 23 and games[1].state == "paused")
 games[0].resume()
 games[0].coop.tick(0.1)
 await create_timer(0.1).timeout
 assert(games[1].state == "playing" and not games[1].overlay.visible)
 games[0].show_pause()
 games[0].coop.timer = 0.0
 games[1].coop.timer = 0.0
 var snapshots_before: int = games[0].coop.snapshots_sent
 var inputs_before: int = games[1].coop.inputs_sent
 for frame in 100:
  games[0].coop.tick(0.01)
  games[1].coop.tick(0.01)
  await process_frame
 assert(games[0].coop.snapshots_sent - snapshots_before == 30, "100 FPS must retain timer remainder to send 30 snapshots per second")
 assert(games[1].coop.inputs_sent - inputs_before == 60, "100 FPS must send 60 inputs per second")
 games[0].enemies.clear()
 for index in 1000: games[0].spawn_enemy(index == 999)
 for index in games[0].enemies.size(): games[0].enemies[index].net_id = index + 1
 var packed: Dictionary = games[0].coop.pack_enemies(games[0].enemies)
 var decoded: Array = games[0].coop.unpack_enemies(packed)
 assert(decoded.size() == 1000 and decoded.back().phase == games[0].enemies.back().phase)
 assert(decoded.back().dash_end == games[0].enemies.back().dash_end, "Compact snapshots must preserve boss telegraphs")
 var old_bytes := var_to_bytes(games[0].enemies).size()
 var new_bytes := var_to_bytes(packed).size()
 assert(new_bytes * 30 < old_bytes * 10 / 2, "30 Hz compact enemy data must use less than half the old 10 Hz bandwidth")
 var started := Time.get_ticks_usec()
 for iteration in 30:
  var_to_bytes(games[0].coop.pack_enemies(games[0].enemies))
 var packing_ms := (Time.get_ticks_usec() - started) / 1000.0
 print("CO-OP HORDE: 1000 enemies, full=%d B, compact=%d B, old10Hz=%d B/s, new30Hz=%d B/s per client, pack+encode30=%.2f ms" % [old_bytes, new_bytes, old_bytes * 10, new_bytes * 30, packing_ms])
 games[0].coop.tick(1.0 / 30.0)
 await create_timer(0.15).timeout
 for client in games.slice(1):
  assert(client.enemies.size() == 1000 and client.enemies.back().boss, "All three clients must decode a 1000-enemy snapshot")
 games[3].coop.leave()
 await create_timer(0.1).timeout
 assert(games[0].coop.positions.size() == 3)
 games[0].coop.leave()
 await create_timer(0.1).timeout
 assert(not games[1].coop.active and not games[1].run_active)
 for game in games: game.get_parent().queue_free()
 await process_frame
 print("CO-OP PASS: four peers, 30 Hz snapshots, 60 Hz inputs, compact hordes, interpolation, pause, disconnect and solo ranking isolation")
 quit()
