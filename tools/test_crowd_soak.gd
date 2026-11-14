extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	game.crowd.rng.seed = 91
	for i in range(6000):
		game.crowd.tick(0.1)
		assert(game.crowd.people.size()<=5)
		for p in game.crowd.people:
			for rect in game.obstacles: assert(not rect.has_point(p.node.position))
		if i%300==0: await process_frame
	assert(game.crowd.serial>15,"Los clientes deben abandonar y ser reemplazados")
	var spots := {}
	for v in game.crowd.visits_log: spots[v] = true
	assert(spots.size()==7,"Deben visitar tanto neveras como estantes")
	print("PASS: 10 minutos simulados, máximo 5 clientes, reposición de visitantes, 7 destinos, sin atravesar muebles")
	quit()
