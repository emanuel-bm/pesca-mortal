extends RefCounted
## Histórico geral por data; ranking exclusivo do infinito por tempo e eliminações.

const LEGACY_VERSION := "0.3"

static func competitive_version(value: String = "") -> String:
 if value.is_empty(): value = str(ProjectSettings.get_setting("application/config/version", "0.3.0"))
 var parts := value.trim_prefix("v").split(".")
 return parts[0] + "." + parts[1] if parts.size() >= 2 else LEGACY_VERSION

static func for_version(records: Array, version: String) -> Array:
 return normalized(records).filter(func(record: Dictionary) -> bool: return record.competitive_version == version)

static func normalized(records: Array) -> Array:
 var result: Array = []
 for record in records:
  if not record is Dictionary: continue
  var seconds: float = float(record.get("seconds", -1))
  var kills: int = int(record.get("kills", -1))
  if not is_finite(seconds) or seconds < 0 or kills < 0: continue
  result.append({"seconds": seconds, "kills": kills, "date": str(record.get("date", "")), "reason": str(record.get("reason", "death")), "character": str(record.get("character", "Pescador")), "level": maxi(0, int(record.get("level", 0))), "mode": str(record.get("mode", "endless")), "competitive_version": str(record.get("competitive_version", LEGACY_VERSION)), "killer_id": str(record.get("killer_id", "")), "killer_name": str(record.get("killer_name", "")), "fatal_attack": str(record.get("fatal_attack", ""))})
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
 file.store_string(JSON.stringify({"version": 4, "runs": chronological(records)}, "\t"))
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

## IDs estáveis agrupam variantes do mesmo inimigo, independentemente do nome exibido.
static func killer_details(enemy: Dictionary) -> Dictionary:
 if enemy.is_empty(): return {"killer_id": "unknown", "killer_name": "Origem desconhecida"}
 if enemy.get("species", "") == "pai_do_mato": return {"killer_id": "pai_do_mato", "killer_name": "Pai do Mato"}
 if enemy.get("boss", false): return {"killer_id": "minhocao", "killer_name": str(enemy.get("display_name", "Minhocão"))}
 var species := str(enemy.get("species", ""))
 if species not in ["pacu", "dourado"]: species = "pintado" if enemy.get("tank", false) else "piranha"
 return {"killer_id": species, "killer_name": {"piranha": "Piranha", "pintado": "Pintado", "pacu": "Pacu", "dourado": "Dourado"}[species]}

static func deaths_by_enemy(records: Array) -> Dictionary:
 var counts: Dictionary = {}
 for record in normalized(records):
  if record.reason != "death": continue
  var killer_id: String = record.killer_id if not record.killer_id.is_empty() else "unknown"
  counts[killer_id] = int(counts.get(killer_id, 0)) + 1
 return counts
