extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, text: String) -> void:
	if not condition:
		push_error(text)
		quit(1)
		assert(condition, text)
	print("PASS: " + text)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_flow.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	await process_frame
	game.crowd.rng.seed = 5721
	for i in range(7200):
		game.crowd.tick(1.0/60)
		if not game.crowd.first().is_empty(): break
	check(not game.crowd.first().is_empty(), "Cliente llega a caja")
	game.interact()
	check(game.transaction_open, "Interacción abre caja")
	var count: int = game.checkout_person.basket
	game.complete_sale()
	check(game.money == 100+count*4 and game.stock == 12-count and game.sold == 1, "Venta actualiza dinero y stock")
	game.complete_sale()
	check(game.money == 100+count*4, "No se duplica el cobro")
	await process_frame
	game.pause_shift()
	check(not game.active, "Pausa detiene simulación")
	game.resume_shift()
	await process_frame
	game.finish()
	check(game.night == 2 and not game.active, "Cierre avanza noche")
	var saved = game.SaveStore.load_game()
	check(saved.get("money") == game.money and saved.get("night") == 2, "Guardado recuperable")
	print("FLOW COMPLETED")
	quit(0)
