extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.SaveStore.PATH = "user://test_commerce_ui.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start(false)
	game.crowd.rng.seed = 5721
	await process_frame
	for i in range(7200):
		game.crowd.tick(1.0/60)
		if not game.crowd.first().is_empty(): break
	var person: Dictionary = game.crowd.first()
	assert(not person.is_empty() and person.items.size()==person.basket)
	game.interact()
	await process_frame
	assert(game.panel.size.x<=608 and game.panel.size.y<=328)
	game.set_payment("cash")
	await process_frame
	assert(game.payment_method=="cash" and game.money==100)
	game.cancel_checkout()
	await process_frame
	assert(game.active and game.stock==12 and game.crowd.first()==person)
	game.interact()
	await process_frame
	game.set_payment("cash")
	await process_frame
	game.complete_sale()
	var expected: int = 100+person.basket*4
	assert(game.money==expected and game.sold==1)
	game.complete_sale()
	assert(game.money==expected)
	await process_frame
	game.enter_interior("cafe")
	game.player.position = Vector2(320,165)
	game.interact()
	await process_frame
	assert(game.cafe_menu_open and game.panel.size.y<=328)
	game.buy_cafe(1)
	assert(game.money==expected-5)
	game.buy_cafe(1)
	assert(game.money==expected-5)
	await process_frame
	game.close_city_panel()
	await process_frame
	game.enter_interior("hardware")
	game.show_upgrades()
	await process_frame
	game.commerce.select_upgrade("storage")
	await process_frame
	game.purchase_upgrade("storage")
	assert(game.money==expected-45 and game.progression.owned.has("storage"))
	await process_frame
	game.purchase_upgrade("storage")
	assert(game.money==expected-45)
	print("PASS: productos, pago efectivo, cancelación, cobro único, café, catálogo, tamaños de panel")
	quit()
