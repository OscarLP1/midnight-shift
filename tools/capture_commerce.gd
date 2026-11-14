extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_physics_process(false)
	game.crowd.spawn()
	game.checkout_person = game.crowd.people[0]
	game.checkout_person.basket = 3
	game.checkout_person.items = ["Agua Bruma","Papas Crujín","Leche Alba"]
	game.transaction_open = true
	game.set_payment("cash")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/checkout-ui.png")
	game.transaction_open = false
	game.enter_interior("hardware")
	game.show_upgrades()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/upgrades-ui.png")
	game.enter_interior("cafe")
	game.commerce.cafe()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/cafe-ui.png")
	quit()
