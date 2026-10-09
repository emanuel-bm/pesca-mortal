extends Node
## Lança gravada e impactos sintetizados sem timbres eletrônicos de glissando.

const SAMPLE_RATE := 22050
var players: Dictionary = {}
var random := RandomNumberGenerator.new()
var last_death_ms := -1000
var last_boss_ms := -1000
var pending_roars: Array[float] = []
var roar_spacing_remaining := 0.0
var roar_voices: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var outgoing_music_player: AudioStreamPlayer
const MUSIC_FADE_SECONDS := 4.0
const MUSIC_OVERLAP_SECONDS := 2.0
var music_streams: Dictionary = {}
var music_track := "calm"
var battle_requested := false
var transition_remaining := -1.0
var music_gain := 1.0
var outgoing_music_gain := 0.0
var music_clock := 0.0
const VOLUME_NAMES := {"master": "Geral", "music": "Música", "boss": "Sons do Minhocão", "shot": "Lança", "death": "Peixes mergulhando", "hurt": "Dano recebido", "level": "Subida de nível"}
const MAX_EFFECT_VOLUME := {"boss": 0.65, "emerge": 0.5, "dash": 0.45, "shot": 0.5, "death": 0.2, "hurt": 0.5, "level": 0.3}
const VOLUME_VERSION := 2
var volumes := {"master": 1.0, "music": 0.7, "boss": 0.8, "shot": 1.0, "death": 1.0, "hurt": 1.0, "level": 1.0}

func _ready() -> void:
 random.randomize()
 for id in ["shot", "death", "hurt", "level", "boss", "emerge", "dash"]:
  var player := AudioStreamPlayer.new()
  if id == "boss": player.stream = load("res://assets/audio/minhocao_roar.wav")
  elif id == "emerge": player.stream = load("res://assets/audio/minhocao_emerge.wav")
  elif id == "dash": player.stream = load("res://assets/audio/minhocao_dash.wav")
  elif id == "shot": player.stream = load("res://assets/audio/spear_swish.wav")
  else: player.stream = synthesize(id)
  player.max_polyphony = 3 if id in ["emerge", "dash"] else 1
  add_child(player)
  players[id] = player
 # Um player exclusivo preserva a música durante pausas e escolhas de melhorias.
 music_player = AudioStreamPlayer.new()
 for id in ["calm", "battle"]:
  var path := "res://assets/audio/correnteza_sombria.wav" if id == "calm" else "res://assets/audio/correnteza_em_furia.wav"
  var theme: AudioStreamWAV = load(path).duplicate()
  theme.loop_mode = AudioStreamWAV.LOOP_FORWARD
  theme.loop_begin = 0
  theme.loop_end = int(theme.get_length() * theme.mix_rate)
  music_streams[id] = theme
 music_player.stream = music_streams.calm
 add_child(music_player)
 outgoing_music_player = AudioStreamPlayer.new()
 add_child(outgoing_music_player)
 load_volumes()

func load_volumes() -> void:
 var config := ConfigFile.new()
 if config.load("user://audio.cfg") == OK and int(config.get_value("audio", "version", 1)) == VOLUME_VERSION:
  for id in volumes: volumes[id] = clampf(float(config.get_value("audio", id, volumes[id])), 0.0, 1.0)
 apply_volumes()
 save_volumes()

func apply_volumes() -> void:
 for id in players:
  players[id].volume_linear = MAX_EFFECT_VOLUME[id] * volumes.master * volumes[volume_group(id)]
  if not effect_enabled(id): players[id].stop()
 for voice in roar_voices:
  voice.volume_linear = MAX_EFFECT_VOLUME.boss * volumes.master * volumes.boss
  if not effect_enabled("boss"): voice.stop()
 if not effect_enabled("boss"):
  pending_roars.clear()
  roar_spacing_remaining = 0.0
  clear_roar_voices()
 apply_music_volume()

func apply_music_volume() -> void:
 if not music_player: return
 music_player.volume_linear = 0.45 * volumes.master * volumes.music * music_gain
 if not effect_enabled("music"):
  music_player.stop()
  outgoing_music_player.stop()
 elif not music_player.playing and DisplayServer.get_name() != "headless":
  music_clock = 0.0
  music_player.play()
 outgoing_music_player.volume_linear = 0.45 * volumes.master * volumes.music * outgoing_music_gain
 if outgoing_music_gain > 0.0 and effect_enabled("music") and not outgoing_music_player.playing and DisplayServer.get_name() != "headless":
  outgoing_music_player.play()

