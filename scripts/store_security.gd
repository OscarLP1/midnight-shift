extends Node2D
var game
var closed := false
var hiding := false
var police := -1.0
var dog: Node2D
var dog_path := PackedVector2Array()
var dog_state := ""
var carrying := false
var dog_in := 65.0
var dirt: Array[Vector2] = []
var dog_sprite: AnimatedSprite2D
var officer: AnimatedSprite2D
var patrol_time := 0.0
var police_state := "idle"
var officer_path := PackedVector2Array()
var repath := 0.0
var detainees: Array[Dictionary] = []
var dog_visits := 0
var dog_action := 0
var stolen_zone := 0
var dog_wait := 0.0
var patrol_x := -90.0
var patrol_texture: Texture2D
func _process(_delta: float) -> void:
	if game!=null: visible = game.location=="store"
func reset() -> void:
	police_state = "idle"
	detainees.clear()
	patrol_time = 0
	if is_instance_valid(officer): officer.free()
	closed = false
	hiding = false
	police = -1
	dog_in = 65
	dirt.clear()
	carrying = false
	if is_instance_valid(dog): dog.free()
	game.actor.modulate.a = 1
func danger() -> bool:
	for p in game.crowd.people:
		if p.evidence: return true
	return false
func toggle_door() -> void:
	if not game.active or game.location!="store": return
	closed = not closed
	game.soundscape.play("door-soft")
	game.message.text = "Entrada cerrada: nadie entra ni sale. Acceso controlado para la policía." if closed else "Entrada abierta."
func hide_player() -> void:
	if not game.active or game.location!="store": return
	if not hiding and game.player.position.distance_to(game.CASHIER)>35:
		game.message.text = "Acércate al mostrador para esconderte."
		return
	hiding = not hiding
	game.actor.modulate.a = 0.12 if hiding else 1.0
	game.message.text = "Bajo el mostrador · H para salir." if hiding else "Has salido del escondite."
func call_police() -> void:
	if not game.active or game.location!="store" or police>=0 or police_state!="idle": return
	police = 20
	game.message.text = "Policía avisada. Llegada estimada: 20 segundos."
func route(target: Vector2) -> void:
	var p := {"node":dog,"bubble":Label.new(),"path":PackedVector2Array()}
	game.crowd.plan(p,target)
	dog_path = p.path
	p.bubble.free()
func spawn_dog() -> void:
	if closed or is_instance_valid(dog): return
	dog = Node2D.new()
	dog.position = Vector2(320,344)
	add_child(dog)
	dog_sprite = game.make_actor("stray-dog")
	dog.add_child(dog_sprite)
	dog_state = "roaming"
	dog_visits = game.crowd.rng.randi_range(3,6)
	dog_action = game.crowd.rng.randi_range(0,2)
	dog_wait = 0
	carrying = false
	route(game.crowd.SPOTS[game.crowd.rng.randi_range(0,7)])
	game.message.text = "Un perro callejero entró a la tienda."
func tick(delta: float) -> void:
	visible = game.location=="store"
	tick_police(delta)
	dog_in -= delta
	if dog_in<=0:
		spawn_dog()
		dog_in = 110
	if is_instance_valid(dog):
		if not dog_path.is_empty():
			if closed and ((dog.position.y<=280 and dog_path[0].y>280) or (dog.position.y>280 and dog_path[0].y<=280)):
				queue_redraw()
				return
			var before: Vector2 = dog.position
			dog.position = dog.position.move_toward(dog_path[0],(110 if carrying else 95)*delta)
			game.Motion.animate(dog_sprite,dog.position-before,80)
			if dog.position.distance_to(dog_path[0])<0.5: dog_path.remove_at(0)
		elif dog_state=="roaming":
			dog_wait += delta
			if dog_wait<0.35: return
			dog_wait = 0
			dog_visits -= 1
			if dog_visits>0:
				route(game.crowd.SPOTS[game.crowd.rng.randi_range(0,7)])
			else:
				if dog_action==1:
					stolen_zone = game.crowd.rng.randi_range(0,2)
					if game.zone_stock[stolen_zone]>0:
						game.zone_stock[stolen_zone] -= 1
						carrying = true
						game.message.text = "¡El perro lleva mercancía! Shift para correr, E para recuperar."
				elif dog_action==2:
					dirt.append(dog.position)
					game.message.text = "El perro ensució el piso. E cerca para limpiar."
				dog_state = "leaving"
				route(Vector2(320,344))
		else:
			if carrying: game.events.losses += game.progression.sale_price()
			dog.free()
			carrying = false

	queue_redraw()
func interact() -> bool:
	if is_instance_valid(dog) and carrying and game.player.position.distance_to(dog.position)<38:
		game.zone_stock[stolen_zone] += 1
		carrying = false
		game.message.text = "Producto recuperado. El perro sale a la calle."
		return true
	for pos in dirt:
		if game.player.position.distance_to(pos)<30:
			dirt.erase(pos)
			game.message.text = "Suelo limpio."
			return true
	return false
