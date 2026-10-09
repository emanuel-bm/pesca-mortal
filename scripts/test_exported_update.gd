extends Node
## Run as the main scene of an isolated Windows export to exercise template tags.
func _ready() -> void:
 var startup: Node = load("res://scripts/startup.gd").new()
 add_child(startup)
 if "--update-e2e" in OS.get_cmdline_user_args():
  startup.request.request_completed.connect(func(_result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray):
   if startup.leaving or startup.actions.get_child_count() == 0:
    print("UPDATE E2E FAILED: no update offered")
    get_tree().quit(1)
    return
   var button: Button = startup.actions.get_child(0)
   if button.text != "Baixar atualização":
    print("UPDATE E2E FAILED: " + button.text)
    get_tree().quit(1)
    return
   print("UPDATE E2E: automatic download started")
   button.pressed.emit()
  , CONNECT_ONE_SHOT)
  return
 startup.request.cancel_request()
 var asset := {"name": startup.asset_name, "browser_download_url": "https://github.com/" + startup.repository + "/releases/download/v9.0.0/Pesca-Mortal-Windows.zip", "digest": "sha256:" + "a".repeat(64)}
 startup.release = {"tag_name": "v9.0.0", "assets": [asset]}
 startup.asset = startup.select_asset(startup.release, startup.asset_name, startup.repository)
 startup._offer()
 var action: String = startup.actions.get_child(0).text
 if action != "Baixar atualização":
  print("EXPORTED UPDATE FAILED: " + action)
  get_tree().quit(1)
  return
 startup.asset = {}
 startup._offer()
 if startup.phase != "error" or startup.actions.get_child(0).text != "Tentar novamente":
  print("EXPORTED UPDATE FAILED: invalid package must remain inside the game")
  get_tree().quit(1)
  return
 print("EXPORTED UPDATE PASS: Windows downloads in-app; invalid packages offer retry/offline")
 get_tree().quit()
