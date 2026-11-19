extends Node2D

var game: Node2D
var weather := 0
var rain_amount := 0.0
var snow_amount := 0.0
var door := -1
var open_doors := [false,false,false,false,false]
var customer_fridges: Dictionary = {}
var customer_opened := [false,false,false,false,false]
var open_time := [0.0,0.0,0.0,0.0,0.0]
var spoiled := [false,false,false,false,false]
var losses := 0
var damaged := [false,false,false,false,false,false,false,false]
var fallen: Array[Dictionary] = []
var disturbance_in := 0.0
var repairing := -1
var repair_progress := 0.0
var apparition := 0.0
var next_apparition := 0.0
var phase := 0.0
var haunt_door := -1
var event_count := 0
var monster_index := 0
var muted := false
var music_volume := 0.8
var effects_volume := 0.7
var voice: AudioStreamPlayer
var creatures: Array[AnimatedSprite2D] = []
var vocal_in := 0.0
var vocal_count := 0
var last_vocal := ""
var vocal_hold := 0.0
var music: Array[AudioStreamPlayer] = []
var monster_path := PackedVector2Array()
var monster_repath := 0.0
var apparition_age := 0.0
var monster_position := Vector2(272,224)
const APPEARANCE_SECONDS := 16.0

func setup(owner_game: Node2D) -> void:
	game = owner_game
	var settings := ConfigFile.new()
	if settings.load("user://audio.cfg")==OK:
		music_volume = clampf(float(settings.get_value("audio","music",0.8)),0,2)
		effects_volume = clampf(float(settings.get_value("audio","effects",0.7)),0,2)
		muted = bool(settings.get_value("audio","muted",false))
	z_index = 5
	for i in range(3):
		var creature: AnimatedSprite2D = game.make_actor("monster-walk-%d" % i,Vector2i(40,64))
		creature.offset.y = -28
		creature.position = Vector2.ZERO
		creature.visible = false
		creature.set_meta("max_cadence",1.25)
		game.add_child(creature)
		creatures.append(creature)
	voice = AudioStreamPlayer.new()
	voice.stream = load("res://assets/audio/threshold.wav")
	voice.volume_db = -13
	add_child(voice)
	for track in ["daylight","unease","presence"]:
		var layer := AudioStreamPlayer.new()
		var stream: AudioStreamWAV = load("res://assets/audio/"+track+".wav")
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()/4
		layer.stream = stream
		layer.volume_db = -60
		add_child(layer)
		music.append(layer)
		if DisplayServer.get_name()!="headless": layer.play()

func _process(delta: float) -> void:
	if game.active:
		phase += delta
		rain_amount = move_toward(rain_amount,1.0 if weather==1 else 0.0,delta*0.45)
		snow_amount = move_toward(snow_amount,1.0 if weather==2 else 0.0,delta*0.3)
	queue_redraw()
	if is_instance_valid(voice): voice.stream_paused = not game.active or muted or game.location!="store"
	for i in range(creatures.size()):
		creatures[i].visible = apparition>0 and monster_index==i and game.location=="store"
		if not game.active: creatures[i].pause()
	if not creatures.is_empty() and apparition>0:
		var creature: AnimatedSprite2D = creatures[monster_index]
		creature.position = monster_position
		creature.modulate = Color(0.90,0.93,1,minf(clampf(apparition_age/1.2,0,1),clampf(apparition/2,0,1)))
	voice.volume_db = -9.0+linear_to_db(maxf(effects_volume,0.0001))
	var danger: bool = apparition>0 or game.security.danger()
	var tension: float = 1.0 if danger else (0.35 if game.elapsed>=horror_start()-60 and game.location=="store" else 0.0)
	var levels := [-60.0 if danger else -7.0,lerpf(-60,-10,tension),-10.0 if apparition>0 else -60.0]
	for i in range(music.size()):
		music[i].stream_paused = not game.active or muted
		music[i].volume_db = move_toward(music[i].volume_db,levels[i]-(5.0 if voice.playing else 0.0)+linear_to_db(maxf(music_volume,0.0001)),delta*7.0)

func save_audio_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio","music",music_volume)
	settings.set_value("audio","effects",effects_volume)
	settings.set_value("audio","muted",muted)
	settings.save("user://audio.cfg")

func _exit_tree() -> void:
	if is_instance_valid(voice): voice.stop()
	for layer in music: layer.stop()

func horror_start() -> float:
	return game.seconds_per_game_hour() * 6.0

