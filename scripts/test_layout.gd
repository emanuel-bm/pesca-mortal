extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func check_menu(game: Node) -> bool:
 var visible_area: Rect2 = game.get_viewport_rect()
 var rect: Rect2 = game.overlay.get_global_rect()
 if rect.get_center().distance_to(visible_area.get_center()) > 2:
  push_error("Painel principal deve ficar no centro da tela")
  return false
 if game.records_panel and game.records_panel.visible:
  var records: Rect2 = game.records_panel.get_global_rect()
  if records.intersects(rect) or not visible_area.encloses(records):
   push_error("Recordes devem ficar à esquerda, dentro da tela e separados")
   return false
 if game.boss_records_panel and game.boss_records_panel.visible:
  var boss_records: Rect2 = game.boss_records_panel.get_global_rect()
  if boss_records.intersects(rect) or boss_records.position.x <= rect.end.x or not visible_area.encloses(boss_records):
   push_error("Ranking de chefões deve ficar à direita, separado e dentro da tela")
   return false
 if game.state == "paused" and not game.stats_panel.visible:
  push_error("Pausa deve mostrar atributos")
  return false
 if game.stats_panel.visible:
  var stats: Rect2 = game.stats_panel.get_global_rect()
  if stats.intersects(rect) or stats.position.x <= rect.end.x or stats.size.y <= rect.size.y:
   push_error("Atributos devem ficar à direita, separados e mais altos")
   return false
 if not visible_area.encloses(rect):
  push_error("Menu fora da tela: %s; tela: %s" % [rect, visible_area])
  return false
 if game.modal_row.get_global_rect().get_center().distance_to(visible_area.get_center()) > 2:
  push_error("Menu não centralizado: %s" % rect)
  return false
 if game.stats_panel.visible and not visible_area.encloses(game.stats_panel.get_global_rect()):
  push_error("Tabela de atributos fora da tela")
  return false
 for child in game.panel.get_children():
  if not rect.encloses(child.get_global_rect()):
   push_error("Conteúdo fora do painel: %s" % child.get_global_rect())
   return false
 return true

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.online.profile = {"nickname": "Teste"}
 game.online.rankings = {"endless": [], "bosses": []}
 for index in 10:
  game.online.rankings.endless.append({"nickname": "Pescador_123456789012", "seconds": 600.0 - index, "kills": 100})
 for resolution in [Vector2i(640, 400), Vector2i(800, 600), Vector2i(1152, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160), Vector2i(900, 1000)]:
  root.size = resolution
  for screen in ["menu", "settings", "paused", "upgrade", "won", "lost", "history", "nickname", "global_ranking"]:
   match screen:
    "menu": game.show_menu()
    "settings": game.show_settings()
    "paused": game.show_pause()
    "upgrade": game.show_upgrades()
    "won": game.finish(true)
    "lost": game.finish(false)
    "history": game.show_history()
    "nickname": game.show_nickname()
    "global_ranking": game.show_global_ranking()
   for frame in 5: await process_frame
   if not check_menu(game):
    push_error("Falha em %s / %s" % [resolution, screen])
    quit(1)
    return
  print("LAYOUT PASS: %s, nove telas" % resolution)
 game.show_menu()
 for frame in 5: await process_frame
 var started := false
 for child in game.panel.get_children():
  if child is Button and child.text == "Modo por chefões":
   child.pressed.emit()
   started = game.state == "playing" and not game.overlay.visible
 if not started:
  push_error("Botão Começar não iniciou a partida")
  quit(1)
  return
 game.update_game(0.1)
 if game.enemies.is_empty():
  push_error("Partida não gerou inimigos")
  quit(1)
  return
 print("START PASS: botão inicia partida e gera inimigos")
 if "--capture" in OS.get_cmdline_user_args():
  root.size = Vector2i(1152, 720)
  game.show_menu()
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/layout.png")
  for screen in ["nickname", "global_ranking"]:
   if screen == "nickname": game.show_nickname()
   else: game.show_global_ranking()
   for frame in 5: await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://.tools/online-%s.png" % screen)
 quit(0)
