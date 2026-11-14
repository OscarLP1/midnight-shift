extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_spatial_events.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	game.events.muted = true
	await process_frame
	for i in range(3):
		assert(game.obstacles[i].size.y==20)
		var behind := Vector2(game.obstacles[i].get_center().x,144)
		assert(not game.obstacles[i].grow(7).has_point(behind))
		assert(not game.crowd.nav.is_point_solid(Vector2i((behind/8).round())))
	game.crowd.rng.seed = 5721
	for i in range(7200):
		game.crowd.tick(1.0/60)
		if not game.crowd.first().is_empty(): break
	assert(game.crowd.first().node.position.distance_to(game.CUSTOMER_CHECKOUT)<1)
	assert(game.crowd.first().sprite.animation=="0")
	game.player.position = Vector2(192,192)
	game.interact()
	await process_frame
	assert(not game.active and game.panel.size.y<=328)
	game.close_city_panel()
	await process_frame
	assert(game.events.outside(Vector2(8,140)) and game.events.outside(Vector2(630,140)))
	assert(not game.events.outside(Vector2(300,200)))
	game.elapsed = 0
	assert(game.shift_hour()==22)
	game.elapsed = game.seconds_per_game_hour() - 0.01
	assert(game.shift_hour()==22)
	game.elapsed = game.seconds_per_game_hour()
	assert(game.shift_hour()==23)
	game.elapsed = game.SHIFT_SECONDS
	assert(game.shift_hour()==6)
	game.elapsed = game.events.horror_start() - 0.01
	game.events.tick(0.01)
	assert(game.events.apparition==0 and game.events.event_count==0)
	game.elapsed = game.events.horror_start()
	game.events.tick(0.01)
	assert(game.events.apparition>0 and game.events.event_count==1)
	game.elapsed = game.events.horror_start() + game.seconds_per_game_hour()
	game.events.tick(0.01)
	assert(game.events.haunt_door==3 and game.events.event_count==2)
	game.events.tick(17)
	assert(game.events.haunt_door==-1)
	game.enter_city()
	assert(game.map_button.visible)
	game.open_map()
	await process_frame
	assert(not game.active and game.panel.size.x<=608)
	game.close_city_panel()
	await process_frame
	game.open_styles()
	await process_frame
	assert(game.panel.size.y<=328)
	game.close_city_panel()
	print("PASS: cola frontal, paso tras estantes, inspección, exterior, horario 04:00, puerta, mapa, galería UI")
	quit()