func reset_shift() -> void:
	weather = (game.night - 1) % 3
	door = -1
	open_doors.fill(false)
	for i in range(5):
		if damaged[i+3]: open_doors[i] = true
	repairing = -1
	customer_fridges.clear()
	customer_opened.fill(false)
	open_time.fill(0.0)
	spoiled.fill(false)
	losses = 0
	apparition = 0
	phase = 0
	next_apparition = horror_start()
	haunt_door = -1
	event_count = 0
	voice.stop()
	vocal_in = 0
	vocal_hold = 0
	vocal_count = 0
	for creature in creatures: creature.visible = false

func tick(delta: float) -> void:
	for item in fallen: item.age += delta
	if repairing>=0:
		if apparition>0 or game.location!="store" or nearby_damage()!=repairing or game.security.hiding:
			repairing = -1
			repair_progress = 0.0
		else:
			repair_progress += delta
			game.message.text = "Reparando… %d%% · Permanece cerca" % mini(100,int(repair_progress/3.0*100))
			if repair_progress>=3.0: finish_repair()
	for i in range(5):
		if open_doors[i]:
			open_time[i] += delta
			if open_time[i]>=game.seconds_per_game_hour()*3 and not spoiled[i]:
				var lost: int = game.zone_stock[i+3]
				game.zone_stock[i+3] = 0
				losses += lost*game.progression.sale_price()
				spoiled[i] = true
				game.message.text = "Nevera %d: mercancía dañada. Cierra y repón con R." % (i+1)
		else: open_time[i] = 0.0
	if game.elapsed>=next_apparition and game.elapsed<game.SHIFT_SECONDS :
		apparition = APPEARANCE_SECONDS
		apparition_age = 0
		monster_path.clear()
		monster_repath = 0
		monster_position = Vector2(580,326) if game.security.closed else [Vector2(272,224),Vector2(432,216),Vector2(320,268)][event_count%3]
		game.crowd.frighten()
		monster_index = (game.night-1+event_count)%3
		haunt_door = -1
		event_count += 1
		disturbance_in = 0.0
		next_apparition = game.elapsed+game.seconds_per_game_hour()*0.5
		game.message.text = "Hay alguien en el pasillo. No parece un cliente." if event_count%2==1 else "Las luces cambian… algo está aquí."
		vocal_count = 0
		vocal_in = 0
		vocal_hold = 0

	if apparition>0:
		disturbance_in -= delta
		if disturbance_in<=0:
			cause_disturbance()
			disturbance_in = 2.8
		apparition_age += delta
		var before: Vector2 = monster_position
		vocal_in -= delta
		vocal_hold = maxf(0,vocal_hold-delta)
		if vocal_in<=0:
			var cue: String = ["stalker-growl","antler-scream","drowned-sobs"][monster_index]
			if monster_index==0 and monster_position.distance_to(game.player.position)<80: cue = "stalker-scream"
			play_vocal(cue)
			vocal_in = [5.5,6.5,5.0][monster_index]
			vocal_hold = 0.7 if monster_index!=2 else 1.0
		monster_repath -= delta
		if monster_position.y<280:
			if monster_repath<=0:
				var target: Vector2 = game.player.position if monster_index==0 and not game.security.hiding else game.crowd.SPOTS[(event_count+int(apparition_age/3))%8]
				monster_path = game.crowd.nav.get_point_path(Vector2i((monster_position/8).round()),Vector2i((target/8).round()))
				if not monster_path.is_empty(): monster_path.remove_at(0)
				monster_repath = 0.7
			if not monster_path.is_empty() and vocal_hold<=0:
				monster_position = monster_position.move_toward(monster_path[0],(62 if monster_index==0 else 38)*delta)
				if monster_position.distance_to(monster_path[0])<0.5: monster_path.remove_at(0)
			if monster_index==0 and monster_position.distance_to(game.player.position)<19 and not game.security.hiding:
				game.message.text = "¡Está detrás de ti! Corre o escóndete."
		game.Motion.animate(creatures[monster_index],monster_position-before,62 if monster_index==0 else 38)
		creatures[monster_index].position = monster_position
	var was_present := apparition>0
	apparition = maxf(0,apparition-delta)
	if was_present and apparition<=0 and damaged.has(true):
		game.message.text = "Se ha ido. Hay daños en la tienda: acércate y pulsa E para reparar."
	if apparition<=0:
		haunt_door = -1
		voice.stop()
		for creature in creatures: creature.visible = false
	queue_redraw()

