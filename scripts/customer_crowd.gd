extends RefCounted

const Motion = preload("res://scripts/character_motion.gd")

var game
var people: Array[Dictionary] = []
var queue: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var nav := AStarGrid2D.new()
var spawn_in := 1.0
var serial := 0
var thief_times: Array[float] = []
var thieves_spawned := 0
var withdrawal_in := 0.0
var last_look := -1
var look_bag: Array[int] = []
var visits_log: Array[Vector2] = []
const SPOTS = [Vector2(192,192),Vector2(352,192),Vector2(512,192),Vector2(96,104),Vector2(208,104),Vector2(320,104),Vector2(432,104),Vector2(544,104)]

func setup(owner_game) -> void:
	game = owner_game
	rng.randomize()
	nav.region = Rect2i(0,0,80,45)
	nav.cell_size = Vector2(8,8)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.update()
	for y in range(45):
		for x in range(80):
			var p := Vector2(x*8,y*8)
			var blocked: bool = not game.walkable_store(p,true)
			for rect in game.obstacles:
				if rect.grow(8).has_point(p): blocked = true
			nav.set_point_solid(Vector2i(x,y),blocked)

func reset() -> void:
	for p in people: p.node.queue_free()
	people.clear()
	queue.clear()
	visits_log.clear()
	spawn_in = 1
	withdrawal_in = 0
	last_look = -1
	look_bag.clear()
	thieves_spawned = 0
	thief_times.clear()
	for i in range(rng.randi_range(2,4)): thief_times.append(45.0+i*110.0+rng.randf_range(0,25))

func spawn() -> void:
	if look_bag.is_empty():
		look_bag.assign([0,1,2,3,4,5,6])
	var appearance_index := rng.randi_range(0,look_bag.size()-1)
	if look_bag.size()>1 and look_bag[appearance_index]==last_look: appearance_index = (appearance_index+1)%look_bag.size()
	var look := look_bag[appearance_index]
	look_bag.remove_at(appearance_index)
	last_look = look
	var body := Node2D.new()
	body.position = Vector2(320,344)
	var asset: String = "employee-modern" if look<4 else ["customer-woman","customer-senior","customer-courier"][look-4]
	var sprite: AnimatedSprite2D = game.make_actor(asset)
	if look<4:
		var palette := ShaderMaterial.new()
		palette.shader = preload("res://scripts/customer_palette.gdshader")
		palette.set_shader_parameter("jacket",[Color("a85542"),Color("b69948"),Color("786397"),Color("507297")][look])
		palette.set_shader_parameter("hair",[Color("45352e"),Color("9c8058"),Color("77717a"),Color("292c3c")][look])
		sprite.material = palette
	body.add_child(sprite)
	var bubble := Label.new()
	bubble.position = Vector2(-25,-57)
	bubble.add_theme_font_size_override("font_size",10)
	bubble.add_theme_color_override("font_color",Color.WHITE)
	bubble.add_theme_color_override("font_outline_color",Color.BLACK)
	bubble.add_theme_constant_override("outline_size",4)
	bubble.z_index = 12
	body.add_child(bubble)
	game.add_child(body)
	var targets: Array[Vector2] = []
	var indexes := [0,1,2,3,4,5,6,7]
	for i in range(rng.randi_range(1,3)):
		var pick := rng.randi_range(0,indexes.size()-1)
		targets.append(SPOTS[indexes[pick]])
		indexes.remove_at(pick)
	serial += 1
	var p := {"id":serial,"node":body,"sprite":sprite,"bubble":bubble,"look":look,"state":"shopping","targets":targets,"path":PackedVector2Array(),"wait":0.0,"patience":rng.randf_range(55,110),"speed":rng.randf_range(36,49),"basket":0,"items":[],"thief":not thief_times.is_empty() and game.elapsed>=thief_times[0],"evidence":false,"lost":false}
	if p.thief:
		thief_times.pop_front()
		thieves_spawned += 1
		var outfit: AnimatedSprite2D = game.make_actor("burglar")
		sprite.sprite_frames = outfit.sprite_frames
		outfit.free()
		sprite.material = null
	people.append(p)
	plan(p,targets[0])

func plan(p: Dictionary, target: Vector2) -> void:
	p.bubble.text = ""
	var start := Vector2i((p.node.position/8).round())
	var end := Vector2i((target/8).round())
	p.path = nav.get_point_path(start,end)
	if not p.path.is_empty(): p.path.remove_at(0)

func leave(p: Dictionary) -> void:
	queue.erase(p)
	p.state = "leaving"
	p.bubble.text = ""
	plan(p,Vector2(320,344))
	reorder()

func reorder() -> void:
	for i in range(queue.size()): plan(queue[i],game.CUSTOMER_CHECKOUT+Vector2(i*32,0))

