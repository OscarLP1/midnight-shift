extends SceneTree

var game
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_physics_process(false)
	await process_frame
	game.enter_city()
	game._physics_process(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/city-preview.png")
	game.player.position = Vector2(367,210)
	game.show_upgrades()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/upgrades-preview.png")
	game.begin_shift()
	game.progression.restore(["storage","register","security"])
	game._physics_process(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/store-preview.png")
	game.crowd.rng.seed = 5721
	for i in range(1500): game.crowd.tick(1.0/30)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/crowd-preview.png")
	for kind in ["cafe","hardware"]:
		game.enter_interior(kind)
		game.player.position = Vector2(320,240)
		game._physics_process(0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/"+kind+"-preview.png")
	quit()
