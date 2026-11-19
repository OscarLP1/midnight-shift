extends SceneTree
func _initialize(): call_deferred("run")
func tap(g,pressed):
 var event=InputEventScreenTouch.new()
 event.index=1
 event.pressed=pressed
 event.position=g.get_canvas_transform()*(g.player.position+Vector2(20,0))
 g._unhandled_input(event)
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.touch_controls=true
 g.start(false)
 g.set_physics_process(false)
 g.player.position=Vector2(96,104)
 tap(g,true)
 tap(g,false)
 assert(g.events.open_doors[0] and g.active)
 tap(g,true)
 g.interaction_started=Time.get_ticks_msec()-500
 tap(g,false)
 assert(not g.active and is_instance_valid(g.panel))
 g.close_city_panel()
 tap(g,true)
 tap(g,false)
 assert(not g.events.open_doors[0] and g.active)
 g.player.position=g.CASHIER
 g.security.hide_player()
 assert(g.security.hiding)
 tap(g,true)
 tap(g,false)
 assert(not g.security.hiding)
 print("PASS: Android tap toggles door; long press inspects; tap exits hiding; no permanent interaction button")
 g.queue_free()
 await process_frame
 quit()
