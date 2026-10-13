extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 var feed: Control = game.incoming_damage_feed
 var piranha := {"species": "piranha", "tank": false, "boss": false}
 var pai := {"species": "pai_do_mato", "boss": true}
 game.receive_hit(10, game.player, piranha)
 assert(feed.entries.size() == 1 and feed.entries[0].damage == "10")
 assert(feed.entries[0].card.get_child(0).get_child(0).texture != null)
 game.receive_hit(10, game.player, pai)
 assert(feed.entries.size() == 1, "Invulnerability must suppress entries")
 game.invulnerability = 0
 game.receive_hit(15.5, game.player, pai, "Tronco arremessado")
 assert(feed.entries.size() == 2 and feed.entries[0].aggressor == "Tronco")
 var log_portrait: AtlasTexture = feed.entries[0].card.get_child(0).get_child(0).texture
 assert(log_portrait.atlas == game.log_art.texture and log_portrait.region == Rect2(game.log_art.region))
 assert(feed.entries[0].damage == "15.5")
 game.invulnerability = 0
 game.receive_hit(1, game.player, pai, "Mãozona")
 assert(feed.entries[0].aggressor == "Pai do Mato", "Other boss attacks must retain the boss portrait and name")
 feed.clear()
 game.invulnerability = 0
 game.receive_hit(10, game.player, piranha)
 game.invulnerability = 0
 game.receive_hit(15.5, game.player, pai, "Tronco arremessado")
 feed.refresh(0.25, game)
 assert(feed.entries[1].card.position.y > feed.entries[0].card.position.y)
 var age: float = feed.entries[0].age
 var card_position: Vector2 = feed.entries[0].card.position
 for paused_state in ["paused", "upgrade", "settings"]:
  game.state = paused_state
  feed.refresh(10, game)
  assert(feed.entries[0].age == age and feed.entries[0].card.position == card_position)
 game.state = "playing"
 game.health = 10
 game.invulnerability = 0
 game.receive_hit(30, game.player, piranha)
 assert(game.health == 1 and feed.entries[0].damage == "9")
 game.invulnerability = 0
 game.receive_hit(30, game.player, piranha)
 assert(feed.entries.size() == 3, "No entry when training protection prevents any HP loss")
 game.health = 100
 for i in 6:
  game.invulnerability = 0
  game.receive_hit(i + 1, game.player, piranha)
 assert(feed.entries.size() == 5 and feed.entries[0].damage == "6" and feed.entries[4].damage == "2")
 var original_size: Vector2 = root.size
 root.size = Vector2i(640, 400)
 await process_frame
 feed.refresh(0.0, game)
 assert(feed.position.y + (feed.STEP * 5 - 8) * feed.scale.y <= game.get_viewport_rect().size.y - 15, "Five cards must fit the logical viewport of a short window")
 root.size = Vector2i(original_size)
 game.state = "playing"
 feed.refresh(3.75, game)
 assert(feed.entries[0].card.modulate.a < 1.0)
 feed.refresh(0.26, game)
 assert(feed.entries.is_empty())
 game.start_run("training")
 game.receive_hit(5, game.player, piranha)
 feed.refresh(0.2, game)
 assert(feed.visible)
 game.prevent_player_death = false
 game.invulnerability = 0
 game.health = 10
 game.receive_hit(30, game.player, pai)
 assert(game.state == "lost" and not feed.visible)
 assert(feed.entries.size() == 1, "Fatal hit must only appear on death screen")
 game.start_run("training")
 assert(feed.entries.is_empty())
 if "--capture" in OS.get_cmdline_user_args():
  for attacker in [piranha, pai, {"species": "pacu", "boss": false, "tank": false}]:
   game.invulnerability = 0
   game.receive_hit(12, game.player, attacker)
  feed.refresh(0.5, game)
  game._process(0.0)
  for frame in 3: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/incoming-damage-preview.png")
 print("INCOMING DAMAGE PASS: attribution, portraits, ordering, immunity, training HP loss, pause, cap, fade, expiry, fatal exclusion, restart")
 game.queue_free()
 await process_frame
 quit(0)
