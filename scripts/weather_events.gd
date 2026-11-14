extends Node2D

var game: Node2D
var weather := 0
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
var monsters: Array[Texture2D] = []
var music: Array[AudioStreamPlayer] = []
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
	for i in range(3): monsters.append(load("res://assets/monster-%d.png" % i))
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
	if is_instance_valid(voice): voice.stream_paused = not game.active or muted
	voice.volume_db = -13.0+linear_to_db(maxf(effects_volume,0.0001))
	var danger: bool = apparition>0 or game.security.danger()
	var tension: float = 1.0 if danger else (0.35 if game.elapsed>=horror_start()-60 and game.location=="store" else 0.0)
	var levels := [-60.0 if danger else -7.0,lerpf(-60,-10,tension),-10.0 if apparition>0 else -60.0]
	for i in range(music.size()):
		music[i].stream_paused = not game.active or muted
		music[i].volume_db = move_toward(music[i].volume_db,levels[i]+linear_to_db(maxf(music_volume,0.0001)),delta*7.0)

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

func tick(delta: float) -> void:
	phase += delta
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
		monster_position = Vector2(580,326) if game.security.closed else [Vector2(272,224),Vector2(432,216),Vector2(320,268)][event_count%3]
		game.crowd.frighten()
		monster_index = (game.night-1+event_count)%3
		haunt_door = -1
		event_count += 1
		next_apparition = game.elapsed+game.seconds_per_game_hour()*0.5
		game.message.text = "Hay alguien en el pasillo. No parece un cliente." if event_count%2==1 else "Las luces cambian… algo está aquí."
		if not muted and DisplayServer.get_name()!="headless": voice.play()
	apparition = maxf(0,apparition-delta)
	if apparition<=0: haunt_door = -1
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
	var regions: Array[Rect2] = [Rect2(0,309,640,51),Rect2(0,30,22,279),Rect2(618,30,22,279),Rect2(0,0,640,30)]
	for region in regions:
		var count := 70 if region.size.x>50 else 32
		for i in range(count):
			var x := region.position.x+fposmod(i*83.7+phase*(6 if weather==2 else -14),maxf(1,region.size.x-5))
			var y := region.position.y+fposmod(i*19.3+phase*(18 if weather==2 else 130),maxf(1,region.size.y-8))
			if weather==1: draw_line(Vector2(x+3,y),Vector2(x,y+7),Color(0.53,0.72,0.89,0.65))
			elif weather==2: draw_rect(Rect2(x,y,2,2),Color("e1edf0"))
	if weather==2:
		draw_line(Vector2(21,35),Vector2(21,306),Color("becfd9"),2)
		draw_line(Vector2(617,35),Vector2(617,306),Color("becfd9"),2)
		draw_line(Vector2(25,306),Vector2(273,306),Color("d8e5ed"),2)
		draw_line(Vector2(366,306),Vector2(616,306),Color("d8e5ed"),2)
	if apparition>0:
		var opacity := minf(clampf((APPEARANCE_SECONDS-apparition)/1.2,0,1),clampf(apparition/2.0,0,1))
		draw_rect(Rect2(32,92,576,188),Color(0.025,0.04,0.09,0.18*opacity))
		var drift := Vector2(sin(phase*0.7)*2,sin(phase*1.1))
		draw_ellipse_shadow(monster_position,opacity)
		draw_texture_rect(monsters[monster_index],Rect2(monster_position+drift-Vector2(20,56),Vector2(40,64)),false,Color(0.90,0.93,1.0,opacity))
		if haunt_door>=0:
			for i in range(4):
				var drop := fposmod(phase*14+i*13,18)
				draw_rect(Rect2(450+i*3,87+drop,1,2),Color(0.3,0.43,0.47,opacity))

func draw_ellipse_shadow(pos: Vector2, opacity: float) -> void:
	draw_set_transform(pos,0,Vector2(1,0.22))
	draw_circle(Vector2.ZERO,20,Color(0.015,0.02,0.035,0.45*opacity))
	draw_set_transform(Vector2.ZERO)
