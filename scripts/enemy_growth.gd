extends RefCounted

const EARLY_BONUSES := [0.20, 0.20, 0.10]
const MINIMUM_BONUS := 0.06
const MAX_FISH_DAMAGE_MULTIPLIER := 3.0

static func minute_bonus(minute: int) -> float:
 if minute <= 0: return 0.0
 return EARLY_BONUSES[minute - 1] if minute <= EARLY_BONUSES.size() else MINIMUM_BONUS

static func multiplier(minute: int) -> float:
 var completed := maxi(0, minute)
 var total := 1.0
 for index in mini(completed, EARLY_BONUSES.size()): total += EARLY_BONUSES[index]
 return total + maxi(0, completed - EARLY_BONUSES.size()) * MINIMUM_BONUS

static func damage_multiplier(minute: int, boss: bool = false) -> float:
 var total := multiplier(minute)
 return total if boss else minf(total, MAX_FISH_DAMAGE_MULTIPLIER)
