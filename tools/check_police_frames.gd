extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_process(false)
	game.set_physics_process(false)
	game.security.set_process(false)
	var gallery := CanvasLayer.new()
	gallery.layer = 100
	root.add_child(gallery)
	var back := ColorRect.new()
	back.color = Color("202d38")
	back.size = Vector2(640,408)
	gallery.add_child(back)
	for direction in range(4):
		for frame in range(4):
			for running in range(2):
				var sprite = game.make_actor("police-officer")
				gallery.add_child(sprite)
				sprite.position = Vector2(50+frame*78+running*320,65+direction*96)
				sprite.scale = Vector2(1.7,1.7)
				sprite.animation = ("run_" if running else "")+str(direction)
				sprite.frame = frame
				var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(sprite.animation,frame)
				assert(atlas.filter_clip)
				assert(atlas.region.end.y <= atlas.atlas.get_height())
				assert(atlas.atlas.resource_path == "res://assets/police-officer.png")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/police-all-frames.png")
	print("PASS: 32 police walk/run frames use the same bounded atlas; all four directions")
	game.queue_free()
	gallery.queue_free()
	await process_frame
	quit()
