extends SceneTree
const NOTES = preload("res://scripts/patch_notes.gd")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 set_meta("offline_session", true)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.online.disabled = true
 game.online.profile = {"nickname": "Teste"}
 game.show_menu()
 for frame in 4: await process_frame
 assert(game.version_badge.visible)
 assert(game.patch_notes.entries.size() >= 9)
 var snapshot: Array = JSON.parse_string(FileAccess.get_file_as_string(NOTES.SNAPSHOT))
 assert(snapshot.filter(func(entry: Dictionary): return entry.has("body")).size() == 1)
 game.open_patch_notes()
 for frame in 4: await process_frame
 assert(game.state == "patch_notes")
 assert(not game.version_badge.visible and not game.profile_panel.visible)
 assert(game.notes_actions.visible and not game.patch_notes.loading)
 assert(game.overlay.size.y >= game.get_viewport_rect().size.y - 26.0)
 assert(is_equal_approx(game.overlay.position.x + game.overlay.size.x / 2.0, game.get_viewport_rect().size.x / 2.0))
 assert(is_equal_approx(game.notes_actions.position.y + game.notes_actions.size.y, game.get_viewport_rect().size.y - 16.0))
 if "--capture" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/patch-notes-live.png")
 var entries := NOTES.parse_entries([
  {"tag_name": "v1.0.0", "name": "Primeira", "body": "- Item [url=bad]texto[/url]", "published_at": "2026-01-01"},
  {"tag_name": "v1.1.0", "name": "Nova", "body": "- Correção", "published_at": "2026-02-01"},
  {"tag_name": "v1.2.0", "draft": true},
  {"tag_name": "v1.3.0", "prerelease": true},
  {"tag_name": "invalid"}])
 assert(entries.size() == 2 and entries[0].tag_name == "v1.1.0")
 assert(NOTES.text(entries[1]).contains("[lb]url=bad]"))
 var saved: Array = game.patch_notes.entries.duplicate(true)
 game.patch_notes.cache_path = "res://.tools/notes-test-cache.json"
 game.patch_notes._completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(entries).to_utf8_buffer())
 assert(game.patch_notes.entries.size() >= 2)
 game.patch_notes._completed(HTTPRequest.RESULT_SUCCESS, 403, [], "{}".to_utf8_buffer())
 assert(game.patch_notes.entries.size() >= 2 and not game.patch_notes.loading)
 game.patch_notes._completed(HTTPRequest.RESULT_SUCCESS, 200, [], "{}".to_utf8_buffer())
 assert(game.patch_notes.entries.size() >= 2)
 game.patch_notes.entries = saved
 var old_tag: String = saved[1].tag_name
 game.show_patch_notes()
 for frame in 3: await process_frame
 for control: Control in game.menu_controls:
  if str(control.get_meta("notes_focus_key", "")) == old_tag: control.grab_focus()
 game.show_patch_notes()
 for frame in 3: await process_frame
 assert(str(root.get_viewport().gui_get_focus_owner().get_meta("notes_focus_key", "")) == old_tag)
 game.patch_notes.changed.emit()
 for frame in 3: await process_frame
 assert(str(root.get_viewport().gui_get_focus_owner().get_meta("notes_focus_key", "")) == old_tag)
 game.patch_notes.bodies.erase(old_tag)
 game.select_patch_note(old_tag)
 assert(game.patch_notes.selected_tag == old_tag)
 assert(not game.patch_notes.body_status.is_empty())
 set_meta("offline_session", false)
 game.select_patch_note(old_tag)
 assert(game.patch_notes.body_loading)
 game.patch_notes.body_request.cancel_request()
 game.patch_notes._body_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify({"tag_name": old_tag, "body": "## Correções\n- Nota anterior"}).to_utf8_buffer())
 assert(not game.patch_notes.body_loading and game.patch_notes.bodies.has(old_tag))
 game.select_patch_note(saved[0].tag_name)
 assert(not game.patch_notes.body_loading)
 assert(NOTES.text(saved[0]).contains("Pesca Mortal"))
 assert(NOTES.text(entries[0]).contains("Nova"))
 game.show_menu()
 for frame in 3: await process_frame
 assert(game.version_badge.visible)
 print("PATCH NOTES PASS: official history, layout, refresh, offline, invalid responses and safe rendering")
 quit()