func _draw() -> void:
	if game==null: return
	if closed:
		draw_rect(Rect2(279,282,80,5),Color("977854"))
		draw_line(Vector2(310,281),Vector2(310,288),Color("eed49c"),2)
	for pos in dirt:
		draw_circle(pos,4,Color("63442c"))
		draw_circle(pos+Vector2(2,-3),3,Color("775136"))
	if patrol_time>0 and patrol_texture!=null:
		draw_texture_rect(patrol_texture,Rect2(patrol_x,308,88,38),false)
	if is_instance_valid(dog) and carrying:
		draw_rect(Rect2(dog.position+Vector2(10,-7),Vector2(6,5)),Color("e7b85e"))

func police_route(target: Vector2) -> void:
	var start := Vector2i(((officer.position+Vector2(0,20))/8).round())
	officer_path = game.crowd.nav.get_point_path(start,Vector2i((target/8).round()))
	if not officer_path.is_empty(): officer_path.remove_at(0)

func move_officer(delta: float) -> void:
	if officer_path.is_empty(): return
	var before: Vector2 = officer.position
	officer.position = officer.position.move_toward(officer_path[0]-Vector2(0,20),120*delta)
	game.Motion.animate(officer,officer.position-before,120)
	if officer.position.distance_to(officer_path[0]-Vector2(0,20))<0.5: officer_path.remove_at(0)

func begin_chase() -> void:
	police_state = "chasing"
	for p in game.crowd.people:
		if p.thief and p.state!="arrested" and not p.has("escape_allowed"):
			p.escape_allowed = not closed and game.crowd.rng.randf()<0.5
			p.speed = 100
			if p.escape_allowed: game.crowd.leave(p)
			else:
				game.crowd.queue.erase(p)
				p.state = "fleeing"
				game.crowd.plan(p,game.crowd.SPOTS[game.crowd.rng.randi_range(0,7)])
	game.crowd.reorder()

func tick_police(delta: float) -> void:
	if police>=0:
		police -= delta
		if police<=0:
			police = -1
			police_state = "arriving"
			patrol_time = 1
			patrol_x = -90
			patrol_texture = load("res://assets/patrol-car.png")
			return
	if police_state=="arriving":
		patrol_x = move_toward(patrol_x,350,110*delta)
		if patrol_x==350:
			police_state = "parked"
			repath = 0.8
	elif police_state=="parked":
		repath -= delta
		if repath<=0:
			officer = game.make_actor("police-officer")
			officer.position = Vector2(320,324)
			add_child(officer)
			begin_chase()
			game.message.text = "La patrulla estacionó. El agente entra a buscar al ladrón."
	elif police_state=="chasing":
		var target: Dictionary = {}
		var suspects := 0
		for p in game.crowd.people:
			if not p.thief or p.state=="arrested": continue
			suspects += 1
			if closed and p.get("escape_allowed",false):
				p.escape_allowed = false
				p.state = "fleeing"
				game.crowd.plan(p,game.crowd.SPOTS[game.crowd.rng.randi_range(0,7)])
			if not p.has("escape_allowed"):
				begin_chase()
				return
			if not p.escape_allowed: target = p
		if not target.is_empty():
			repath -= delta
			if repath<=0:
				police_route(target.node.position)
				repath = 0.35
			move_officer(delta)
			if (officer.position+Vector2(0,20)).distance_to(target.node.position)<15:
				target.state = "arrested"
				target.path.clear()
				target.evidence = false
				target.bubble.text = "Detenido"
				detainees.append(target)
		elif suspects==0:
			police_state = "escorting"
			police_route(Vector2(320,344))
			for p in detainees: game.crowd.plan(p,Vector2(320,344))
	elif police_state=="escorting":
		move_officer(delta)
		for i in range(detainees.size()):
			var p: Dictionary = detainees[i]
			var before: Vector2 = p.node.position
			if not p.path.is_empty():
				p.node.position = p.node.position.move_toward(p.path[0],110*delta)
				if p.node.position.distance_to(p.path[0])<0.5: p.path.remove_at(0)
			game.Motion.animate(p.sprite,p.node.position-before,120)
		var escorted := true
		for p in detainees:
			if not p.path.is_empty(): escorted = false
		if officer_path.is_empty() and escorted:
			for p in detainees:
				game.crowd.people.erase(p)
				p.node.queue_free()
			detainees.clear()
			officer.queue_free()
			police_state = "departing"
			game.message.text = "La patrulla se lleva a los detenidos."
	elif police_state=="departing":
		patrol_x = move_toward(patrol_x,740,110*delta)
		if patrol_x==740:
			police_state = "idle"
			patrol_time = 0