func start_calm_music() -> void:
 var needs_restart := music_track != "calm" or battle_requested
 battle_requested = false
 transition_remaining = -1.0
 music_gain = 1.0
 outgoing_music_gain = 0.0
 outgoing_music_player.stop()
 if needs_restart:
  music_track = "calm"
  music_clock = 0.0
  music_player.stop()
  music_player.stream = music_streams.calm
 apply_music_volume()

func prepare_boss_music(seconds_until_boss: float) -> void:
 # Segue o relógio da partida: pausar antes do chefe também congela o fade.
 if battle_requested: return
 music_gain = smoothstep(0.0, MUSIC_FADE_SECONDS, maxf(0.0, seconds_until_boss + MUSIC_OVERLAP_SECONDS))
 apply_music_volume()

func request_battle_music() -> void:
 # Novos chefões não reiniciam a trilha nem prolongam a transição pendente.
 if battle_requested: return
 battle_requested = true
 # A calma termina os dois segundos finais de seu fade enquanto a nova entra.
 var previous_player := music_player
 music_player = outgoing_music_player
 outgoing_music_player = previous_player
 outgoing_music_gain = music_gain
 music_player.stop()
 music_player.stream = music_streams.battle
 music_track = "battle"
 music_clock = 0.0
 music_gain = 0.0
 transition_remaining = MUSIC_FADE_SECONDS
 apply_music_volume()

func _process(delta: float) -> void:
 update_music(delta)
 update_roars(delta)

func update_music(delta: float) -> void:
 music_clock = fposmod(music_clock + delta, 30.0)
 if transition_remaining >= 0.0:
  transition_remaining = maxf(0.0, transition_remaining - delta)
  var progress := 1.0 - transition_remaining / MUSIC_FADE_SECONDS
  # Fade-in de quatro segundos; saída termina dois segundos após o chefe.
  music_gain = smoothstep(0.0, 1.0, progress)
  var outgoing_remaining := maxf(0.0, transition_remaining - (MUSIC_FADE_SECONDS - MUSIC_OVERLAP_SECONDS))
  outgoing_music_gain = smoothstep(0.0, MUSIC_FADE_SECONDS, outgoing_remaining)
  if outgoing_music_gain <= 0.0: outgoing_music_player.stop()
  if transition_remaining <= 0.0:
   transition_remaining = -1.0
 apply_music_volume()

func volume_group(id: String) -> String:
 return "boss" if id in ["boss", "emerge", "dash"] else id

func effect_enabled(id: String) -> bool:
 return volumes.master > 0.0 and volumes[volume_group(id)] > 0.0

func set_volume(id: String, value: float) -> void:
 volumes[id] = clampf(value, 0.0, 1.0)
 apply_volumes()
 save_volumes()

func save_volumes() -> void:
 var config := ConfigFile.new()
 config.set_value("audio", "version", VOLUME_VERSION)
 for key in volumes: config.set_value("audio", key, volumes[key])
 config.save("user://audio.cfg")

func play_shot() -> void:
 play_effect("shot", 0.96, 1.04)

func play_death() -> void:
 if not effect_enabled("death"): return
 # Limita aglomerados de mortes a um efeito a cada 65 ms.
 var now := Time.get_ticks_msec()
 if now - last_death_ms < 65: return
 last_death_ms = now
 play_effect("death", 0.9, 1.1)

func play_hurt() -> void:
 play_effect("hurt", 0.98, 1.02)

func play_boss_emergence() -> void:
 play_effect("emerge", 0.98, 1.02)

func play_boss_dash() -> void:
 play_effect("dash", 0.98, 1.02)

func announce_boss() -> void:
 request_battle_music()
 if not effect_enabled("boss"): return
 last_boss_ms = Time.get_ticks_msec()
 # Cada chefe conserva seu rugido; os da mesma onda começam desencontrados.
 if roar_spacing_remaining <= 0.0:
  play_roar_voice()
 else:
  pending_roars.append(roar_spacing_remaining)
 roar_spacing_remaining += random.randf_range(0.18, 0.28)

