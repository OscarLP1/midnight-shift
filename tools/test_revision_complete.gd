extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_physics_process(false)
 g.start(false)
 g.events.muted = true
 assert(g.crowd.thief_times.size()>=2 and g.crowd.thief_times.size()<=4)
 assert(g.cold_stock()+g.shelf_stock()==g.stock)
 g.stock = 0
 g.crowd.spawn()
 var p = g.crowd.people[0]
 p.thief = false
 p.node.position = g.crowd.SPOTS[0]
 p.path.clear()
 p.targets.assign([g.crowd.SPOTS[0]])
 g.crowd.tick(7)
 assert(p.state=="leaving" and not g.crowd.queue.has(p))
 g.stock = 24
 g.crowd.reset()
 g.crowd.spawn()
 p = g.crowd.people[0]
 p.thief = true
 p.node.position = g.crowd.SPOTS[0]
 p.targets.assign([g.crowd.SPOTS[0]])
 p.path.clear()
 g.crowd.tick(7)
 assert(p.stolen_count>=1 and p.stolen_count<=5)
 var after: int = g.stock
 g.player.position = p.node.position
 g.crowd.intervene()
 assert(g.stock==after+p.get("stolen_count",0) or p.stolen_count==0)
 g.security.closed = true
 g.security.call_police()
 g.security.tick(20)
 for i in range(9000):
  g.crowd.tick(1.0/60)
  g.security.tick(1.0/60)
  if g.security.police_state=="idle": break
 assert(g.security.police_state=="idle")
 g.player.position = g.CASHIER
 g.security.hide_player()
 for i in range(60): g.security._process(1.0/60)
 assert(g.security.hide_amount>0.9 and g.actor.modulate.a<0.1)
 g.security.hide_player()
 g.security.closed = false
 g.security.spawn_dog()
 g.player.position = g.security.dog.position
 assert(g.security.interact() and g.security.dog_caught)
 g.player.position = Vector2(320,272)
 g.security.tick(0.1)
 assert(not is_instance_valid(g.security.dog))
 g.night = 2
 g.events.reset_shift()
 g.elapsed = g.events.horror_start()
 g.events.tick(0.1)
 assert(g.events.open_doors.has(true))
 g.events.reset_shift()
 g.night = 1
 g.elapsed = g.events.horror_start()
 g.events.tick(0.1)
 var before: Vector2 = g.events.monster_position
 for i in range(60): g.events.tick(1.0/60)
 assert(g.events.monster_position.distance_to(before)>1)
 print("PASS: night thief quota, stock groups, empty stock departure, theft quantities, police cycle, hiding animation, dog capture/removal, haunted doors and moving monster")
 g.free()
 await process_frame
 quit()