func interact() -> bool:
	var broken := nearby_damage()
	if broken>=0:
		if apparition>0:
			game.message.text = "Espera a que se vaya antes de reparar."
		else:
			repairing = broken
			repair_progress = 0.0
			game.message.text = "Reparando… permanece cerca durante 3 segundos."
		return true
	if game.player.position.y<116:
		var selected := clampi(int((game.player.position.x-40)/112),0,4)
		open_doors[selected] = not open_doors[selected]
		customer_opened[selected] = false
		if not open_doors[selected]: open_time[selected] = 0.0
		game.soundscape.play("door-soft")
		door = selected if open_doors[selected] else -1
		game.message.text = "V · Revisar productos · E · Cerrar · R · Reponer" if door>=0 else "Nevera cerrada."
		return true
	var shelf := shelf_near(game.player.position)
	if shelf>=0:
		game.exploration.shelf(shelf)
		return true
	return false

func sync_customer_fridges(users: Dictionary) -> void:
	for index in range(5):
		var occupied: bool = users.has(index)
		if occupied and not customer_fridges.has(index):
			customer_opened[index] = not open_doors[index]
			if not open_doors[index]:
				open_doors[index] = true
				game.soundscape.play("door-soft")
		elif not occupied and customer_fridges.has(index):
			if customer_opened[index] and not damaged[index+3]:
				open_doors[index] = false
				open_time[index] = 0.0
				game.soundscape.play("door-soft")
			customer_opened[index] = false
	customer_fridges = users.duplicate()

func inspect_fridge() -> void:
	if not game.active or game.location!="store" or game.player.position.y>=116: return
	var selected := clampi(int((game.player.position.x-40)/112),0,4)
	if not open_doors[selected]:
		game.message.text = "E · Abre la nevera antes de revisar sus productos."
		return
	game.exploration.fridge(selected)

func shelf_near(pos: Vector2) -> int:
	for i in range(3):
		var rect: Rect2 = game.obstacles[i]
		if rect.grow(29).has_point(pos): return i
	return -1

func restock() -> void:
	if not game.active or game.location!="store": return
	if nearby_damage()>=0:
		game.message.text = "E · Repara primero el mueble dañado."
		return
	var zone := shelf_near(game.player.position)
	if game.player.position.y<116: zone = clampi(int((game.player.position.x-40)/112),0,4)+3
	if zone<0: return
	if zone>=3 and open_doors[zone-3] and spoiled[zone-3]:
		game.message.text = "Cierra la nevera antes de reponer la mercancía dañada."
		return
	var amount: int = mini(4,game.progression.capacity()-game.stock)
	if amount<=0 or game.money<amount*2:
		game.message.text = "Sin espacio o fondos para reponer ($2/unidad)."
		return
	game.money -= amount*2
	game.expenses += amount*2
	game.zone_stock[zone] += amount
	if zone>=3: spoiled[zone-3] = false
	game.message.text = "Reposición en %s: +%d unidades." % [("nevera %d" % (zone-2)) if zone>=3 else game.exploration.ZONES[zone],amount]

func cycle_weather() -> void:
	if not game.active or game.location!="store": return
	weather = (weather+1)%3
	game.message.text = "Clima: " + ["despejado","lluvia","nieve"][weather]

func outside(p: Vector2) -> bool:
	return not Rect2(24,33,592,273).has_point(p)

func _draw() -> void:
	if not is_instance_valid(game): return
	draw_weather()
	if game.location!="store": return
	draw_fallen_products()
	if apparition>0:
		var opacity := minf(clampf((APPEARANCE_SECONDS-apparition)/1.2,0,1),clampf(apparition/2.0,0,1))
		draw_rect(Rect2(32,92,576,188),Color(0.025,0.04,0.09,(0.65 if sin(phase*19)>0.7 else 0.18)*opacity))
		draw_ellipse_shadow(monster_position,opacity)

		if haunt_door>=0:
			for i in range(4):
				var drop := fposmod(phase*14+i*13,18)
				draw_rect(Rect2(450+i*3,87+drop,1,2),Color(0.3,0.43,0.47,opacity))

func draw_ellipse_shadow(pos: Vector2, opacity: float) -> void:
	draw_set_transform(pos,0,Vector2(1,0.22))
	draw_circle(Vector2.ZERO,20,Color(0.015,0.02,0.035,0.45*opacity))
	draw_set_transform(Vector2.ZERO)

func play_vocal(cue: String) -> void:
	last_vocal = cue
	vocal_count += 1
	voice.stream = load("res://assets/audio/"+cue+".wav")
	if not muted and DisplayServer.get_name()!="headless": voice.play()

func weather_regions() -> Array[Rect2]:
	if game.location=="city": return [Rect2(0,0,640,360)]
	if game.location=="store": return [Rect2(0,309,640,51),Rect2(0,30,21,279),Rect2(619,30,21,279),Rect2(0,0,640,30)]
	return []

