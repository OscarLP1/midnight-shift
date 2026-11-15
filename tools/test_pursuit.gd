extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_physics_process(false)
 g.start(false)
 g.events.muted = true
 g.crowd.spawn()
 var thief = g.crowd.people[0]
 thief.thief = true
 thief.evidence = true
 thief.items = ["Papas Crujín"]
 thief.node.position = Vector2(192,192)
 thief.path.clear()
 g.security.closed = true
 g.crowd.leave(thief)
 for i in range(1200): g.crowd.tick(1.0/60)
 assert(g.crowd.people.has(thief) and thief.node.position.y<=280)
 g.security.call_police()
 g.security.tick(20)
 assert(g.security.police_state=="arriving" and not is_instance_valid(g.security.officer))
 for i in range(240): g.security.tick(1.0/60)
 assert(not is_instance_valid(g.security.officer))
 for i in range(7200):
  g.security.tick(1.0/60)
  g.crowd.tick(1.0/60)
  if g.security.police_state=="idle": break
 assert(g.security.police_state=="idle" and not g.crowd.people.has(thief))
 g.security.closed = false
 var routes := {}
 var actions := {}
 for i in range(20):
  g.security.spawn_dog()
  routes[str(g.security.dog_path)] = true
  actions[g.security.dog_action] = true
  g.security.dog.free()
 assert(routes.size()>3 and actions.size()==3)
 g.crowd.reset()
 g.crowd.spawn()
 thief = g.crowd.people[0]
 thief.thief = true
 thief.evidence = true
 thief.node.position = g.player.position
 assert(g.crowd.intervene())
 assert(thief.state=="leaving" and not g.crowd.queue.has(thief))
 var escapes := 0
 for i in range(500):
  thief.erase("escape_allowed")
  g.security.begin_chase()
  if thief.escape_allowed: escapes += 1
 assert(escapes>190 and escapes<310)
 g.security.closed = true
 thief.erase("escape_allowed")
 g.security.begin_chase()
 assert(not thief.escape_allowed)
 g.open_security_menu()
 await process_frame
 assert(g.security_panel.position.y+g.security_panel.size.y<=360 and g.active)
 print("PASS: closed exits, car parks before officer, pursuit/custody/departure, dog route/action diversity, no thief checkout, 50 percent open-door draws, zero closed-door escape, UI bounds")
 g.free()
 await process_frame
 quit()
