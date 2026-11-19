extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_city.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	await process_frame
	game.finish()
	assert(game.night == 2 and not game.active)
	await process_frame
	game.enter_city()
	await process_frame
	assert(game.location == "city" and game.active and not game.customer.visible)
	assert(game.store_bodies[0].collision_layer == 0 and game.city_bodies[0].collision_layer == 1)
	game.player.position = Vector2(game.District.DOORS.hardware,258)
	game.interact()
	assert(game.location == "hardware")
	game.player.position = game.District.room_point(game.location,Vector2(320,170))
	game.interact()
	await process_frame
	game.purchase_upgrade("storage")
	assert(game.money == 60 and game.progression.capacity() == 40)
	await process_frame
	game.purchase_upgrade("storage")
	assert(game.money == 60)
	await process_frame
	game.purchase_upgrade("security")
	assert(game.money == 60 and not game.progression.owned.has("security"))
	await process_frame
	game.purchase_upgrade("register")
	assert(game.money == 0 and game.progression.sale_price() == 5)
	var saved = game.SaveStore.load_game()
	assert(saved.location == "city" and saved.upgrades.size() == 2)
	await process_frame
	game.start(true)
	assert(game.location == "city" and game.progression.owned.size() == 2)
	await process_frame
	game.begin_shift()
	assert(game.location == "store")
	assert(game.stock == 12 and game.night == 2)
	assert(game.store_bodies[0].collision_layer == 1 and game.city_bodies[0].collision_layer == 0)
	game.finish()
	assert(game.night == 3)
	game.finish()
	assert(game.night == 3)
	print("PASS: cierre, ciudad, colisiones, compra, duplicados, fondos, efectos, persistencia, regreso")
	quit()
