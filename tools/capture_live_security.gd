extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start(false)
 game.set_physics_process(false)
 game.events.muted = true
 game.open_security_menu()
 game.security.call_police()
 for i in range(120): game._physics_process(1.0/60)
 await create_timer(0.1).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/live-security.png")
 game.free()
 await process_frame
 quit()
