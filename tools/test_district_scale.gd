extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(game, title: String) -> void:
	game.update_world_camera()
	game.update_hint()
	game.hud.text = "BARRIO DEL FARO · $100"
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/district-"+title+".png")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_district_scale.json"
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_physics_process(false)
	game.events.muted = true
	game.enter_city()
	assert(game.player.position.x==game.District.DOORS.store)
	assert((game.background.scale*game.background.texture.get_size()).is_equal_approx(game.District.STREET_SIZE))
	await capture(game,"supermarket")
	for place in ["hardware","cafe","atelier"]:
		game.street = 1 if place=="atelier" else 0
		game.enter_city()
		game.player.position = Vector2(game.District.DOORS[place],258)
		assert(game.nearby_shop()==place)
		await capture(game,place+"-exterior")
		game.city_interact()
		assert(game.location==place and game.actor.scale==Vector2(1.6,1.6))
		assert(is_equal_approx(game.background.scale.x,game.District.scale_for(place)))
		assert(game.world_camera.position==Vector2(320,204))
		await capture(game,place+"-interior")
		game.player.position = game.District.room_point(place,Vector2(320,170))
		game.interior_interact()
		assert(not game.active)
		game.close_city_panel()
		await process_frame
		game.player.position = game.District.room_point(place,Vector2(320,305))
		game.interior_interact()
		assert(game.location=="city" and game.player.position.x==game.District.DOORS[place])
	game.street = 0
	game.enter_city()
	game.player.position = Vector2(40,258)
	game.city_interact()
	assert(game.street==1 and game.player.position.x==564)
	game.player.position.x=600
	game.city_interact()
	assert(game.street==0 and game.player.position.x==76)
	game.player.position.x = 600
	game.update_world_camera()
	assert(game.world_camera.position==Vector2(320,204))
	game.open_map()
	await capture(game,"map")
	assert(game.panel.size.x<=608 and game.panel.size.y<=328)
	game.close_city_panel()
	game.begin_shift()
	assert(game.background.scale==Vector2.ONE and game.background.position==Vector2.ZERO)
	assert(game.world_camera.position==Vector2(320,204))
	print("PASS: all four storefronts, three interiors, restored interior scale, doors, services, street connections, district map, return to store")
	game.queue_free()
	await process_frame
	quit()
