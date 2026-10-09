extends Node
## Identity, personal-record outbox and cached public ranking. No admin secrets.
signal changed

const RULESET := "pesca-1"
const DEFAULT_PATH := "user://online_ranking.json"
var storage_path := DEFAULT_PATH
var endpoint := ""
var profile: Dictionary = {}
var pending: Dictionary = {}
var rankings: Dictionary = {"endless": [], "bosses": []}
var fetched_at := ""
var status := ""
var busy := false
var disabled := false
var network_disabled := false
var request: HTTPRequest
var action := ""
var sent_record: Dictionary = {}
var refresh_requested := false
var response_redirects := 0

func _ready() -> void:
 var config := ConfigFile.new()
 if config.load("res://online.cfg") == OK:
  endpoint = str(config.get_value("ranking", "url", "")).strip_edges()
 load_state()
 request = HTTPRequest.new()
 request.timeout = 20.0
 # Google rejects a redirected GET that retains the original POST body.
 # Read ContentService's response explicitly with an empty GET instead.
 request.max_redirects = 0
 add_child(request)
 request.request_completed.connect(_completed)

func load_state() -> void:
 if not FileAccess.file_exists(storage_path): return
 var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
 if not data is Dictionary: return
 if data.get("profile") is Dictionary: profile = data.profile
 if data.get("pending") is Dictionary: pending = data.pending
 if data.get("rankings") is Dictionary: rankings = data.rankings
 fetched_at = str(data.get("fetched_at", ""))

func save_state() -> bool:
 var temporary := storage_path + ".tmp"
 var file := FileAccess.open(temporary, FileAccess.WRITE)
 if file == null:
  status = "Não foi possível salvar os dados da conta neste computador."
  changed.emit()
  return false
 file.store_string(JSON.stringify({"profile": profile, "pending": pending, "rankings": rankings, "fetched_at": fetched_at}))
 file.flush()
 var write_error := file.get_error()
 file.close()
 if write_error == OK and DirAccess.rename_absolute(temporary, storage_path) == OK: return true
 status = "Não foi possível salvar os dados da conta neste computador."
 changed.emit()
 return false

func nickname() -> String:
 return str(profile.get("nickname", ""))

static func valid_nickname(value: String) -> bool:
 var regex := RegEx.new()
 regex.compile("^[A-Za-z0-9_]{3,20}$")
 return regex.search(value) != null

static func better(candidate: Dictionary, previous: Dictionary) -> bool:
 if previous.is_empty(): return true
 if candidate.seconds != previous.seconds:
  return candidate.seconds < previous.seconds if candidate.mode == "bosses" else candidate.seconds > previous.seconds
 return candidate.kills > previous.kills

func set_nickname(value: String) -> void:
 if busy or disabled: return
 if network_disabled:
  status = "Conecte-se ao ranking para cadastrar ou alterar seu nome."
  changed.emit()
  return
 value = value.strip_edges()
 if not valid_nickname(value):
  status = "Use de 3 a 20 letras sem acentos, números ou _."
  changed.emit()
  return
 if endpoint.is_empty():
  status = "O ranking global ainda não foi ativado."
  changed.emit()
  return
 if not profile.has("token"):
  profile["token"] = Crypto.new().generate_random_bytes(32).hex_encode()
  # Persist before registration: a lost response must not orphan a reserved name.
  if not save_state(): return
 _send("rename" if profile.has("player_id") else "register", {"nickname": value})

func queue_record(record: Dictionary) -> void:
 if record.mode == "bosses" and record.reason != "won": return
 var mode: String = record.mode
 if pending.has(mode) and not better(record, pending[mode]): return
 var previous: Dictionary = pending.duplicate(true)
 pending[mode] = {"mode": mode, "seconds": record.seconds, "kills": record.kills, "level": record.level, "character": record.character, "reason": record.reason, "ruleset": RULESET, "run_id": Crypto.new().generate_random_bytes(16).hex_encode()}
 if not save_state():
  pending = previous
  return
 if not busy and not disabled: _next()

func synchronize() -> void:
 if disabled or network_disabled: return
 if endpoint.is_empty():
  status = "O ranking global ainda não foi ativado."
  changed.emit()
  return
 refresh_requested = true
 if not busy: _next()

