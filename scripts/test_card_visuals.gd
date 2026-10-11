extends SceneTree

class Preview:
 extends Node2D
 var game: Node
 var renderer := preload("res://scripts/card_visuals.gd").new()
 var clock := 0.0

 func _process(dt: float) -> void:
  clock += dt
  queue_redraw()

 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO, Vector2(1152, 720)), Color("101c27"))
  var font := ThemeDB.fallback_font
  draw_string(font, Vector2(45, 65), "CARTAS TEMPORÁRIAS · EFEITOS PIXELADOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("eaf5ff"))
  draw_string(font, Vector2(45, 100), "Quatro camadas independentes no personagem", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("96b2c4"))
  var names := ["FÚRIA", "ÍMÃ", "INTANGIBILIDADE", "PERFURAÇÃO", "TODAS JUNTAS"]
  for index in 5:
   var origin := Vector2(120 + index * 228, 345)
   draw_rect(Rect2(origin - Vector2(108, 165), Vector2(216, 335)), Color("162a39"))
   draw_string(font, origin + Vector2(-95, -130), names[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("d6eaff"))
   draw_set_transform(origin, 0, Vector2.ONE * 1.8)
   var size: Vector2 = game.canoe_region.size / maxf(game.canoe_region.size.x, game.canoe_region.size.y) * 72
   var tint := Color(1.3, 1.2, 1) if index in [3, 4] else Color.WHITE
   draw_texture_rect_region(game.canoe_texture, Rect2(-size / 2, size), game.canoe_region, tint)
   var time := floorf(clock * 20) / 20.0
   if index in [2, 4]: renderer.shield(self, Vector2.ZERO, time, maxf(0, 0.32 - fposmod(clock, 1.8)), Vector2.RIGHT, 1)
   if index in [3, 4]: renderer.piercing(self, Vector2.ZERO, time, 1)
   if index in [0, 4]: renderer.fury(self, Vector2.ZERO, time, 0.18 if index == 4 else 0.0, 1, 1)
   if index in [1, 4]: renderer.magnet(self, Vector2.ZERO, 1 - fposmod(clock, 1.4))
   draw_set_transform(Vector2.ZERO)
  draw_string(font, Vector2(45, 580), "Fúria: cabeça e ombros  ·  Ímã: atração  ·  Defesa: hexágonos  ·  Perfuração: agulhas e clarões", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("96b2c4"))

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.start_run("training")
 game.test_run = true
 for id in game.cards.IDS: game.cards.activate(id)
 var health: float = game.health
 game.receive_hit(15, game.player + Vector2(40, 0))
 assert(game.health == health and game.cards.shield_impact_seconds == 0.32)
 game.cards.attack_feedback()
 assert(game.cards.fury_burst_seconds == 0.24)
 var red: Color = game.cards.visuals.fury_color(Color.RED, Color.YELLOW, 0.0, 1.0)
 var gold: Color = game.cards.visuals.fury_color(Color.RED, Color.YELLOW, game.cards.fury_burst_seconds, 1.0)
 assert(red == Color.RED and gold == Color.YELLOW, "Attack must change the full fury palette to gold")
 game.cards.tick_effects(0.12)
 var remaining: float = game.cards.shield_impact_seconds
 game.receive_hit(15, game.player + Vector2(40, 0))
 assert(is_equal_approx(game.cards.shield_impact_seconds, remaining), "Continuous contact must not restart the shield flash")
 game.cards.tick_effects(0.9)
 assert(game.cards.magnet_visual_seconds == 0.0)
 assert(game.cards.fury_burst_seconds == 0.0 and game.cards.shield_impact_seconds == 0.0)
 for id in ["furia", "intangivel", "perfurante"]: assert(game.cards.active(id))
 game.cards.effects.perfurante = 0.0
 assert(game.cards.player_tint() == Color.WHITE)
 assert(game.cards.active("furia") and game.cards.active("intangivel"))
 game.cards.reset()
 assert(game.cards.visual_age == 0.0 and game.cards.magnet_visual_seconds == 0.0)
 for id in game.cards.effects: assert(not game.cards.active(id))
 print("CARD VISUALS PASS: coexistence, magnet expiry, attack burst, shield block and cooldown, reset")
 if "--capture" in OS.get_cmdline_user_args():
  var preview := Preview.new()
  preview.game = game
  preview.clock = 0.6
  preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  preview.set_process(false)
  root.size = Vector2i(1152, 720)
  root.content_scale_size = Vector2i(1152, 720)
  root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
  var layer := CanvasLayer.new()
  layer.layer = 100
  root.add_child(layer)
  layer.add_child(preview)
  preview.set_process(false)
  for frame in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/card-effects-preview.png")
  layer.free()
 game.queue_free()
 await process_frame
 quit()
