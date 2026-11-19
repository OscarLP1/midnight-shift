extends Node2D

var game: Node2D
var weather := 0
var rain_amount := 0.0
var snow_amount := 0.0
var door := -1
var open_doors := [false,false,false,false,false]
var open_time := [0.0,0.0,0.0,0.0,0.0]
var spoiled := [false,false,false,false,false]
var losses := 0
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
		next_apparition = game.elapsed+game.seconds_per_game_hour()*0.5
		game.message.text = "Hay alguien en el pasillo. No parece un cliente." if event_count%2==1 else "Las luces cambian… algo está aquí."
		vocal_count = 0
		vocal_in = 0
		vocal_hold = 0

	if apparition>0:
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
		if monster_index==1:
			haunt_door = int(apparition_age/3)%5
			open_doors[haunt_door] = true
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
	apparition = maxf(0,apparition-delta)
	if apparition<=0:
		haunt_door = -1
		voice.stop()
		for creature in creatures: creature.visible = false
	queue_redraw()

func interact() -> bool:
	if game.player.position.y<116:
		var selected := clampi(int((game.player.position.x-40)/112),0,4)
		open_doors[selected] = not open_doors[selected]
		if not open_doors[selected]: open_time[selected] = 0.0
		game.soundscape.play("door-soft")
		door = selected if open_doors[selected] else -1
		game.message.text = "Nevera abierta · R para reponer" if door>=0 else "Nevera cerrada."
		return true
	var shelf := shelf_near(game.player.position)
	if shelf>=0:
		game.exploration.shelf(shelf)
		return true
	return false

func shelf_near(pos: Vector2) -> int:
	for i in range(3):
		var rect: Rect2 = game.obstacles[i]
		if rect.grow(29).has_point(pos): return i
	return -1

func restock() -> void:
	if not game.active or game.location!="store": return
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
