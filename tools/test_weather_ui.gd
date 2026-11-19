extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_physics_process(false)
	game.events.muted = true
	game.events.weather = 0
	game.events.rain_amount = 0
	game.events.snow_amount = 0
	assert(game.background.material == game.dry_night_material)
	assert(game.foreground_props[3].material is ShaderMaterial)
	assert(game.UIStyles.selected == 0)
	assert(game.events.weather_regions().size()==4)
	game.events.weather = 1
	game.events._process(1.0)
	assert(game.events.rain_amount>0 and game.events.snow_amount==0)
	game.events.weather = 2
	game.events._process(4.0)
	assert(game.events.rain_amount==0 and game.events.snow_amount==1)
	game.set_location("city")
	assert(game.events.visible and game.events.weather_regions().size()==1)
	assert(game.background.material==null)
	game.set_location("cafe")
	assert(game.events.weather_regions().is_empty())
	game.set_location("store")
	game.player.position = Vector2(112,219)
	game.Motion.face(game.actor,0)
	game.active = false
	game.hud.text = "N1  ·  22:00    $100    Neveras 5 / Estantes 6"
	game.message.text = "Mostrador con recorte · Una sola interfaz · Clima independiente"
	game.hint.text = "E · Interactuar    Shift · Correr    Esc · Pausa"
	if DisplayServer.get_name()!="headless":
		for climate in range(3):
			game.events.weather = climate
			game.events.rain_amount = 1 if climate==1 else 0
			game.events.snow_amount = 1 if climate==2 else 0
			game.events.phase = 3.6
			game.events.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/weather-ui-%d.png" % climate)
	print("PASS: dry baseline, counter cutout, unified UI, weather transitions and location masks")
	game.free()
	await process_frame
	quit()
