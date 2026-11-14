extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
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
 for i in range(7200):
  game.crowd.tick(1.0/60)
  if not game.crowd.first().is_empty(): break
 game.security.spawn_dog()
 game.security.dog.position = Vector2(255,250)
 game.security.call_police()
 game.security.tick(21)
 for i in range(420): game.security.tick(1.0/60)
 game.progression.owned.assign(["storage","register","security"])
 game.player.position = Vector2(150,264)
 game._physics_process(0)
 await snap("art-store")
 game.enter_city()
 game.player.position = Vector2(40,210)
 game.city_interact()
 game._physics_process(0)
 await snap("art-modistas")
 game.free()
 await process_frame
 quit()
