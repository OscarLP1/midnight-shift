extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_night_atelier.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	game.events.muted = true
	game.wardrobe.config_path = "user://test_appearance.cfg"
	game.wardrobe.saved = [0,0,0,0]
	await process_frame
	assert(game.player.position==game.CASHIER)
	for point in [Vector2(32,150),Vector2(608,150),Vector2(100,288),Vector2(500,288),Vector2(280,88)]:
		assert(not game.walkable_store(point,true))
		assert(game.crowd.nav.is_point_solid(Vector2i((point/8).round())))
	for trial in [[Vector2(48,200),Vector2(-300,0)],[Vector2(592,200),Vector2(300,0)],[Vector2(272,105),Vector2(0,-300)],[Vector2(400,270),Vector2(0,300)]]:
		game.player.position = trial[0]
		for i in range(15):
			await physics_frame
			game.player.velocity = trial[1]
			game.player.move_and_slide()
		assert(game.player.position.x>=46 and game.player.position.x<=594)
		assert(game.player.position.y>=103 and game.player.position.y<=273.1)
	game.player.position = game.CASHIER
	game.crowd.rng.seed = 5721
	for i in range(3600):
		game.crowd.tick(1.0/60)
		for p in game.crowd.people: assert(game.walkable_store(p.node.position,true))
		if not game.crowd.first().is_empty(): break
	assert(not game.crowd.first().is_empty())
	assert(game.crowd.first().node.position==game.CUSTOMER_CHECKOUT)
	assert(game.crowd.first().sprite.animation=="0")
	game.crowd.reset()
	for i in range(5):
		game.crowd.spawn()
		game.crowd.people[i].node.position = Vector2(272+i*32,104)
		game.crowd.plan(game.crowd.people[i],game.crowd.people[i].targets[0])
	game.elapsed = 480
	game.crowd.tick(0.1)
	var departing := 0
	for p in game.crowd.people:
		if p.state=="leaving": departing += 1
	assert(departing==1)
	game.elapsed = 539.9
	game.events.tick(0.1)
	assert(game.events.event_count==0)
	game.elapsed = 540
	game.events.tick(0.1)
	assert(game.events.apparition>15 and game.events.event_count==1)
	for p in game.crowd.people: assert(p.state=="leaving" and p.speed>=100)
	for i in range(900): game.crowd.tick(1.0/60)
	assert(game.crowd.people.is_empty())
	game.events.tick(2.0)
	assert(game.events.apparition>12)
	for time in [585,630,675]:
		game.elapsed = time
		game.events.tick(0.1)
	assert(game.events.event_count==4)
	game.events.tick(17)
	game.elapsed = 720
	game.events.tick(0.1)
	assert(game.events.apparition==0 and game.events.event_count==4)
	game.events.music_volume = 1.0
	game.events.muted = false
	game.active = true
	game.elapsed = 540
	game.events._process(8)
	assert(game.events.music.size()==3 and game.events.music[1].volume_db>-25)
	game.events.muted = true
	game.events._process(0.1)
	if game.events.music[0].playing: assert(game.events.music[0].stream_paused)
	game.enter_city()
	game.player.position = Vector2(40,258)
	game.interact()
	assert(game.street==1 and game.location=="city")
	game.player.position = Vector2(game.District.DOORS.atelier,258)
	game.interact()
	assert(game.location=="atelier")
	game.player.position = game.District.room_point(game.location,Vector2(320,170))
	game.interact()
	await process_frame
	assert(not game.active and game.panel.size.x<=608 and game.panel.size.y<=328)
	game.wardrobe.cycle(0,1)
	game.wardrobe.cycle(1,2)
	game.wardrobe.cycle(2,1)
	game.wardrobe.cycle(3,3)
	game.wardrobe.rotate_preview()
	await process_frame
	game.wardrobe.confirm()
	assert(game.active and game.wardrobe.saved==[1,2,1,3])
	var cfg := ConfigFile.new()
	assert(cfg.load(game.wardrobe.config_path)==OK and cfg.get_value("look","0")==1)
	game.wardrobe.saved = [0,0,0,0]
	game.wardrobe.setup(game)
	assert(game.wardrobe.saved==[1,2,1,3])
	game.player.position = game.District.room_point(game.location,Vector2(320,305))
	game.interact()
	assert(game.location=="city" and game.player.position.x==game.District.DOORS.atelier)
	game.open_map()
	await process_frame
	assert(game.panel.size.y<=328)
	game.close_city_panel()
	await process_frame
	game.pause_shift()
	await process_frame
	assert(game.panel.position.y+game.panel.size.y<=360)
	print("PASS: walls, checkout side, gradual departure, fleeing, 4 visible events, adaptive music/mute, atelier entry, preview, persistence and exit")
	game.free()
	await process_frame
	quit()

