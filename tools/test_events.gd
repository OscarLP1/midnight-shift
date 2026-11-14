extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_events.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	await process_frame
	game.player.position = Vector2(200,100)
	game.interact()
	assert(game.events.door == 1)
	game.events.restock()
	assert(game.stock == 16 and game.money == 92)
	game.interact()
	assert(game.events.door == -1)
	game.events.restock()
	assert(game.money == 92)
	game.events.cycle_weather()
	assert(game.events.weather == 1)
	game.events.cycle_weather()
	assert(game.events.weather == 2)
	game.crowd.spawn()
	var person: Dictionary = game.crowd.people[0]
	person.thief = true
	person.evidence = true
	person.state = "concealing"
	person.path.clear()
	game.player.position = person.node.position
	assert(game.crowd.intervene())
	assert(not person.thief and person.state == "queue")
	person.thief = true
	person.evidence = true
	game.crowd.leave(person)
	person.path.clear()
	game.crowd.tick(0.1)
	assert(game.stock == 15 and game.events.losses == 4)
	game.crowd.tick(0.1)
	assert(game.stock == 15)
	game.night = 3
	game.elapsed = game.events.horror_start()
	game.events.tick(0.1)
	assert(game.events.apparition > 0)
	print("PASS: nevera, reposición, coste, clima, evidencia, devolución, pérdida única, aparición")
	quit()
