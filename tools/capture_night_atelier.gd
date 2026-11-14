extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+name+".png")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_physics_process(false)
	game.events.muted = true
	game.crowd.rng.seed = 5721
	for i in range(7200):
		game.crowd.tick(1.0/60)
		if not game.crowd.first().is_empty(): break
	game._physics_process(0)
	await snap("new-checkout-side")
	game.elapsed = 540
	game.events.tick(2)
	game._physics_process(0)
	await snap("new-apparition")
	game.enter_city()
	game.open_map()
	await snap("new-map")
	game.close_city_panel()
	game.enter_interior("atelier")
	game._physics_process(0)
	await snap("new-atelier")
	game.wardrobe.open()
	game.wardrobe.cycle(0,1)
	game.wardrobe.cycle(1,1)
	await snap("new-wardrobe")
	game.free()
	await process_frame
	quit()
