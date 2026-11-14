extends Node2D
## Small physical store tasks. The caller owns action progress and calls tick()
## only while the store simulation is running.

signal changed
signal spill_cleaned

const WAREHOUSE_POSITION := Vector2(575,275)
const LEDGER_POSITION := Vector2(65,275)
const INTERACTION_RADIUS := 34.0
const CLEAN_RADIUS := 30.0
const MAX_SPILLS := 3
const SPILL_POSITIONS: Array[Vector2] = [Vector2(264,222),Vector2(430,255),Vector2(90,180)]

var game: Node2D
var spills: Array[Vector2] = []
var rng := RandomNumberGenerator.new()
var until_spill := 120.0
var cleaned_this_shift := 0

func setup(owner_game: Node2D) -> void:
	game = owner_game
	rng.randomize()
	# Floor details stay below characters and the independently sorted furniture.
	z_index = -1
	queue_redraw()

func reset_shift() -> void:
	spills.clear()
	cleaned_this_shift = 0
	_schedule_spill()
	changed.emit()
	queue_redraw()

func _process(_delta: float) -> void:
	visible = is_instance_valid(game) and game.location == "store"
	if visible:
		queue_redraw()

func tick(delta: float) -> void:
	if not _can_interact() or delta <= 0:
		return
	until_spill -= delta
	if until_spill <= 0:
		var available: Array[Vector2] = []
		for point in SPILL_POSITIONS:
			if not spills.has(point):
				available.append(point)
		if not available.is_empty() and spills.size() < MAX_SPILLS:
			add_spill(available[rng.randi_range(0,available.size()-1)])
		_schedule_spill()

func nearest(player_pos: Vector2) -> String:
	if not is_instance_valid(game) or game.location != "store":
		return ""
	var selected := ""
	var distance := INTERACTION_RADIUS
	for point in spills:
		var current := player_pos.distance_to(point)
		if current <= minf(distance,CLEAN_RADIUS):
			distance = current
			selected = "spill"
	for entry in [[WAREHOUSE_POSITION,"warehouse"],[LEDGER_POSITION,"ledger"]]:
		var current := player_pos.distance_to(entry[0])
		if current < distance:
			distance = current
			selected = entry[1]
	return selected

func clean() -> bool:
	if not _can_interact():
		return false
	var chosen := -1
	var distance := CLEAN_RADIUS
	for i in range(spills.size()):
		var current: float = game.player.position.distance_to(spills[i])
		if current <= distance:
			distance = current
			chosen = i
	if chosen < 0:
		return false
	spills.remove_at(chosen)
	cleaned_this_shift += 1
	changed.emit()
	spill_cleaned.emit()
	queue_redraw()
	return true

func spill_count() -> int:
	return spills.size()

func add_spill(point: Vector2) -> void:
	# Restrict external events to audited walkable points. This prevents saved
	# or scripted spills from appearing inside shelves or outside the store.
	if spills.size() >= MAX_SPILLS or not SPILL_POSITIONS.has(point) or spills.has(point):
		return
	spills.append(point)
	changed.emit()
	queue_redraw()

func snapshot() -> Dictionary:
	var entries: Array = []
	for point in spills:
		entries.append([point.x,point.y])
	return {"spills":entries,"until_spill":until_spill,"cleaned":cleaned_this_shift}

func restore(data: Dictionary) -> void:
	spills.clear()
	var entries = data.get("spills",[])
	if entries is Array:
		for entry in entries:
			if entry is Array and entry.size() == 2 and _is_number(entry[0]) and _is_number(entry[1]):
				add_spill(Vector2(float(entry[0]),float(entry[1])))
	var timer = data.get("until_spill",120.0)
	until_spill = clampf(float(timer),1.0,320.0) if _is_number(timer) and is_finite(float(timer)) else 120.0
	var cleaned = data.get("cleaned",0)
	cleaned_this_shift = clampi(int(cleaned),0,10000) if _is_number(cleaned) and is_finite(float(cleaned)) else 0
	changed.emit()
	queue_redraw()

func _is_number(value: Variant) -> bool:
	return value is int or value is float

func _can_interact() -> bool:
	return is_instance_valid(game) and game.location == "store" and game.active and is_instance_valid(game.player)

func _schedule_spill() -> void:
	var multiplier := 1.6 if is_instance_valid(game) and game.progression.owned.has("cleaning") else 1.0
	until_spill = rng.randf_range(100,160)*multiplier

