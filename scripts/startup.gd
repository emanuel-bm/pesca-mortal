extends Control
## The same application checks releases before loading the game.
const GAME := "res://main.tscn"
var repository := ""
var asset_name := ""
var executable_name := ""
var release: Dictionary = {}
var asset: Dictionary = {}
var request: HTTPRequest
var message: Label
var actions: VBoxContainer
var status_frame: PanelContainer
var loading: VBoxContainer
var phase := "check"
var leaving := false
var download_path := "user://update.exe"
var using_patch := false
var force_full_update := false

class LoadingSpinner extends Control:
 var angle := 0.0
 func _process(delta: float) -> void:
  if not is_visible_in_tree(): return
  angle = fmod(angle + delta * 4.0, TAU)
  queue_redraw()
 func _draw() -> void:
  draw_arc(size / 2.0, 16.0, angle, angle + TAU * 0.75, 32, Color(0.7, 0.8, 0.9), 3.0, true)

static func version_parts(value: String) -> Array[int]:
 var expression := RegEx.new()
 expression.compile("^v?([0-9]+)\\.([0-9]+)\\.([0-9]+)$")
 var match_value := expression.search(value)
 var parts: Array[int] = []
 if match_value == null: return parts
 for index in range(1, 4): parts.append(int(match_value.get_string(index)))
 return parts

static func newer(remote: String, local: String) -> bool:
 var a := version_parts(remote)
 var b := version_parts(local)
 if a.is_empty() or b.is_empty(): return false
 for index in range(3):
  if a[index] != b[index]: return a[index] > b[index]
 return false

static func select_asset(data: Dictionary, name_value: String, repo: String) -> Dictionary:
 if data.get("draft", false) or data.get("prerelease", false): return {}
 var expected_name := name_value.replace("{version}", str(data.get("tag_name", "")).trim_prefix("v"))
 var entries: Variant = data.get("assets", [])
 if not entries is Array: return {}
 for entry: Variant in entries:
  if not entry is Dictionary or entry.get("name", "") != expected_name: continue
  var url := str(entry.get("browser_download_url", ""))
  var digest := str(entry.get("digest", ""))
  var expression := RegEx.new()
  expression.compile("^sha256:[0-9a-fA-F]{64}$")
  if url.to_lower().begins_with("https://github.com/" + repo.to_lower() + "/releases/download/") and expression.search(digest) != null:
   return entry
 return {}

static func select_patch(data: Dictionary, repo: String, base_hash: String, full: Dictionary) -> Dictionary:
 var patch := select_asset(data, "pesca-mortal-windows-" + base_hash + "-v{version}.patch.gz", repo)
 if not patch.is_empty() and not full.is_empty() and int(patch.get("size", 0)) > 0 and int(patch.get("size", 0)) < int(full.get("size", 0)):
  return patch
 return {}

func _ready() -> void:
 get_window().title = "Pesca Mortal"
 var config := ConfigFile.new()
 if config.load("res://updates.cfg") == OK:
  repository = str(config.get_value("updates", "repository", "")).strip_edges()
  asset_name = str(config.get_value("updates", "windows_asset", ""))
  executable_name = str(config.get_value("updates", "windows_executable", ""))
 _build_ui()
 request = HTTPRequest.new()
 request.timeout = 10.0
 request.body_size_limit = 2 * 1024 * 1024
 add_child(request)
 request.request_completed.connect(_completed)
 if "--update-install-failed" in OS.get_cmdline_user_args():
  force_full_update = true
  _error("Não foi possível instalar a atualização. A versão anterior foi preservada.")
 elif repository.is_empty():
  _set_message("As atualizações ainda não foram ativadas.\nVocê pode jogar a versão instalada.")
  _button("Jogar offline", _play.bind(true))
 else:
  _check()

func _build_ui() -> void:
 var background := ColorRect.new()
 background.color = Color(0.045, 0.055, 0.075)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(center)
 loading = VBoxContainer.new()
 loading.add_theme_constant_override("separation", 18)
 center.add_child(loading)
 var spinner := LoadingSpinner.new()
 spinner.custom_minimum_size = Vector2(40, 40)
 spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 loading.add_child(spinner)
 var loading_text := Label.new()
 loading_text.text = "Verificando atualizações…"
 loading_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 loading_text.add_theme_font_size_override("font_size", 20)
 loading.add_child(loading_text)
 loading.hide()
 var frame := PanelContainer.new()
 status_frame = frame
 center.add_child(frame)
 var margin := MarginContainer.new()
 for side in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + side, 24)
 frame.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 18)
 margin.add_child(column)
 var title := Label.new()
 title.text = "PESCA MORTAL"
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size", 30)
 column.add_child(title)
 var version := Label.new()
 version.text = "Versão " + str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
 version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(version)
 message = Label.new()
 message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(message)
 actions = VBoxContainer.new()
 column.add_child(actions)
 resized.connect(func(): frame.custom_minimum_size.x = minf(540.0, maxf(260.0, size.x - 32.0)))
 frame.custom_minimum_size.x = minf(540.0, maxf(260.0, size.x - 32.0))

func _set_message(value: String) -> void:
 loading.hide()
 status_frame.show()
 message.text = value
 for child in actions.get_children():
  actions.remove_child(child)
  child.queue_free()

func _button(value: String, action: Callable) -> Button:
 var control := Button.new()
 control.text = value
 control.custom_minimum_size.y = 44
 control.pressed.connect(action)
 actions.add_child(control)
 return control

