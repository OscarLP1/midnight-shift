extends Node2D

var game: Node2D
var weather := 0
var door := -1
var open_amount := 0.0
var reputation := 100
var losses := 0
var evidence := false
var thief := false
var visitor := 0
var visits := 0
var wait_time := 0.0
var apparition := 0.0
var next_apparition := 100.0
var phase := 0.0
var names := ["Elena · habitual", "Leo · repartidor", "Iván · oficinista", "Vera · exploradora", "Tomás · tranquilo", "Noa · impaciente"]

func setup(owner_game: Node2D) -> void:
	game = owner_game
	z_index = 5

func reset_shift() -> void:
	weather = (game.night - 1) % 3
	door = -1
	open_amount = 0
	losses = 0
	visits = 0
	evidence = false
	thief = false
	wait_time = 0
	apparition = 0
	next_apparition = 100

func new_visitor() -> void:
	visitor = visits % names.size()
	visits += 1
	thief = game.night >= 2 and randf() < game.progression.theft_chance()
	evidence = false
	wait_time = 0
	var colors := [Color("c4b1d9"),Color("e8c175"),Color("98bada"),Color("e49a9a"),Color("a4c1a2"),Color("e1d4af")]
	game.customer.modulate = colors[visitor]

func tick(delta: float) -> void:
	phase += delta
	open_amount = move_toward(open_amount,1.0 if door>=0 else 0.0,delta*4)
	if game.elapsed > next_apparition and game.night>=3:
		apparition = 6
		next_apparition += 180
		game.message.text = ["Alguien observa desde la calle.","Una sombra se mueve contra el viento.","El cristal refleja una figura pálida."][(game.night-3)%3]
	apparition = maxf(0,apparition-delta)
	queue_redraw()

func interact() -> bool:
	if game.player.position.y < 116:
		var selected := clampi(int((game.player.position.x-40)/112),0,4)
		door = -1 if door == selected else selected
		game.message.text = "Nevera abierta · R: reponer 4 unidades por $8" if door>=0 else "Nevera cerrada."
		return true
	if game.player.position.distance_to(Vector2(270,188))<40:
		game.message.text = "Estantería · %d unidades · Reposición en neveras (R)." % game.stock
		return true
	return false

func restock() -> void:
	if not game.active or game.location != "store": return
	if door<0 or game.player.position.y>116:
		game.message.text = "Abre una nevera antes de reponer."
	elif game.money<8:
		game.message.text = "Necesitas $8 para reponer."
	elif game.stock>game.progression.capacity()-4:
		game.message.text = "No hay espacio para otras 4 unidades."
	else:
		game.money -= 8
		game.expenses += 8
		game.stock += 4
		game.message.text = "Reposición: +4 unidades · gasto $8."

func cycle_weather() -> void:
	if not game.active or game.location != "store": return
	weather = (weather+1)%3
	game.message.text = "Clima: " + ["despejado", "lluvia", "nieve"][weather]

func _draw() -> void:
	if not is_instance_valid(game): return
	if weather == 2:
		draw_rect(Rect2(24,305,250,5),Color("d8e5ed"))
		draw_rect(Rect2(366,305,250,5),Color("d8e5ed"))
	for i in range(75):
		var x := fmod(i*83.7+phase*(12 if weather==2 else -25),640.0)
		var y := 311+fmod(i*13.3+phase*(18 if weather==2 else 140),49.0)
		if weather==1: draw_line(Vector2(x,y),Vector2(x-3,y+7),Color(0.5,0.7,0.9,0.65))
		if weather==2: draw_rect(Rect2(x,y,2,2),Color("e0eff7"))
	if evidence:
		draw_circle(game.customer.position+Vector2(0,-47),3,Color("efac75"))
	if apparition>0:
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/art_direction/visitors-source.png")
		var tex: Texture2D = atlas.atlas
		atlas.region = Rect2(((game.night-3)%3)*tex.get_width()/3.0,tex.get_height()*2.0/3.0,tex.get_width()/3.0,tex.get_height()/3.0)
		draw_texture_rect(atlas,Rect2(555,295,28,60),false,Color(0.65,0.8,1,minf(apparition,1)))

func _door_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12,0.32,0.4,0.6)
	style.border_color = Color("90dce8")
	style.set_border_width_all(1)
	return style
