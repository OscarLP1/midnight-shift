extends Node2D
var game
var hide_amount := 0.0
var hiding_actor: AnimatedSprite2D
var hide_direction := 1
var entrance_view: Node2D
var dropping: Texture2D
var hide_material: ShaderMaterial
var wheel_phase := 0.0
var arrested_total := 0
var dog_caught := false
var escort_trail: Array[Vector2] = []
var closed := false
var police_access := false
var passage_exiting := false
var gate_wait := 0.0
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
const DOG_TROT_SPEED := 64.0
const DOG_ESCAPE_SPEED := 74.0
const PATROL_WHEEL_CENTERS = [Vector2(20,30),Vector2(69,30)]
func _process(delta: float) -> void:
	if game==null: return
	visible = game.location=="store"
	if game.active:
		hide_amount = move_toward(hide_amount,1.0 if hiding else 0.0,delta*3)
	if not is_instance_valid(entrance_view):
		entrance_view = preload("res://scripts/entrance_view.gd").new()
		entrance_view.game = game
		entrance_view.z_index = 2
		add_child(entrance_view)
	if not is_instance_valid(hiding_actor):
		hiding_actor = game.make_actor("employee-hide")
		hiding_actor.z_index = 3
		hide_material = ShaderMaterial.new()
		hide_material.shader = preload("res://scripts/hide_palette.gdshader")
		var image: Image = load("res://assets/employee-hide.png").get_image()
		var tops := PackedFloat32Array()
		for row in range(4):
			for col in range(4): tops.append(image.get_region(Rect2i(col*32,row*48,32,48)).get_used_rect().position.y)
		hide_material.set_shader_parameter("head_top",tops)
		hiding_actor.material = hide_material
		hiding_actor.pause()
		game.player.add_child(hiding_actor)
	game.actor.visible = hide_amount<=0.001
	game.actor.modulate.a = 1
	if hide_amount>0:
		hide_material.set_shader_parameter("jacket",game.wardrobe.COLORS[game.wardrobe.saved[2]])
		hide_material.set_shader_parameter("hair",game.wardrobe.HAIR_COLORS[game.wardrobe.saved[3]])
		hiding_actor.animation = str(hide_direction)
		hiding_actor.pause()
		hiding_actor.frame = mini(3,int(hide_amount*4))
		hiding_actor.position = Vector2(0,lerpf(-20,-37,hide_amount))
		hiding_actor.visible = game.location=="store"
	else: hiding_actor.visible = false
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
	police_access = false
	gate_wait = 0
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
	if hiding:
		game.player.position = game.CASHIER
		hide_direction = 1
		game.player.velocity = Vector2.ZERO
	game.actor.z_index = 0
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
			var previous: Vector2 = dog.position
			dog.position = game.player.position+Vector2(17,0)
			game.Motion.animate(dog_sprite,dog.position-previous,game.player.velocity.length())
			if game.player.position.distance_to(Vector2(320,272))<35:
				dog.free()
				game.message.text = "Sacaste al perro por la entrada y volviste a cerrarla." if closed else "Sacaste al perro a la calle."
			return
		if not dog_path.is_empty():
			if closed and ((dog.position.y<=280 and dog_path[0].y>280) or (dog.position.y>280 and dog_path[0].y<=280)):
				queue_redraw()
				return
			var before: Vector2 = dog.position
			var speed := DOG_ESCAPE_SPEED if carrying else DOG_TROT_SPEED
			dog.position = dog.position.move_toward(dog_path[0],speed*delta)
			game.Motion.animate(dog_sprite,dog.position-before,speed)
			if dog.position.distance_to(dog_path[0])<0.5: dog_path.remove_at(0)
		elif dog_state=="roaming":
			game.Motion.animate(dog_sprite,Vector2.ZERO)
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

	if dropping==null: dropping = load("res://assets/dog-dropping.png")
	for pos in dirt:
		draw_texture_rect(dropping,Rect2(pos-Vector2(7,7),Vector2(14,9)),false)
	if patrol_time>0 and patrol_texture!=null:
		draw_texture_rect(patrol_texture,Rect2(patrol_x,308,88,38),false)
		for offset in PATROL_WHEEL_CENTERS:
			var center: Vector2 = Vector2(patrol_x,308)+offset
			draw_circle(center,4.5,Color("26303b"))
			draw_arc(center,4.5,0,TAU,16,Color("aab9c2"),1)
			for i in range(3):
				var angle := wheel_phase+i*TAU/3
				draw_line(center,center+Vector2.from_angle(angle)*3.5,Color("aab9c2"),1)
	if is_instance_valid(dog) and carrying:
		draw_rect(Rect2(dog.position+Vector2(10,-7),Vector2(6,5)),Color("e7b85e"))

func police_route(target: Vector2) -> void:
	var start := Vector2i(((officer.position)/8).round())
	officer_path = game.crowd.nav.get_point_path(start,Vector2i((target/8).round()))
	if not officer_path.is_empty(): officer_path.remove_at(0)

func move_officer(delta: float) -> void:
	if officer_path.is_empty():
		game.Motion.animate(officer,Vector2.ZERO)
		return
	if not police_passage_ready(officer.position,officer_path[0]):
		game.Motion.animate(officer,Vector2.ZERO)
		return
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
	gate_wait = maxf(0,gate_wait-delta)
	if police_access and police_state=="chasing" and is_instance_valid(officer) and ((not passage_exiting and officer.position.y<=264) or (passage_exiting and officer.position.y>=312)):
		police_access = false
		game.soundscape.play("door-soft")
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
		var previous_x := patrol_x
		patrol_x = move_toward(patrol_x,350,110*delta)
		wheel_phase += (patrol_x-previous_x)/5.0
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
				if not police_passage_ready(leader.node.position,leader.path[0]):
					game.Motion.animate(leader.sprite,Vector2.ZERO)
					game.Motion.animate(officer,Vector2.ZERO)
					return
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
		closed = true
		police_access = false
		gate_wait = 0.7
		game.soundscape.play("door-soft")
		police_state = "securing_exit"
		game.message.text = "La patrulla se lleva a %d detenido(s)." % count if count>0 else "La patrulla termina la revisión sin detenidos."
	elif police_state=="securing_exit":
		if gate_wait<=0: police_state = "departing"
	elif police_state=="departing":
		var previous_x := patrol_x
		patrol_x = move_toward(patrol_x,740,110*delta)
		wheel_phase += (patrol_x-previous_x)/5.0
		if patrol_x==740:
			police_state = "idle"
			patrol_time = 0

func police_passage_ready(from: Vector2, target: Vector2) -> bool:
	if police_access: return gate_wait<=0
	if not closed: return true
	if absf(target.y-from.y)>0.1 and minf(from.y,target.y)<=310 and maxf(from.y,target.y)>=268:
		police_access = true
		passage_exiting = target.y>from.y
		gate_wait = 0.7
		game.soundscape.play("door-soft")
		return false
	return true
