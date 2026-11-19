extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start(false)
	game.set_physics_process(false)
	game.events.muted = true
	game.active = false
	game.player.visible = false
	var names := ["Chef","Bombera","Constructor"]
	for i in range(3):
		var sprite = game.make_actor(game.crowd.CUSTOMER_ASSETS[9+i])
		sprite.position = Vector2(220+i*100,240)
		sprite.scale = Vector2.ONE*1.5
		game.add_child(sprite)
		for direction in range(4): assert(sprite.sprite_frames.get_frame_count(str(direction))==4)
		var label := Label.new()
		label.text = names[i]
		label.position = Vector2(190+i*100,252)
		game.UIStyles.apply_label(label,10)
		game.add_child(label)
	game.hud.text = "NUEVOS CLIENTES · CUATRO APARIENCIAS PROPIAS"
	game.message.text = "Chef · Bombera · Constructor"
	game.hint.text = "Aparición aleatoria junto al resto de clientes"
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/customer-catalog-new.png")
	print("PASS: four new customer atlases with four directions and four frames")
	game.queue_free()
	await process_frame
	quit()
