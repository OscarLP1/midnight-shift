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
 game.set_physics_process(false)
 await snap("main-menu-commands")
 game.menus.commands(false)
 await snap("commands-guide")
 game.free()
 await process_frame
 quit()
