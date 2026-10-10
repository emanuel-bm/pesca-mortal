extends Node
## Host-authoritative co-op. Team shares health, XP, cards and upgrades.
const PORT := 24567
const MAX_PLAYERS := 4
var game: Node2D
var active := false
var running := false
var positions: Dictionary = {}
var inputs: Dictionary = {}
var input_ages: Dictionary = {}
var attack_timers: Dictionary = {}
var timer := 0.0
var connection_time := 0.0
var message := ""

func _ready() -> void:
 multiplayer.peer_connected.connect(_joined)
 multiplayer.peer_disconnected.connect(_left)
 multiplayer.connected_to_server.connect(_connected)
 multiplayer.connection_failed.connect(_failed)
 multiplayer.server_disconnected.connect(_failed)

func host() -> void:
 close()
 var peer := ENetMultiplayerPeer.new()
 var result := peer.create_server(PORT, MAX_PLAYERS - 1)
 if result != OK:
  message = "Não foi possível abrir a porta %d (%s)." % [PORT, error_string(result)]
  lobby()
  return
 multiplayer.multiplayer_peer = peer
 active = true
 positions[1] = game.ARENA / 2
 message = "Sala criada. Compartilhe seu IP Tailscale."
 lobby()

func join(address: String) -> void:
 close()
 if not address.strip_edges().is_valid_ip_address():
  message = "Digite um endereço IP válido."
  lobby()
  return
 var peer := ENetMultiplayerPeer.new()
 var result := peer.create_client(address.strip_edges(), PORT)
 if result != OK:
  message = "Não foi possível conectar: " + error_string(result)
  lobby()
  return
 multiplayer.multiplayer_peer = peer
 active = true
 connection_time = 0.0
 message = "Conectando…"
 lobby()

func close() -> void:
 active = false
 running = false
 multiplayer.multiplayer_peer.close()
 multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
 positions.clear()
 inputs.clear()
 input_ages.clear()
 attack_timers.clear()

func leave() -> void:
 game.run_active = false
 close()
 game.show_menu()

func lobby() -> void:
 game.state = "coop_lobby"
 game.clear_panel()
 game.title("CO-OP ONLINE")
 game.title("Até 4 jogadores · UDP %d\nVida, XP, cartas e melhorias compartilhados" % PORT, 16)
 game.title(message, 16)
 if not active:
  var address := LineEdit.new()
  address.placeholder_text = "IP Tailscale do anfitrião (100.x.x.x)"
  game.panel.add_child(address)
  game.button("Criar sala", host)
  game.button("Entrar por IP", func(): join(address.text))
 elif multiplayer.is_server():
  game.title("Jogadores: %d / %d" % [positions.size(), MAX_PLAYERS], 18)
  game.button("Iniciar modo infinito", begin.bind("endless"))
  game.button("Iniciar modo por chefões", begin.bind("bosses"))
 else:
  game.title("Aguardando o anfitrião iniciar", 18)
 game.button("Voltar / desconectar", leave)
 game.setup_menu_navigation()

func _joined(id: int) -> void:
 if not multiplayer.is_server(): return
 if running:
  multiplayer.multiplayer_peer.disconnect_peer(id)
  return
 positions[id] = game.ARENA / 2 + Vector2(48 * (positions.size()), 0)
 lobby()

func _left(id: int) -> void:
 positions.erase(id)
 inputs.erase(id)
 input_ages.erase(id)
 attack_timers.erase(id)
 if active and not running and multiplayer.is_server(): lobby()

func _connected() -> void:
 message = "Conectado."
 lobby()

func _failed() -> void:
 close()
 game.run_active = false
 message = "Conexão encerrada ou indisponível. Confira IP, Tailscale e firewall."
 lobby()

func begin(mode: String) -> void:
 if not active or not multiplayer.is_server(): return
 for id in positions: positions[id] = game.ARENA / 2 + Vector2(48 * positions.keys().find(id), 0)
 inputs.clear()
 input_ages.clear()
 attack_timers.clear()
 _begin.rpc(mode)

@rpc("authority", "call_local", "reliable")
func _begin(mode: String) -> void:
 if mode not in ["endless", "bosses"]: return
 game.start_run(mode)
 running = true
 game.test_run = true # Co-op results must never enter solo rankings.

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func submit_input(direction: Vector2) -> void:
 var id := multiplayer.get_remote_sender_id()
 if not multiplayer.is_server() or not running or not positions.has(id): return
 if not direction.is_finite(): return
 inputs[id] = direction.limit_length()
 input_ages[id] = 0.0

