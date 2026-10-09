extends RefCounted
## Presentation-only variants. Collision always uses the original artwork.
var variants: Dictionary = {}
var fish_batches: Array[MultiMesh] = []
var fish_sizes: Array[Vector2] = []

func register_art(id: String, texture: Texture2D, region: Rect2, medium: int, low: int) -> void:
 if not texture: return
 var source := texture.get_image().get_region(Rect2i(region))
 var textures: Array[Texture2D] = []
 for maximum in [low, medium]:
  var image := source.duplicate() as Image
  var dimensions := Vector2(source.get_size())
  var size := (dimensions * minf(1.0, float(maximum) / maxf(dimensions.x, dimensions.y))).round().max(Vector2.ONE)
  image.resize(int(size.x), int(size.y), Image.INTERPOLATE_NEAREST)
  textures.append(ImageTexture.create_from_image(image))
 variants[id] = textures

func setup(game: Node) -> void:
 for pair in [["piranha", game.piranha_art, 32, 16], ["pintado", game.pintado_art, 64, 32]]:
  var art: Dictionary = pair[1]
  if art.is_empty(): continue
  register_art(pair[0], art.texture, Rect2(art.region), pair[2], pair[3])
  fish_sizes.append(Vector2(art.region.size) / maxf(art.region.size.x, art.region.size.y))
  var batch := MultiMesh.new()
  batch.transform_format = MultiMesh.TRANSFORM_2D
  batch.use_colors = true
  var quad := QuadMesh.new()
  quad.size = Vector2.ONE
  batch.mesh = quad
  fish_batches.append(batch)
 if game.canoe_texture: register_art("canoe", game.canoe_texture, game.canoe_region, 64, 32)
 if game.player_texture: register_art("player", game.player_texture, Rect2(Vector2.ZERO, game.player_texture.get_size()), 64, 32)
 if game.boss_texture: register_art("boss", game.boss_texture, Rect2(Vector2.ZERO, game.boss_texture.get_size()), 96, 48)

func texture_for(id: String, quality: int, original: Texture2D) -> Texture2D:
 if quality == 2 or not variants.has(id): return original
 return variants[id][quality]

func draw_fish(game: Node2D, view: Rect2, offset: Vector2) -> void:
 if fish_batches.size() != 2: return
 var counts := [0, 0]
 # Capacity grows only when necessary; no reallocation for individual deaths.
 for batch in fish_batches:
  if batch.instance_count < game.enemies.size():
   batch.instance_count = maxi(64, game.enemies.size() * 2)
 for enemy in game.enemies:
  if enemy.boss or not view.grow(enemy.radius + 2).has_point(enemy.pos): continue
  var species := 1 if enemy.tank else 0
  var size: Vector2 = fish_sizes[species] * float(enemy.radius) * 2.0
  var facing := -1.0 if enemy.get("facing_left", false) else 1.0
  var transform := Transform2D(Vector2(size.x * facing, 0), Vector2(0, size.y), Vector2(enemy.pos) - offset)
  fish_batches[species].set_instance_transform_2d(counts[species], transform)
  fish_batches[species].set_instance_color(counts[species], Color(1.7, 1.7, 1.7) if enemy.flash > 0 else Color.WHITE)
  counts[species] += 1
 for species in 2:
  fish_batches[species].visible_instance_count = counts[species]
  if counts[species] > 0:
   game.draw_multimesh(fish_batches[species], variants["pintado" if species == 1 else "piranha"][game.graphics_quality])
