extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for pair in [[Vector2.DOWN,"0"],[Vector2.UP,"1"],[Vector2.LEFT,"2"],[Vector2.RIGHT,"3"]]:
		game.Motion.animate(game.actor,pair[0])
		assert(game.actor.animation == pair[1])
	game.Motion.animate(game.actor,Vector2.ZERO)
	assert(not game.actor.is_playing() and game.actor.animation == "3")
	game.crowd.thief_times.assign([0.0])
	game.crowd.spawn()
	var sprite = game.crowd.people[0].sprite
	assert(game.crowd.people[0].thief)
	for pair in [[Vector2.DOWN,"0"],[Vector2.UP,"1"],[Vector2.LEFT,"2"],[Vector2.RIGHT,"3"]]:
		game.Motion.animate(sprite,pair[0],100)
		assert(game.Motion.facing(sprite)==int(pair[1]) and sprite.is_playing())
	game.Motion.animate(sprite,Vector2.ZERO)
	assert(sprite.frame==1 and not sprite.is_playing())
	for direction in range(4): assert(sprite.sprite_frames.get_frame_count(str(direction))==4)
	game.set_location("cafe")
	assert(game.actor.scale == Vector2(1.6,1.6))
	game.set_location("store")
	assert(game.actor.scale == Vector2.ONE and game.actor.position.y == -20)
	print("PASS: cuatro direcciones, idle conserva orientación, variantes completas y escala restaurada")
	quit()
