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
	for i in range(2400): game.crowd.tick(1.0/60)
	game.events.weather = 1
	game.events.door = 1
	game._physics_process(0)
	await create_timer(0.4).timeout
	await snap("revision-store")
	game.exploration.shelf(0)
	await snap("revision-shelf")
	game.close_city_panel()
	game.enter_city()
	game.open_map()
	await snap("revision-map")
	game.close_city_panel()
	game.open_styles()
	await snap("revision-styles")
	game.close_city_panel()
	game.begin_shift()
	game.elapsed = game.events.horror_start()
	game.events.tick(0.01)
	game.elapsed = game.events.horror_start() + game.seconds_per_game_hour()
	game.events.tick(0.01)
	game.events.weather = 2
	game._physics_process(0)
	await snap("revision-night")
	quit()
