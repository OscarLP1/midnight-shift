extends RefCounted

static var PATH := "user://midnight_save.json"

static func load_game() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary and int(parsed.get("version",0)) in [1,2]:
		return parsed
	return {}

static func write_game(money: int, night: int, upgrades: Array = [], stock: int = 12, location: String = "store", inventory: Array = []) -> bool:
	var file = FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 2, "money": money, "night": night, "upgrades": upgrades, "stock": stock, "location": location, "inventory": inventory}))
	file.close()
	return DirAccess.rename_absolute(PATH + ".tmp", PATH) == OK

