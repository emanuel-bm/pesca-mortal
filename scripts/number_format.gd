extends RefCounted

static func integer(value: int) -> String:
 var digits := str(value).trim_prefix("-")
 var grouped := ""
 while digits.length() > 3:
  grouped = "." + digits.right(3) + grouped
  digits = digits.left(digits.length() - 3)
 return ("-" if value < 0 else "") + digits + grouped

static func decimal(value: float, precision: int = 1, trim_zero: bool = true) -> String:
 var parts := (("%." + str(precision) + "f") % value).split(".")
 var whole := integer(int(parts[0]))
 if parts[0].begins_with("-") and int(parts[0]) == 0: whole = "-" + whole
 if parts.size() < 2 or (trim_zero and int(parts[1]) == 0): return whole
 return whole + "," + parts[1]