func _check() -> void:
 phase = "check"
 request.download_file = ""
 request.timeout = 10.0
 request.body_size_limit = 2 * 1024 * 1024
 _set_message("Verificando atualizações…")
 status_frame.hide()
 loading.show()
 var expression := RegEx.new()
 expression.compile("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
 if expression.search(repository) == null:
  _error("O endereço de atualizações ainda não foi configurado corretamente.")
  return
 var error := request.request("https://api.github.com/repos/" + repository + "/releases/latest", ["Accept: application/vnd.github+json", "User-Agent: Pesca-Mortal"])
 if error != OK: _play(true)

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
 if leaving: return
 if phase == "download":
  if result != HTTPRequest.RESULT_SUCCESS or code != 200:
   _error("O download falhou. Tente novamente ou jogue offline.")
   return
  _set_message("Conferindo os arquivos da atualização…")
  if FileAccess.get_sha256(download_path).to_lower() != str(asset.digest).trim_prefix("sha256:").to_lower():
   _error("O arquivo baixado está incompleto ou inválido. Tente novamente.")
   return
  _install()
  return
 if result != HTTPRequest.RESULT_SUCCESS or code != 200:
  _play(true)
  return
 var parser := JSON.new()
 if parser.parse(body.get_string_from_utf8()) != OK:
  _play(true)
  return
 var data: Variant = parser.data
 if not data is Dictionary or version_parts(str(data.get("tag_name", ""))).is_empty():
  _play(true)
  return
 release = data
 if not newer(str(release.tag_name), str(ProjectSettings.get_setting("application/config/version", "1.0.0"))):
  _play(false)
  return
 asset = select_asset(release, asset_name, repository)
 using_patch = false
 if OS.get_name() == "Windows" and OS.has_feature("template") and not force_full_update:
  var base_hash := FileAccess.get_sha256(OS.get_executable_path())
  var patch := select_patch(release, repository, base_hash, asset)
  if not patch.is_empty():
   asset = patch
   using_patch = true
 _offer()

func _offer() -> void:
 _set_message("Nova versão disponível: " + str(release.tag_name) + "\nAtualize agora ou continue com a versão instalada em modo offline.")
 if OS.get_name() == "Windows" and OS.has_feature("template"):
  if asset.is_empty():
   _error("O pacote de atualização ainda não está disponível ou não pôde ser validado. Tente novamente ou jogue offline.")
   return
  _button("Baixar atualização", _download)
 else:
  _button("Baixar atualização no GitHub", func(): OS.shell_open("https://github.com/" + repository + "/releases/latest"))
  message.text += "\nNesta plataforma, baixe e instale a nova versão manualmente."
 _button("Jogar offline", _play.bind(true))

func _download() -> void:
 phase = "download"
 download_path = "user://update.exe" if asset_name.to_lower().ends_with(".exe") else "user://update.zip"
 if using_patch: download_path = "user://update.patch.gz"
 request.download_file = download_path
 request.timeout = 300.0
 request.body_size_limit = 1024 * 1024 * 1024
 _set_message("Baixando atualização…")
 _button("Jogar offline", _play.bind(true))
 if request.request(str(asset.browser_download_url), ["User-Agent: Pesca-Mortal"]) != OK:
  _error("Não foi possível iniciar o download.")

func _process(_delta: float) -> void:
 if phase == "download" and is_instance_valid(request) and not leaving:
  message.text = "Baixando atualização… %.1f MB" % (request.get_downloaded_bytes() / 1048576.0)

func _error(value: String) -> void:
 if using_patch:
  force_full_update = true
  using_patch = false
 phase = "error"
 _set_message(value)
 _button("Tentar novamente", _check)
 _button("Jogar offline", _play.bind(true))

func _install() -> void:
 phase = "install"
 if using_patch:
  var codec := FileAccess.open("user://windows_delta.ps1", FileAccess.WRITE)
  if codec == null:
   _error("Não foi possível preparar o patch. Você pode jogar offline.")
   return
  codec.store_string(FileAccess.get_file_as_string("res://scripts/windows_delta.ps1"))
  codec.close()
 var helper := "user://install_update.ps1"
 var script_file := FileAccess.open(helper, FileAccess.WRITE)
 if script_file == null:
  _error("Não foi possível preparar a instalação. Você pode jogar offline.")
  return
 script_file.store_string(FileAccess.get_file_as_string("res://scripts/install_update.ps1"))
 script_file.close()
 var parameters := "user://update-install.json"
 var file := FileAccess.open(parameters, FileAccess.WRITE)
 if file == null:
  _error("Não foi possível preparar a instalação.")
  return
 file.store_string(JSON.stringify({"pid": OS.get_process_id(), "archive": ProjectSettings.globalize_path(download_path), "format": "patch" if using_patch else ("exe" if asset_name.to_lower().ends_with(".exe") else "zip"), "target": OS.get_executable_path(), "entry": executable_name, "sha256": str(asset.digest).trim_prefix("sha256:")}))
 file.close()
 var powershell := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
 var pid := OS.create_process(powershell, ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", ProjectSettings.globalize_path(helper), "-ParametersPath", ProjectSettings.globalize_path(parameters)], false)
 if pid == -1:
  _error("Não foi possível iniciar a instalação. Você pode jogar offline.")
  return
 leaving = true
 get_tree().quit()

func _play(offline: bool) -> void:
 if leaving: return
 leaving = true
 if is_instance_valid(request): request.cancel_request()
 get_tree().set_meta("offline_session", offline)
 get_tree().change_scene_to_file.call_deferred(GAME)
