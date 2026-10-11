extends Node
## Windows can cover the game without changing its keyboard focus.
signal obscured_changed(value: bool)
var helper_pid := -1
var status_path := ""
var helper_path := ""
var poll_clock := 0.0
var obscured := false

func _ready() -> void:
 if OS.get_name() != "Windows" or DisplayServer.get_name() == "headless": return
 var token := "%d_%d" % [OS.get_process_id(), get_instance_id()]
 status_path = ProjectSettings.globalize_path("user://window_visibility_%s.status" % token)
 helper_path = ProjectSettings.globalize_path("user://window_visibility_%s.ps1" % token)
 var source := FileAccess.open("res://scripts/window_visibility.ps1", FileAccess.READ)
 var target := FileAccess.open(helper_path, FileAccess.WRITE)
 if source == null or target == null:
  push_warning("Não foi possível iniciar a detecção de janelas sobrepostas.")
  return
 target.store_string(source.get_as_text())
 target.close()
 var handle := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, get_window().get_window_id())
 helper_pid = OS.create_process("powershell.exe", PackedStringArray([
  "-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass",
  "-File", helper_path, "-WindowHandle", str(handle), "-StatusPath", status_path
 ]), false)
 if helper_pid == -1: push_warning("Não foi possível iniciar a detecção de janelas sobrepostas.")

func _process(delta: float) -> void:
 poll_clock += delta
 if poll_clock < 0.1: return
 poll_clock = 0.0
 poll_status()

func poll_status() -> void:
 if status_path.is_empty() or not FileAccess.file_exists(status_path): return
 var file := FileAccess.open(status_path, FileAccess.READ)
 if file == null: return
 var value := file.get_as_text()
 if value not in ["0", "1"]: return
 var next := value == "1"
 if next == obscured: return
 obscured = next
 obscured_changed.emit(obscured)

func _exit_tree() -> void:
 if helper_pid != -1 and OS.is_process_running(helper_pid): OS.kill(helper_pid)
 for path in [status_path, helper_path]:
  if not path.is_empty(): DirAccess.remove_absolute(path)
