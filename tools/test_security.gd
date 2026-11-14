extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_physics_process(false)
 g.start(false)
 g.events.muted = true
 g.events.tick(300)
 assert(not g.events.spoiled.has(true))
 g.player.position = Vector2(96,104)
 g.events.interact()
 g.events.tick(260)
 g.events.interact()
 g.events.tick(300)
 assert(not g.events.spoiled[0] and g.events.open_time[0]==0)
 g.security.toggle_door()
 g.security.spawn_dog()
 assert(not is_instance_valid(g.security.dog))
 g.security.toggle_door()
 g.security.spawn_dog()
 assert(is_instance_valid(g.security.dog))
 g.security.carrying = true
 g.zone_stock[0] -= 1
 var stock: int = g.stock
 g.player.position = g.security.dog.position
 assert(g.security.interact() and g.stock==stock+1)
 g.player.position = g.CASHIER
 g.security.hide_player()
 assert(g.security.hiding)
 g.security.hide_player()
 g.crowd.spawn()
 var thief = g.crowd.people[0]
 thief.thief = true
 thief.evidence = true
 g.security.call_police()
 g.security.tick(21)
 assert(not thief.thief and thief.state=="leaving")
 print("PASS: closed refrigeration safe, closing resets timer, blocked dogs, recovery, hiding and police")
 g.free()
 await process_frame
 quit()
