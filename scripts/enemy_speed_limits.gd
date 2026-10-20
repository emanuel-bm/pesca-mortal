extends RefCounted

const GROWTH = preload("res://scripts/enemy_growth.gd")

static func minute_multiplier(minute: int) -> float:
 return GROWTH.multiplier(minute)

static func capped_speed(base_speed: float, multiplier: float) -> float:
 return base_speed * multiplier
