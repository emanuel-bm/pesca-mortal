extends RefCounted
## The export feature keeps the public build and its account storage unchanged.
const ID := "festival-high-tech-mt"
const NAME := "Festival High Tech MT"
const PROFILE_NAME := "Festival Hightech"

static func enabled() -> bool:
 return OS.has_feature("festival") or "--festival" in OS.get_cmdline_user_args()

static func valid_name(value: String) -> bool:
 var name := value.strip_edges()
 if name.is_empty() or name.length() > 30: return false
 for index in range(name.length()):
  var character := name.substr(index, 1)
  var letter := character.to_lower() != character.to_upper()
  var digit := character >= "0" and character <= "9"
  if not letter and not digit and (index == 0 or character not in [" ", "_", ".", "-"]): return false
 return true