func tick(delta: float) -> void:
	spawn_in -= delta
	if game.elapsed>=game.events.horror_start()-60:
		withdrawal_in -= delta
		if withdrawal_in<=0:
			for visitor in people:
				if visitor.state not in ["leaving","arrested","fleeing"]:
					leave(visitor)
					break
			withdrawal_in = 12.0
	if not game.security.closed and spawn_in<=0 and people.size()<5 and game.elapsed<game.events.horror_start()-60:
		spawn()
		spawn_in = rng.randf_range(7,13)
	for p in people.duplicate():
		if p.state=="arrested": continue
		if not p.thief and game.security.closed and (game.security.danger() or game.security.police_state!="idle") and p.state!="sheltering":
			queue.erase(p)
			p.state = "sheltering"
			plan(p,Vector2(184+(p.id%3)*24,264))
		if p.state=="sheltering":
			p.bubble.text = "A salvo · esperando"
			if not game.security.closed and not game.security.danger():
				p.sprite.scale = Vector2.ONE
				leave(p)
			elif p.path.is_empty():
				p.sprite.scale.y = 0.65
				continue
		if p.state=="fleeing" and not game.security.closed and game.security.police_state=="idle": leave(p)
		if p.state=="queue" and not p.thief:
			var stocked := false
			for product in p.items:
				if game.zone_stock[game.product_zone(product)]>0: stocked = true
			if not stocked: leave(p)
		if p.state=="fleeing" and p.path.is_empty(): plan(p,SPOTS[rng.randi_range(0,7)])
		if not p.path.is_empty():
			var target: Vector2 = p.path[0]
			if game.security.closed and ((p.node.position.y<=280 and target.y>280) or (p.node.position.y>280 and target.y<=280)):
				p.bubble.text = "Puerta cerrada"
				if p.thief:
					p.state = "fleeing"
					p.speed = 95
					plan(p,SPOTS[rng.randi_range(0,7)])
				else:
					p.state = "sheltering"
					plan(p,Vector2(184+(p.id%3)*24,264))
				continue
			var before: Vector2 = p.node.position
			p.node.position = p.node.position.move_toward(target,p.speed*delta)
			Motion.animate(p.sprite,p.node.position-before,p.speed)
			if p.node.position.distance_to(target)<0.5:
				p.path.remove_at(0)
				if p.path.is_empty() and p.state=="queue": Motion.face(p.sprite,0)
			continue
		Motion.animate(p.sprite,Vector2.ZERO)
		if p.state == "shopping": Motion.face(p.sprite,1)
		elif p.state == "queue": Motion.face(p.sprite,0)
		if p.state == "shopping":
			p.wait += delta
			p.bubble.text = "Mirando…"
			if p.wait>=2.5+(p.id%3):
				var visited: Vector2 = p.targets.pop_front()
				visits_log.append(visited)
				var product_names := ["Papas Crujín", "Fideos Nube", "Jabón Claro", "Agua Bruma", "Jugo Aurora", "Leche Alba", "Yogur Nieve", "Queso Fresco"]
				var spot_index := SPOTS.find(visited)
				var product_zone: int = spot_index
				if product_zone<0 or product_zone>=game.zone_stock.size() or game.zone_stock[product_zone]<=0:
					p.bubble.text = "Agotado · se va"
					leave(p)
					continue
				if spot_index<3:
					p.items.append(game.exploration.PRODUCTS[spot_index][rng.randi_range(0,2)])
				else: p.items.append(product_names[spot_index])
				p.basket += 1
				p.wait = 0
				if p.thief:
					p.evidence = true
					var amount: int = mini(game.zone_stock[spot_index],rng.randi_range(1,5))
					game.zone_stock[spot_index] -= amount
					p.stolen_zone = spot_index
					p.stolen_count = amount
					p.lost = true
					game.events.losses += amount*game.progression.sale_price()
					p.state = "concealing"
					p.bubble.text = "Oculta un artículo"
				elif p.targets.is_empty():
					p.state = "queue"
					queue.append(p)
					reorder()
				else: plan(p,p.targets[0])
		elif p.state == "concealing":
			p.wait += delta
			if p.wait>3:
				p.speed = 95
				leave(p)
		elif p.state == "queue":
			p.wait += delta
			p.bubble.text = "%d artículos" % p.basket
			if p.wait>p.patience: leave(p)
		elif p.state == "leaving":
			if p.thief and p.evidence and not p.lost:
				p.lost = true
				var zone: int = game.product_zone(p.items[0]) if not p.items.is_empty() else 0
				var lost: int = mini(game.zone_stock[zone],1)
				game.zone_stock[zone] -= lost
				game.events.losses += lost*4
			people.erase(p)
			p.node.queue_free()

func first() -> Dictionary:
	for person in queue:
		if not person.thief and person.state=="queue" and person.path.is_empty(): return person
	return {}

func intervene() -> bool:
	for p in people:
		if p.evidence and p.node.position.distance_to(game.player.position)<48:
			p.evidence = false
			if p.get("stolen_count",0)>0:
				game.zone_stock[p.stolen_zone] += p.stolen_count
				game.events.losses -= p.stolen_count*game.progression.sale_price()
				p.stolen_count = 0
			p.items.clear()
			p.basket = 0
			leave(p)
			game.message.text = "Recuperaste la mercancía. El ladrón intenta huir."
			return true
	return false

func frighten() -> void:
	for p in people:
		if p.state in ["arrested","sheltering"]: continue
		leave(p)
		p.speed = 105.0
		p.bubble.text = "¡Vámonos!"