func tick(dt: float) -> void:
 if not active: return
 if not running:
  connection_time += dt
  if not multiplayer.is_server() and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED and connection_time > 10.0: _failed()
  return
 timer += dt
 if not multiplayer.is_server():
  if timer >= 0.05:
   timer = 0.0
   submit_input.rpc_id(1, game.movement())
  return
 if game.state == "playing":
  var host_position: Vector2 = game.player
  positions[1] = host_position
  for id in positions:
   if id == 1: continue
   input_ages[id] = float(input_ages.get(id, 0.0)) + dt
   var direction: Vector2 = inputs.get(id, Vector2.ZERO) if input_ages[id] < 0.5 else Vector2.ZERO
   positions[id] = (positions[id] + direction * game.effective_speed() * dt).clamp(Vector2(18, 18), game.ARENA - Vector2(18, 18))
   game.player = positions[id]
   attack_timers[id] = float(attack_timers.get(id, 0.0)) - dt
   if attack_timers[id] <= 0.0 and not game.enemies.is_empty():
    game.fire()
    attack_timers[id] = game.effective_attack_delay()
   var host_knockback: Vector2 = game.knockback_velocity
   for enemy in game.enemies:
    if enemy.boss and not game.MINHOCAO.vulnerable(enemy): continue
    if game.invulnerability <= 0.0 and game.enemy_overlaps(enemy, game.player, 14): game.receive_hit(enemy.contact, enemy.pos)
   game.knockback_velocity = host_knockback
   if game.state != "playing":
    game.player = host_position
    break
   for i in range(game.gems.size() - 1, -1, -1):
    if game.gems[i].pos.distance_to(game.player) < game.magnet:
     game.gems[i].pos = game.gems[i].pos.move_toward(game.player, game.XP_ATTRACTION_SPEED * dt)
    if game.gems[i].pos.distance_to(game.player) < 20:
     game.collect_xp(int(game.gems[i].xp))
     game.gems.remove_at(i)
   game.cards.update_pickups(0.0)
  game.player = host_position
  if game.state == "playing": game.show_pending_level_up()
 if timer >= 0.1:
  timer = 0.0
  var projectiles: Array = []
  for bullet in game.bullets:
   projectiles.append({"pos": bullet.pos, "velocity": bullet.velocity, "life": bullet.life, "piercing": bullet.get("piercing", false)})
  var pickups: Array = []
  for pickup in game.cards.pickups: pickups.append({"id": pickup.id, "pos": pickup.pos, "age": pickup.age})
  snapshot.rpc({"positions": positions, "enemies": game.enemies, "bullets": projectiles, "gems": game.gems, "pickups": pickups, "effects": game.cards.effects, "state": game.state, "health": game.health, "max_health": game.max_health, "xp": game.xp, "level": game.level, "kills": game.kills, "elapsed": game.elapsed, "boss_spawned": game.boss_spawned})

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func snapshot(data: Dictionary) -> void:
 if not running: return
 positions = data.positions
 game.player = positions.get(multiplayer.get_unique_id(), game.player)
 game.enemies.assign(data.enemies)
 game.bullets.assign(data.bullets)
 game.gems.assign(data.gems)
 for key in ["health", "max_health", "xp", "level", "kills", "elapsed", "boss_spawned"]: game.set(key, data[key])
 game.cards.reset()
 game.cards.effects = data.effects
 for pickup in data.pickups:
  game.cards.spawn(pickup.id, pickup.pos)
  game.cards.pickups.back().age = pickup.age
 var next: String = data.state
 if game.state != next:
  game.state = next
  game.clear_panel()
  if next == "playing":
   game.overlay.hide()
  else:
   game.title("Vitória!" if next == "won" else "Fim de partida" if next == "lost" else "Aguardando o anfitrião")
   game.title("O anfitrião controla pausas e melhorias da equipe.", 16)
   game.button("Desconectar", leave)
 game.queue_redraw()

func nearest_player(point: Vector2) -> Vector2:
 var nearest: Vector2 = game.player
 if not running: return nearest
 for id in positions:
  if id != 1 and point.distance_squared_to(positions[id]) < point.distance_squared_to(nearest): nearest = positions[id]
 return nearest

func draw_players(canvas: Node2D, offset: Vector2) -> void:
 if not running: return
 for id in positions:
  if id == multiplayer.get_unique_id(): continue
  var point: Vector2 = positions[id] - offset
  if game.canoe_texture:
   var size: Vector2 = game.canoe_region.size / maxf(game.canoe_region.size.x, game.canoe_region.size.y) * 72
   canvas.draw_texture_rect_region(game.canoe_texture, Rect2(point - size / 2, size), game.canoe_region, Color(0.6, 1, 0.75))
  else: canvas.draw_circle(point, 14, Color(0.6, 1, 0.75))
  canvas.draw_string(game.game_font, point + Vector2(-24, -42), "Aliado", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
