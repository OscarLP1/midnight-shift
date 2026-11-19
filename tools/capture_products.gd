extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.events.muted = true
	game.set_physics_process(false)
	for category in range(3):
		game.exploration.shelf(category)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/products-%d.png" % category)
	game.queue_free()
	await process_frame
	quit()