func draw_weather() -> void:
	var regions := weather_regions()
	for region in regions:
		# Surface response is independent of the dry background, with gradual transitions.
		if region.position.y>=309 or game.location=="city":
			var ground := Rect2(0,292,640,68) if game.location=="city" else region
			draw_rect(ground,Color(0.08,0.15,0.23,0.2*rain_amount))
			for i in range(22):
				var pos := Vector2(fposmod(i*97.7,632.0)+4,ground.position.y+fposmod(i*17.9,ground.size.y-4))
				var pulse := fposmod(phase*1.6+i*0.37,1.0)
				draw_set_transform(pos,0,Vector2(1,0.28))
				draw_arc(Vector2.ZERO,1+pulse*5,0,TAU,12,Color(0.57,0.72,0.79,(1-pulse)*0.42*rain_amount),1)
				draw_set_transform(Vector2.ZERO)
				# Small irregular snow deposits; leave the walking lane readable.
				draw_rect(Rect2(pos.x,ground.end.y-3-fposmod(i*7.0,9.0),8+i%7,2),Color(0.72,0.82,0.91,0.65*snow_amount))
		for layer in range(3):
			var count := int(region.get_area()/950.0)+8
			for i in range(count):
				var seed_value := float(i*83+layer*191)
				var speed := 85.0+layer*45.0
				var x := region.position.x+fposmod(seed_value-phase*(13+layer*7),region.size.x)
				var y := region.position.y+fposmod(i*37.3+layer*31+phase*speed,region.size.y)
				if rain_amount>0:
					var end := Vector2(maxf(region.position.x,x-1.5-layer),minf(region.end.y,y+3+layer*2))
					draw_line(Vector2(x,y),end,Color(0.59,0.74,0.87,(0.18+layer*0.12)*rain_amount),1)
				if snow_amount>0:
					var sway := sin(phase*(0.65+layer*0.13)+i)* (3+layer*2)
					x = region.position.x+fposmod(seed_value+phase*(3+layer)+sway,region.size.x-2)
					y = region.position.y+fposmod(i*37.3+phase*(9+layer*7),region.size.y-2)
					draw_rect(Rect2(x,y,1+int(layer==2),1+int(layer==2)),Color(0.85,0.92,1,(0.35+layer*0.23)*snow_amount))
	if game.location=="store" and snow_amount>0:
		for rect in [Rect2(24,306,250,2),Rect2(366,306,250,2),Rect2(20,35,2,271),Rect2(618,35,2,271)]:
			draw_rect(rect,Color(0.78,0.87,0.94,snow_amount*0.85))

func nearby_damage() -> int:
	if game.location!="store": return -1
	var zone := shelf_near(game.player.position)
	if game.player.position.y<116: zone = clampi(int((game.player.position.x-40)/112),0,4)+3
	return zone if zone>=0 and damaged[zone] else -1

func cause_disturbance() -> void:
	haunt_door = (event_count+int(apparition_age/2.8))%5
	open_doors[haunt_door] = true
	customer_opened[haunt_door] = false
	damaged[haunt_door+3] = true
	game.soundscape.play("door-soft")
	var zone := (event_count+int(apparition_age/2.8))%3
	if not damaged[zone]:
		damaged[zone] = true
		for item in range(3):
			fallen.append({"zone":zone,"item":item,"age":0.0})
	game.message.text = "¡Las neveras se abren y los productos caen!"

func finish_repair() -> void:
	var zone := repairing
	damaged[zone] = false
	if zone>=3:
		open_doors[zone-3] = false
		open_time[zone-3] = 0.0
	else:
		for item in fallen.duplicate():
			if item.zone==zone: fallen.erase(item)
	repairing = -1
	repair_progress = 0.0
	game.soundscape.play("door-soft")
	game.message.text = "Nevera reparada y cerrada." if zone>=3 else "Estante reparado y productos recogidos."

func draw_fallen_products() -> void:
	var catalog: Texture2D = preload("res://assets/product-catalog.png")
	for item in fallen:
		var origin: Vector2 = game.crowd.SPOTS[item.zone]+Vector2(-20+item.item*18,-44)
		var t: float = clampf(item.age/0.75,0.0,1.0)
		var pos := origin+Vector2((item.item-1)*9*t,45*t*t)
		draw_set_transform(pos,lerpf(0.0,(-0.7 if item.item%2==0 else 0.8),t))
		draw_texture_rect_region(catalog,Rect2(-6,-9,12,18),Rect2(item.item*catalog.get_width()/3.0,item.zone*catalog.get_height()/3.0,catalog.get_width()/3.0,catalog.get_height()/3.0))
		draw_set_transform(Vector2.ZERO)
	for zone in range(3):
		if damaged[zone]:
			var p: Vector2 = game.crowd.SPOTS[zone]
			draw_line(p+Vector2(-25,-16),p+Vector2(22,-10),Color("845333"),2)
