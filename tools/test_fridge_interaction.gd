extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.start(false)
 g.set_physics_process(false)
 await process_frame
 g.player.position=Vector2(80,105)
 var previous_panel=g.panel
 g.events.interact()
 assert(g.active)
 assert(g.events.open_doors[0])
 assert(g.panel==previous_panel)
 var before: float=g.events.open_time[0]
 g.events.tick(0.5)
 assert(g.events.open_time[0]>before)
 g.events.interact()
 assert(g.active)
 assert(not g.events.open_doors[0])
 assert(g.events.open_time[0]==0)
 g.events.inspect_fridge()
 assert(g.active)
 g.events.interact()
 g.events.inspect_fridge()
 assert(is_instance_valid(g.panel))
 assert(not g.active)
 print("PASS: E toggles without pausing or opening product UI; time advances; close resets timer; V inspects only open fridge")
 g.queue_free()
 await process_frame
 quit()
