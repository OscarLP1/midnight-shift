extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_crowd_interiors.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	game.crowd.rng.seed = 5721
	await process_frame
	var looks := {}
	var max_count := 0
	for i in range(120*30):
		game.crowd.tick(1.0/30)
		max_count = maxi(max_count,game.crowd.people.size())
		for p in game.crowd.people:
			looks[p.look] = true
			for obstacle in game.obstacles:
				assert(not obstacle.has_point(p.node.position),"NPC intersecta mueble")
		if not game.crowd.first().is_empty(): break
	assert(max_count>=2 and looks.size()>=2,"Clientes simultáneos y distintos")
	assert(game.crowd.visits_log.size()>0)
	game.player.position = game.CASHIER
	game.interact()
	assert(game.transaction_open)
	var count: int = game.checkout_person.basket
	game.complete_sale()
	assert(game.money==100+count*4 and game.stock==12-count)
	game.complete_sale()
	assert(game.sold==1)
	await process_frame
	game.finish()
	await process_frame
	game.enter_city()
	game.player.position = Vector2(game.District.DOORS.hardware,258)
	game.interact()
	assert(game.location=="hardware" and game.active)
	assert(game.interior_bodies[0].collision_layer==1)
	game.player.position = game.District.room_point(game.location,Vector2(320,170))
	game.interact()
	await process_frame
	game.purchase_upgrade("storage")
	assert(game.progression.capacity()==40)
	await process_frame
	game.close_city_panel()
	game.player.position = game.District.room_point(game.location,Vector2(320,305))
	game.interact()
	assert(game.location=="city" and game.player.position.x==game.District.DOORS.hardware)
	game.player.position = Vector2(game.District.DOORS.cafe,258)
	game.interact()
	assert(game.location=="cafe")
	game.player.position = game.District.room_point(game.location,Vector2(320,170))
	game.interact()
	await process_frame
	game.rest_at_cafe()
	assert(game.location=="cafe" and game.active and game.cafe_used)
	game.player.position = game.District.room_point(game.location,Vector2(320,305))
	game.interact()
	assert(game.location=="city" and game.player.position.x==game.District.DOORS.cafe)
	print("PASS: clientes distintos simultáneos, navegación, fila, compra múltiple, cobro único, interiores, mejoras y salidas")
	quit()
