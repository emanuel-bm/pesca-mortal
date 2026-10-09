extends RefCounted
## Histórico geral por data; ranking exclusivo do infinito por tempo e eliminações.

static func normalized(records: Array) -> Array:
 var result: Array = []
 for record in records:
  if not record is Dictionary: continue
  var seconds: float = float(record.get("seconds", -1))
  var kills: int = int(record.get("kills", -1))
  if not is_finite(seconds) or seconds < 0 or kills < 0: continue
  result.append({"seconds": seconds, "kills": kills, "date": str(record.get("date", "")), "reason": str(record.get("reason", "death")), "character": str(record.get("character", "Pescador")), "level": maxi(0, int(record.get("level", 0))), "mode": str(record.get("mode", "endless"))})
 return result

static func ranked(records: Array) -> Array:
 var result: Array = normalized(records).filter(func(record: Dictionary) -> bool: return record.mode == "endless")
 result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
  if a.seconds != b.seconds: return a.seconds > b.seconds
  return a.kills > b.kills
 )
 return result

static func chronological(records: Array) -> Array:
 var result := normalized(records)
 result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.date > b.date)
 return result

static func load_records(path: String = "user://endless_runs.json") -> Array:
 if not FileAccess.file_exists(path): return []
 var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
 if not parsed is Dictionary or not parsed.get("runs", null) is Array: return []
 return chronological(parsed.runs)

static func save_records(records: Array, path: String = "user://endless_runs.json") -> Error:
 var file := FileAccess.open(path, FileAccess.WRITE)
 if file == null: return FileAccess.get_open_error()
 file.store_string(JSON.stringify({"version": 2, "runs": chronological(records)}, "\t"))
 return OK

static func time_text(seconds: float) -> String:
 var total := maxi(0, int(seconds))
 return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]

static func character_text(record: Dictionary) -> String:
 var name: String = record.get("character", "Pescador")
 var final_level: int = int(record.get("level", 0))
 return "%s (lv%d)" % [name, final_level] if final_level > 0 else name

static func boss_ranked(records: Array) -> Array:
 var result: Array = normalized(records).filter(func(record: Dictionary) -> bool: return record.mode == "bosses" and record.reason == "won")
 result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
  if a.seconds != b.seconds: return a.seconds < b.seconds
  return a.kills > b.kills
 )
 return result

static func totals(records: Array) -> Dictionary:
 var total := {"seconds": 0.0, "kills": 0, "levels": 0}
 for record in normalized(records):
  total.seconds += record.seconds
  total.kills += record.kills
  total.levels += maxi(0, record.level - 1)
 return total
