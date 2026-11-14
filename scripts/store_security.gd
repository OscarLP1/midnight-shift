extends Node2D
var game
var hide_amount := 0.0
var wheel_phase := 0.0
var arrested_total := 0
var dog_caught := false
var escort_trail: Array[Vector2] = []
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
func _process(delta: float) -> void:
	if game==null: return
	visible = game.location=="store"
	if game.active:
		hide_amount = move_toward(hide_amount,1.0 if hiding else 0.0,delta*3)
	game.actor.scale.y = lerpf(1.0,0.3,hide_amount)*(1.6 if game.location in ["cafe","hardware","atelier"] else 1.0)
	game.actor.position.y = lerpf(-20,-5,hide_amount)
	game.actor.modulate.a = 1.0-hide_amount
	if is_instance_valid(dog): dog.visible = visible
	if is_instance_valid(officer): officer.visible = visible
	queue_redraw()
func reset() -> void:
	police_state = "idle"
	arrested_total = 0
	hide_amount = 0
	dog_caught = false
	detainees.clear()
	patrol_time = 0
	if is_instance_valid(officer): officer.free()
	closed = false
	hiding = false
	police = -1
	dog_in = 35
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
	if hiding: game.player.position = game.CASHIER
	game.actor.z_index = -1 if hiding else 0
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
	game.add_child(dog)
	dog_caught = false
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
		dog_in = game.crowd.rng.randf_range(45,75)
	if is_instance_valid(dog):
		if dog_caught:
			dog.position = game.player.position+Vector2(17,0)
			if game.player.position.distance_to(Vector2(320,272))<35:
				dog.free()
				game.message.text = "Sacaste al perro por la entrada y volviste a cerrarla." if closed else "Sacaste al perro a la calle."
			return
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
	if is_instance_valid(dog) and game.player.position.distance_to(dog.position)<38:
		if carrying: game.zone_stock[stolen_zone] += 1
		dog_caught = true
		dog_path.clear()
		carrying = false
		game.message.text = "Perro sujetado. Llévalo a la entrada para sacarlo."
		return true
	for pos in dirt:
		if game.player.position.distance_to(pos)<30:
			dirt.erase(pos)
			game.message.text = "Suelo limpio."
			return true
	return false
func _draw() -> void:
	if game==null: return
	if hide_amount>0.9:
		draw_string(ThemeDB.fallback_font,game.CASHIER+Vector2(-28,8),"OCULTO",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)
	if closed:
		draw_rect(Rect2(279,282,80,5),Color("977854"))
		draw_line(Vector2(310,281),Vector2(310,288),Color("eed49c"),2)
	for pos in dirt:
		draw_circle(pos,4,Color("63442c"))
		draw_circle(pos+Vector2(2,-3),3,Color("775136"))
	if patrol_time>0 and patrol_texture!=null:
		draw_texture_rect(patrol_texture,Rect2(patrol_x,308,88,38),false)
		for x in [patrol_x+17,patrol_x+69]:
			draw_arc(Vector2(x,338),5,0,TAU,12,Color("17202b"),2)
			for i in range(3):
				var angle := wheel_phase+i*TAU/3
				draw_line(Vector2(x,338),Vector2(x,338)+Vector2.from_angle(angle)*4,Color("aab9c2"),1)
	if is_instance_valid(dog) and carrying:
		draw_rect(Rect2(dog.position+Vector2(10,-7),Vector2(6,5)),Color("e7b85e"))

func police_route(target: Vector2) -> void:
	var start := Vector2i(((officer.position)/8).round())
	officer_path = game.crowd.nav.get_point_path(start,Vector2i((target/8).round()))
	if not officer_path.is_empty(): officer_path.remove_at(0)

func move_officer(delta: float) -> void:
	if officer_path.is_empty(): return
	var before: Vector2 = officer.position
	officer.position = officer.position.move_toward(officer_path[0],120*delta)
	game.Motion.animate(officer,officer.position-before,120)
	if officer.position.distance_to(officer_path[0])<0.5: officer_path.remove_at(0)

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
		wheel_phase += delta*18
		patrol_x = move_toward(patrol_x,350,110*delta)
		if patrol_x==350:
			police_state = "parked"
			repath = 0.8
	elif police_state=="parked":
		repath -= delta
		if repath<=0:
			officer = game.make_actor("police-officer")
			officer.position = Vector2(320,344)
			officer.offset.y = -20
			game.add_child(officer)
			begin_chase()
			var has_suspect := false
			for suspect in game.crowd.people:
				if suspect.thief and suspect.state!="arrested": has_suspect = true
			if has_suspect:
				game.message.text = "La patrulla estacionó. El agente entra a buscar al ladrón."
			else:
				game.message.text = "La patrulla llegó: ya no hay sospechosos en la tienda."
				police_state = "escorting"
				police_route(Vector2(320,344))
				for detainee in detainees: game.crowd.plan(detainee,Vector2(320,344))
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
			if target.is_empty() or (officer.position).distance_to(p.node.position)<(officer.position).distance_to(target.node.position): target = p
		if not target.is_empty():
			repath -= delta
			if repath<=0:
				police_route(target.node.position)
				repath = 0.35
			move_officer(delta)
			if not target.escape_allowed and (officer.position).distance_to(target.node.position)<15:
				target.state = "arrested"
				target.path.clear()
				target.evidence = false
				target.bubble.text = "Esposado"
				arrested_total += 1
				detainees.append(target)
		elif suspects==0:
			police_state = "escorting"
			escort_trail.clear()
			police_route(Vector2(320,344))
			for p in detainees: game.crowd.plan(p,Vector2(320,344))
	elif police_state=="escorting":
		# The first prisoner leads on a navigable path; the officer follows at cuff distance.
		if not detainees.is_empty():
			var leader: Dictionary = detainees[0]
			var before: Vector2 = leader.node.position
			if not leader.path.is_empty():
				leader.node.position = leader.node.position.move_toward(leader.path[0],75*delta)
				if leader.node.position.distance_to(leader.path[0])<0.5: leader.path.remove_at(0)
			game.Motion.animate(leader.sprite,leader.node.position-before,75)
			escort_trail.push_front(leader.node.position)
			if escort_trail.size()>16: escort_trail.pop_back()
			var previous: Vector2 = officer.position
			officer.position = escort_trail.back()
			game.Motion.animate(officer,officer.position-previous,75)
			for i in range(1,detainees.size()):
				detainees[i].node.position = officer.position+Vector2(i*8,20)
			if not leader.path.is_empty(): return
		else:
			move_officer(delta)
			if not officer_path.is_empty(): return
		var count := detainees.size()
		for p in detainees:
			game.crowd.people.erase(p)
			p.node.queue_free()
		detainees.clear()
		officer.queue_free()
		police_state = "departing"
		game.message.text = "La patrulla se lleva a %d detenido(s)." % count if count>0 else "La patrulla termina la revisión sin detenidos."
	elif police_state=="departing":
		wheel_phase += delta*18
		patrol_x = move_toward(patrol_x,740,110*delta)
		if patrol_x==740:
			police_state = "idle"
			patrol_time = 0
