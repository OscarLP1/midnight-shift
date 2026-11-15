extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
 game.update_hint()
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
 game._physics_process(0)
 game.security.dirt.append(Vector2(245,260))
 game.security.toggle_door()
 game.player.position = game.CASHIER
 game.security.hide_player()
 await create_timer(0.8).timeout
 await snap("refined-hide-door")
 game.security.hide_player()
 await create_timer(0.8).timeout
 game.crowd.spawn()
 var person = game.crowd.people[0]
 person.thief = false
 person.node.position = game.CUSTOMER_CHECKOUT
 person.path.clear()
 person.state = "queue"
 person.items = ["Papas Crujín","Papas Crujín","Papas Crujín"]
 person.basket = 3
 person.payment = "cash"
 game.crowd.queue.append(person)
 game.zone_stock[0] = 1
 game.crowd.tick(0.01)
 await snap("refined-quantity")
 game.interact()
 await snap("refined-checkout")
 game.free()
 await process_frame
 quit()
