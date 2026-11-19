extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_physics_process(false)
	game.events.muted = true
	game.security.patrol_texture = load("res://assets/patrol-car.png")
	game.security.patrol_time = 1
	game.security.patrol_x = 350
	game.security.queue_redraw()
	game.hud.text = "N1 · 22:00    $100    Neveras 5 / Estantes 6"
	game.message.text = "La patrulla se ve completa. Los avisos están debajo del escenario."
	game.update_hint()
	assert(game.message.position.y>=360)
	assert(game.hint.position.y>=360)
	assert(game.world_camera.position==Vector2(320,204))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/patrol-footer.png")
	game.queue_free()
	await process_frame
	quit()
