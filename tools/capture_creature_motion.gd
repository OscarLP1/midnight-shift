extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start(false)
 game.set_physics_process(false)
 game.events.muted = true
 game.crowd.spawn_in = 999
 game.player.position = Vector2(270,270)
 game.night = 3
 game.events.reset_shift()
 game.elapsed = game.events.horror_start()
 game._physics_process(0)
 for i in range(90): game.events.tick(1.0/60)
 await create_timer(0.35).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/creature-in-store.png")
 game.free()
 await process_frame
 quit()