func _draw() -> void:
	if not is_instance_valid(game) or game.location != "store":
		return
	_draw_warehouse()
	_draw_ledger()
	for point in spills:
		_draw_spill(point)
	if not is_instance_valid(game.player):
		return
	var target := nearest(game.player.position)
	if target == "warehouse":
		_draw_marker(Vector2(580,232))
	elif target == "ledger":
		_draw_marker(Vector2(65,254))
	elif target == "spill":
		for point in spills:
			if point.distance_to(game.player.position) <= CLEAN_RADIUS:
				_draw_marker(point+Vector2(0,-9))

func _draw_warehouse() -> void:
	# A low receiving shelf with small, textured cartons; the front remains
	# accessible at WAREHOUSE_POSITION and does not create navigation obstacles.
	draw_rect(Rect2(565,266,36,5),Color(0.12,0.15,0.21,0.32))
	draw_rect(Rect2(565,253,35,15),Color("403b3c"))
	draw_rect(Rect2(566,252,33,3),Color("b09772"))
	_draw_carton(Vector2(566,239),Vector2(16,13))
	_draw_carton(Vector2(584,241),Vector2(14,11))
	_draw_carton(Vector2(568,256),Vector2(13,9))
	_draw_carton(Vector2(584,255),Vector2(13,10))
	draw_rect(Rect2(566,230,32,7),Color("273e47"))
	draw_string(ThemeDB.fallback_font,Vector2(568,236),"BODEGA",HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("e2d2aa"))

func _draw_carton(point: Vector2, dimensions: Vector2) -> void:
	draw_rect(Rect2(point,dimensions),Color("926a49"))
	draw_line(point,point+Vector2(dimensions.x-1,0),Color("d4aa76"))
	draw_line(point+Vector2(0,dimensions.y-1),point+dimensions-Vector2.ONE,Color("684c3e"))
	draw_rect(Rect2(point+Vector2(dimensions.x/2-1,0),Vector2(2,dimensions.y-1)),Color("bbaa83"))
	draw_rect(Rect2(point+Vector2(2,dimensions.y-5),Vector2(4,3)),Color("ddc6a0"))
	draw_line(point+Vector2(3,dimensions.y-4),point+Vector2(5,dimensions.y-4),Color("7b7065"))

func _draw_ledger() -> void:
	# Small wall-mounted writing shelf beside the cash register.
	draw_rect(Rect2(53,265,25,3),Color("655348"))
	draw_rect(Rect2(54,258,23,7),Color("9a8065"))
	draw_rect(Rect2(57,257,15,9),Color("283d48"))
	draw_rect(Rect2(58,257,12,7),Color("e5d7ae"))
	draw_line(Vector2(64,257),Vector2(64,263),Color("b4a17f"))
	for y in [259,261]:
		draw_line(Vector2(59,y),Vector2(62,y),Color("918978"))
		draw_line(Vector2(66,y),Vector2(69,y),Color("918978"))
	draw_line(Vector2(73,257),Vector2(73,264),Color("bd866a"))

func _draw_spill(point: Vector2) -> void:
	var dark := Color(0.18,0.32,0.36,0.65)
	var middle := Color(0.36,0.55,0.56,0.65)
	var shine := Color(0.75,0.86,0.78,0.78)
	var polygon := PackedVector2Array([Vector2(-9,0),Vector2(-7,-3),Vector2(-2,-3),Vector2(0,-5),Vector2(5,-4),Vector2(7,-1),Vector2(10,1),Vector2(7,4),Vector2(2,4),Vector2(-1,3),Vector2(-6,4),Vector2(-9,2)])
	for i in range(polygon.size()): polygon[i] += point
	draw_colored_polygon(polygon,dark)
	draw_rect(Rect2(point+Vector2(-5,-1),Vector2(10,3)),middle)
	draw_line(point+Vector2(-4,-2),point+Vector2(0,-2),shine)
	draw_rect(Rect2(point+Vector2(5,1),Vector2(2,1)),shine)
	draw_rect(Rect2(point+Vector2(-12,1),Vector2(2,1)),middle)
	draw_rect(Rect2(point+Vector2(11,-3),Vector2(1,1)),middle)

func _draw_marker(point: Vector2) -> void:
	var amber := Color("ebd7a2")
	draw_line(point+Vector2(-3,-3),point,amber,1)
	draw_line(point,point+Vector2(3,-3),amber,1)
