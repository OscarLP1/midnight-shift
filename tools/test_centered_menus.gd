extends SceneTree
func _initialize() -> void: call_deferred("run")
func check_panel(game, menu: Control, title: String) -> void:
	await process_frame
	await process_frame
	var viewport_size: Vector2 = game.get_viewport_rect().size
	assert((menu.position+menu.size*0.5-viewport_size*0.5).length()<1.0,title)
	assert(menu.position.x>=0 and menu.position.y>=0,title+" fits")
	assert(menu.position.x+menu.size.x<=viewport_size.x and menu.position.y+menu.size.y<=viewport_size.y,title+" fits")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/centered-"+title+".png")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await check_panel(game,game.panel,"main")
	game.menus.commands()
	await check_panel(game,game.panel,"commands")
	game.start(false)
	game.events.muted = true
	game.pause_shift()
	await check_panel(game,game.panel,"pause")
	game.resume_shift()
	game.open_security_menu()
	await check_panel(game,game.security_panel,"security")
	assert(game.active)
	game.close_security_menu()
	game.enter_city()
	game.open_map()
	await check_panel(game,game.panel,"map")
	game.close_city_panel()
	game.enter_interior("cafe")
	game.commerce.cafe()
	await check_panel(game,game.panel,"cafe")
	game.close_city_panel()
	game.enter_interior("hardware")
	game.show_upgrades()
	await check_panel(game,game.panel,"upgrades")
	game.close_city_panel()
	game.enter_interior("atelier")
	game.wardrobe.open()
	await check_panel(game,game.panel,"wardrobe")
	print("PASS: 8 menus centered and contained; security remains live")
	game.queue_free()
	await process_frame
	quit()