func _next() -> void:
 if busy or disabled or network_disabled or endpoint.is_empty(): return
 if profile.has("player_id") and not pending.is_empty():
  var mode: String = str(pending.keys()[0])
  sent_record = pending[mode].duplicate(true)
  _send("submit", {"record": sent_record})
 elif refresh_requested:
  refresh_requested = false
  _send("ranking", {})

func _send(operation: String, payload: Dictionary) -> void:
 if not endpoint.begins_with("https://") and not endpoint.begins_with("http://127.0.0.1:"):
  status = "O serviço de ranking está indisponível."
  changed.emit()
  return
 action = operation
 response_redirects = 0
 payload["action"] = operation
 if operation != "ranking":
  payload["token"] = profile.get("token", "")
  payload["player_id"] = profile.get("player_id", "")
 busy = true
 status = "Atualizando ranking…" if operation in ["ranking", "submit"] else "Salvando nome…"
 changed.emit()
 # Only the first request sends credentials; the redirect reads a JSON response.
 var error := request.request(endpoint, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
 if error != OK:
  busy = false
  status = "Sem conexão. Seu recorde continua salvo neste computador."
  changed.emit()

func _completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
 if code in [301, 302, 303] and response_redirects < 3:
  var location := ""
  for header in headers:
   if header.to_lower().begins_with("location:"):
    location = header.substr(header.find(":") + 1).strip_edges()
  if location.begins_with("/") and endpoint.begins_with("http://127.0.0.1:"):
   location = endpoint.substr(0, endpoint.find("/", 7)) + location
  var allowed := location.begins_with("https://script.googleusercontent.com/macros/echo?")
  if endpoint.begins_with("http://127.0.0.1:"):
   allowed = location.begins_with(endpoint.substr(0, endpoint.find("/", 7)) + "/response/")
  if allowed:
   response_redirects += 1
   if request.request(location, [], HTTPClient.METHOD_GET, "") == OK: return
 busy = false
 var parser := JSON.new()
 var data: Variant = null
 if result == HTTPRequest.RESULT_SUCCESS and code == 200 and parser.parse(body.get_string_from_utf8()) == OK:
  data = parser.data
 if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not data is Dictionary or not data.get("ok", false):
  var error_code := str(data.get("error", "")) if data is Dictionary else ""
  status = "Sem conexão. Seu recorde continua salvo neste computador."
  if error_code == "nickname_taken": status = "Esse nome já está em uso. Escolha outro."
  elif error_code == "invalid_nickname": status = "Use de 3 a 20 letras sem acentos, números ou _."
  elif error_code == "unauthorized": status = "Não foi possível autenticar esta conta."
  elif error_code in ["invalid_record", "unsupported_ruleset"]:
   var mode := str(sent_record.get("mode", ""))
   if pending.get(mode, {}).get("run_id", "") == sent_record.get("run_id", ""):
    pending.erase(mode)
    save_state()
   status = "Recorde recusado: " + str(data.get("message", "dados incompatíveis com as regras."))
  changed.emit()
  return
 if action in ["register", "rename"]:
  if not data.get("player_id") is String or not data.get("nickname") is String or not valid_nickname(data.nickname):
   status = "Não foi possível confirmar o cadastro. Tente novamente."
   changed.emit()
   return
  var previous := profile.duplicate(true)
  profile["player_id"] = str(data.player_id)
  profile["nickname"] = str(data.nickname)
  if not save_state():
   profile = previous
   return
  status = "Nome salvo."
  refresh_requested = true
 elif action == "submit":
  var mode: String = str(sent_record.mode)
  if pending.get(mode, {}).get("run_id", "") == sent_record.run_id: pending.erase(mode)
  if not save_state(): return
  status = "Recorde sincronizado."
 elif action == "ranking":
  if not data.get("rankings") is Dictionary:
   status = "Não foi possível ler o ranking."
   changed.emit()
   return
  for mode in ["endless", "bosses"]:
   if not data.rankings.get(mode) is Array:
    status = "Não foi possível ler o ranking."
    changed.emit()
    return
   for entry in data.rankings[mode]:
    if not entry is Dictionary or not entry.get("nickname") is String or not (entry.get("seconds") is float or entry.get("seconds") is int) or not (entry.get("kills") is float or entry.get("kills") is int):
     status = "Não foi possível ler o ranking."
     changed.emit()
     return
  rankings = data.rankings
  fetched_at = Time.get_datetime_string_from_system()
  save_state()
  status = "Ranking atualizado."
 changed.emit()
 _next()
