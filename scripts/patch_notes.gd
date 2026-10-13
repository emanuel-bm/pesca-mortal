extends Node
## Public GitHub release bodies are the source of truth.
signal changed
const SNAPSHOT := "res://assets/release_notes.json"
var cache_path := "user://release_notes_lazy.json"
var entries: Array = []
var selected_tag := ""
var bodies := {}
var body_request: HTTPRequest
var body_loading := false
var body_status := ""
var requested_tag := ""
var repository := ""
var request: HTTPRequest
var loading := false
var status := ""
var pending: Array = []
var page := 1
var last_refresh := -300.0

func _ready() -> void:
 var config := ConfigFile.new()
 if config.load("res://updates.cfg") == OK:
  repository = str(config.get_value("updates", "repository", ""))
 var snapshot: Variant = JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT))
 entries = parse_entries(snapshot)
 for entry: Dictionary in entries:
  if entry.has("body"): bodies[entry.tag_name] = entry.body
 if not entries.is_empty(): selected_tag = entries[0].tag_name
 if FileAccess.file_exists(cache_path):
  var cache: Variant = JSON.parse_string(FileAccess.get_file_as_string(cache_path))
  if cache is Dictionary and cache.get("repository", "") == repository:
   if cache.get("bodies", {}) is Dictionary: bodies.merge(cache.bodies, false)
   var saved := parse_entries(cache.get("releases", []))
   if not saved.is_empty():
    saved.append_array(entries)
    entries = parse_entries(saved)
 request = HTTPRequest.new()
 request.timeout = 15.0
 request.body_size_limit = 8 * 1024 * 1024
 add_child(request)
 request.request_completed.connect(_completed)
 body_request = HTTPRequest.new()
 body_request.timeout = 15.0
 body_request.body_size_limit = 2 * 1024 * 1024
 add_child(body_request)
 body_request.request_completed.connect(_body_completed)

static func parse_entries(data: Variant) -> Array:
 var result: Array = []
 if not data is Array: return result
 var seen := {}
 var version_regex := RegEx.new()
 version_regex.compile("^v?[0-9]+\\.[0-9]+\\.[0-9]+$")
 for item: Variant in data:
  if not item is Dictionary or item.get("draft", false) or item.get("prerelease", false): continue
  var tag := str(item.get("tag_name", ""))
  if version_regex.search(tag) == null or seen.has(tag): continue
  if item.has("body") and not item.body is String: continue
  seen[tag] = true
  var entry := {"tag_name": tag, "name": str(item.get("name", "")), "published_at": str(item.get("published_at", ""))}
  if item.has("body"): entry["body"] = item.body
  result.append(entry)
 result.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.published_at) > str(b.published_at))
 return result

func refresh() -> void:
 if loading: return
 if bool(get_tree().get_meta("offline_session", false)):
  status = "Notas salvas · modo offline"
  changed.emit()
  return
 if Time.get_ticks_msec() / 1000.0 - last_refresh < 300.0: return
 var expression := RegEx.new()
 expression.compile("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
 if expression.search(repository) == null:
  _failed()
  return
 pending.clear()
 page = 1
 loading = true
 status = "Atualizando notas…"
 changed.emit()
 _fetch()

func _fetch() -> void:
 if request.request("https://api.github.com/repos/" + repository + "/releases?per_page=100&page=" + str(page), ["Accept: application/vnd.github+json", "User-Agent: Pesca-Mortal"]) != OK: _failed()

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
 var data: Variant = JSON.parse_string(body.get_string_from_utf8())
 if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not data is Array:
  _failed()
  return
 for item: Variant in data:
  if item is Dictionary:
   var metadata: Dictionary = item.duplicate()
   metadata.erase("body")
   pending.append(metadata)
 if data.size() == 100:
  page += 1
  _fetch()
  return
 var fresh := parse_entries(pending)
 if fresh.is_empty():
  _failed()
  return
 entries = parse_entries(fresh + entries)
 pending.clear()
 loading = false
 last_refresh = Time.get_ticks_msec() / 1000.0
 status = ""
 var file := FileAccess.open(cache_path, FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify({"repository": repository, "releases": entries, "bodies": bodies}))
  file.close()
 changed.emit()

func _failed() -> void:
 loading = false
 pending.clear()
 status = "Sem conexão com as releases · exibindo notas salvas"
 changed.emit()

static func escape_bbcode(value: String) -> String:
 return value.replace("[", "[lb]")

static func text(entry: Dictionary) -> String:
 var heading := str(entry.get("name", "")).strip_edges()
 if heading.is_empty():
  for line: String in str(entry.get("body", "")).split("\n"):
   if line.begins_with("# "):
    heading = line.trim_prefix("# ").strip_edges()
    break
 if heading.is_empty(): heading = "Pesca Mortal " + str(entry.tag_name).trim_prefix("v")
 var result := "[font_size=32][b]" + escape_bbcode(heading) + "[/b][/font_size]\n\n"
 var body := str(entry.get("body", "")).replace("\r", "")
 if body.strip_edges().is_empty(): return result + "[font_size=20]Esta release não possui notas publicadas.[/font_size]\n"
 for raw_line in body.split("\n"):
  var line := str(raw_line).strip_edges()
  if line.begins_with("```"): continue
  if line.begins_with("# ") and line.trim_prefix("# ").strip_edges() == heading: continue
  var subheading := line.begins_with("#")
  if subheading:
   while line.begins_with("#"): line = line.substr(1)
   line = line.strip_edges()
  if line.begins_with("- ") or line.begins_with("* "): line = "• " + line.substr(2)
  line = line.replace("**", "").replace("`", "")
  var safe := escape_bbcode(line)
  result += ("[font_size=32][b]" + safe + "[/b][/font_size]" if subheading else "[font_size=20]" + safe + "[/font_size]") + "\n"
 return result

static func label(entry: Dictionary) -> String:
 var date := str(entry.get("published_at", "")).substr(0, 10).split("-")
 return str(entry.tag_name).trim_prefix("v") + (" · " + date[2] + "/" + date[1] + "/" + date[0] if date.size() == 3 else "")

func select(tag: String) -> void:
 body_request.cancel_request()
 selected_tag = tag
 requested_tag = tag
 body_loading = false
 body_status = ""
 if bodies.has(tag):
  changed.emit()
  return
 if bool(get_tree().get_meta("offline_session", false)):
  body_status = "Conecte-se para baixar estas notas."
  changed.emit()
  return
 body_loading = true
 changed.emit()
 if body_request.request("https://api.github.com/repos/" + repository + "/releases/tags/" + tag.uri_encode(), ["Accept: application/vnd.github+json", "User-Agent: Pesca-Mortal"]) != OK: _body_failed()

func _body_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
 var data: Variant = JSON.parse_string(body.get_string_from_utf8())
 if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not data is Dictionary:
  _body_failed()
  return
 if data.get("tag_name", "") != requested_tag or not data.get("body") is String:
  _body_failed()
  return
 bodies[requested_tag] = data.body
 for entry: Dictionary in entries:
  if entry.tag_name == requested_tag: entry["name"] = str(data.get("name", ""))
 body_loading = false
 body_status = ""
 var file := FileAccess.open(cache_path, FileAccess.WRITE)
 if file: file.store_string(JSON.stringify({"repository": repository, "releases": entries, "bodies": bodies}))
 changed.emit()

func _body_failed() -> void:
 body_loading = false
 body_status = "Não foi possível carregar estas notas. Tente novamente."
 changed.emit()
