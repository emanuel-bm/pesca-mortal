extends RefCounted

const CAP_MINUTE := 10
const MAX_MULTIPLIER := pow(1.08, CAP_MINUTE)

static func capped_speed(base_speed: float, multiplier: float) -> float:
 return base_speed * minf(multiplier, MAX_MULTIPLIER)
