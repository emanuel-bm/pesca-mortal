extends Node
## Public GitHub release bodies are the source of truth.
signal changed
const SNAPSHOT := "res://assets/release_notes.json"
var cache_path := "user://release_notes.json"
var entries: Array = []
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
 entries = parse_entries(JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT)))
 if FileAccess.file_exists(cache_path):
  var cache: Variant = JSON.parse_string(FileAccess.get_file_as_string(cache_path))
  if cache is Dictionary and cache.get("repository", "") == repository:
   var saved := parse_entries(cache.get("releases", []))
   if not saved.is_empty():
    saved.append_array(entries)
    entries = parse_entries(saved)
 request = HTTPRequest.new()
 request.timeout = 15.0
 request.body_size_limit = 8 * 1024 * 1024
 add_child(request)
 request.request_completed.connect(_completed)

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
  if not item.get("body", "") is String or not item.get("name", "") is String: continue
  seen[tag] = true
  result.append({"tag_name": tag, "name": item.get("name", tag), "body": item.get("body", ""), "published_at": str(item.get("published_at", ""))})
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
 pending.append_array(data)
 if data.size() == 100:
  page += 1
  _fetch()
  return
 var fresh := parse_entries(pending)
 if fresh.is_empty():
  _failed()
  return
 entries = fresh
 pending.clear()
 loading = false
 last_refresh = Time.get_ticks_msec() / 1000.0
 status = ""
 var file := FileAccess.open(cache_path, FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify({"repository": repository, "releases": entries}))
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
 var heading := str(entry.get("name", entry.tag_name))
 var result := "[font_size=24][b]" + escape_bbcode(heading) + "[/b][/font_size]\n\n"
 var body := str(entry.get("body", "")).replace("\r", "")
 if body.strip_edges().is_empty(): return result + "[font_size=16]Esta release não possui notas publicadas.[/font_size]\n"
 for raw_line in body.split("\n"):
  var line := str(raw_line).strip_edges()
  if line.begins_with("```"): continue
  if line.begins_with("# ") and line.trim_prefix("# ") == heading: continue
  var subheading := line.begins_with("#")
  if subheading:
   while line.begins_with("#"): line = line.substr(1)
   line = line.strip_edges()
  if line.begins_with("- ") or line.begins_with("* "): line = "• " + line.substr(2)
  line = line.replace("**", "").replace("`", "")
  var safe := escape_bbcode(line)
  result += ("[font_size=20][b]" + safe + "[/b][/font_size]" if subheading else "[font_size=16]" + safe + "[/font_size]") + "\n"
 return result
