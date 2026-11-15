extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.start(false)
 g.set_physics_process(false)
 g.events.muted = true
 g.open_security_menu()
 assert(g.active and is_instance_valid(g.security_panel))
 var elapsed: float = g.elapsed
 g._physics_process(0.1)
 assert(g.elapsed>elapsed)
 g.security.call_police()
 assert(g.security.police==20)
 g.soundscape._process(0.1)
 assert(not g.soundscape.siren_requested)
 for i in range(210): g._physics_process(0.1)
 g.soundscape._process(0.1)
 assert(g.security.police_state=="arriving" and g.soundscape.siren_requested)
 assert(is_instance_valid(g.security_panel) and g.active)
 g.close_security_menu()
 g.security.reset()
 g.crowd.reset()
 g.crowd.spawn_in = 9999
 g.crowd.spawn()
 var thief = g.crowd.people[0]
 thief.thief = true
 thief.evidence = true
 thief.state = "concealing"
 thief.wait = -999
 thief.node.position = Vector2(352,192)
 thief.path.clear()
 g.security.closed = true
 g.security.call_police()
 var entered := false
 var exit_opened := false
 var closed_after := false
 var captured := false
 for i in range(14000):
  g.crowd.tick(1.0/60)
  g.security.tick(1.0/60)
  g.security._process(1.0/60)
  g.security.entrance_view._process(1.0/60)
  if g.security.police_access and g.security.police_state=="chasing": entered = true
  if not g.security.detainees.is_empty(): captured = true
  if g.security.police_access and g.security.police_state=="escorting": exit_opened = true
  if g.security.police_state=="securing_exit":
   assert(not g.security.police_access and g.security.closed)
   closed_after = true
  if g.security.police_state=="idle" and g.security.police<0: break
 assert(entered and captured and exit_opened and closed_after)
 assert(g.security.closed and g.security.entrance_view.closure>0.95)
 assert(not g.crowd.people.has(thief))
 g.soundscape._process(0.1)
 assert(not g.soundscape.siren_requested)
 for child in g.controls.get_children():
  if child is Button and child.has_meta("hud_icon"):
   assert(child.text=="" and child.icon!=null and child.flat)
 g.open_security_menu()
 assert(g.active)
 g.pause_shift()
 assert(not g.active and not is_instance_valid(g.security_panel))
 print("PASS: live panel advances clock and patrol, siren on visible arrival, controlled entry, arrest, opened escort exit, closed exit, icon-only controls and real pause")
 g.free()
 await process_frame
 quit()