func update_roars(delta: float) -> void:
 roar_spacing_remaining = maxf(0.0, roar_spacing_remaining - delta)
 for index in range(pending_roars.size() - 1, -1, -1):
  pending_roars[index] -= delta
  if pending_roars[index] <= 0.0:
   pending_roars.remove_at(index)
   play_roar_voice()

func play_roar_voice() -> void:
 if not effect_enabled("boss"): return
 var voice := AudioStreamPlayer.new()
 voice.stream = players.boss.stream
 voice.pitch_scale = random.randf_range(0.97, 1.03)
 voice.volume_linear = MAX_EFFECT_VOLUME.boss * volumes.master * volumes.boss
 add_child(voice)
 roar_voices.append(voice)
 voice.finished.connect(on_roar_finished.bind(voice))
 voice.play()

func on_roar_finished(voice: AudioStreamPlayer) -> void:
 roar_voices.erase(voice)
 voice.queue_free()

func clear_roar_voices() -> void:
 for voice in roar_voices:
  voice.stop()
  voice.queue_free()
 roar_voices.clear()

func play_effect(id: String, pitch_min: float, pitch_max: float) -> void:
 if not effect_enabled(id): return
 if DisplayServer.get_name() == "headless": return
 var player: AudioStreamPlayer = players[id]
 player.pitch_scale = random.randf_range(pitch_min, pitch_max)
 player.play()

func reset() -> void:
 pending_roars.clear()
 roar_spacing_remaining = 0.0
 clear_roar_voices()
 for player in players.values(): player.stop()
 last_death_ms = -1000
 last_boss_ms = -1000

func _exit_tree() -> void:
 reset()
 music_player.stop()
 outgoing_music_player.stop()

func synthesize(id: String) -> AudioStreamWAV:
 var duration: float = {"shot": 0.085, "death": 0.45, "hurt": 0.24, "level": 0.65}[id]
 var count := int(SAMPLE_RATE * duration)
 var data := PackedByteArray()
 data.resize(count * 2)
 var phase := 0.0
 var noise := RandomNumberGenerator.new()
 noise.seed = 731
 var filtered_noise := 0.0
 for i in count:
  var t := float(i) / SAMPLE_RATE
  var progress := t / duration
  var frequency := 0.0
  var sample := 0.0
  filtered_noise = lerpf(filtered_noise, noise.randf_range(-1, 1), 0.45)
  match id:
   "level":
    var notes := [392.0, 493.88, 587.33, 783.99]
    var note_index := mini(3, int(t / 0.12))
    var note_time := t - note_index * 0.12
    phase += TAU * notes[note_index] / SAMPLE_RATE
    sample = (sin(phase) + 0.18 * sin(phase * 2.0)) * exp(-note_time * 9) * 0.65
   "shot":
    frequency = lerpf(1400, 320, progress)
    phase += TAU * frequency / SAMPLE_RATE
    sample = sin(phase) * 0.75 + filtered_noise * 0.25
   "death":
    # Mergulho: duas massas de água e cauda abafada, sem oscilador tonal.
    var entry := exp(-pow((t - 0.035) / 0.028, 2))
    var closing_water := exp(-pow((t - 0.13) / 0.055, 2))
    var droplets := pow(maxf(0, sin(t * 113) * sin(t * 67)), 3) * exp(-t * 8)
    sample = filtered_noise * (entry * 1.3 + closing_water * 0.9 + droplets * 0.5)
   "hurt":
    frequency = 72
    phase += TAU * frequency / SAMPLE_RATE
    sample = sin(phase) * exp(-t * 22) * 0.65 + filtered_noise * exp(-t * 35) * 0.35
  # Ataque suave e cauda até zero evitam estalos nas bordas.
  var envelope := minf(t / 0.004, 1.0) * pow(1.0 - progress, 2.0)
  var pcm := int(clampf(sample * envelope, -1, 1) * 28000)
  data.encode_u16(i * 2, pcm & 0xffff)
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = SAMPLE_RATE
 stream.stereo = false
 stream.data = data
 return stream
