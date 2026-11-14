extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var seen := {}
	for i in range(7):
		game.crowd.spawn()
		var person: Dictionary = game.crowd.people.back()
		assert(not seen.has(person.look))
		seen[person.look] = true
		for d in range(4):
			assert(person.sprite.sprite_frames.get_frame_count(str(d))==4)
			game.Motion.face(person.sprite,d)
			assert(person.sprite.animation==str(d))
	assert(seen.size()==7)
	print("PASS: siete apariencias sin repetición, cuatro direcciones y 16 frames por cliente")
	quit()
