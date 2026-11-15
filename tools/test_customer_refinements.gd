extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 g.SaveStore.PATH = "user://test_customer_refinements.json"
 root.add_child(g)
 await process_frame
 g.set_physics_process(false)
 g.start(false)
 g.crowd.rng.seed = 5721
 g.events.muted = true
 g.crowd.spawn_in = 999
 g.crowd.spawn()
 var p = g.crowd.people[0]
 p.thief = false
 p.payment = "cash"
 p.state = "queue"
 p.items = ["Papas Crujín","Papas Crujín","Papas Crujín"]
 p.basket = 3
 p.node.position = g.CUSTOMER_CHECKOUT
 p.path.clear()
 g.crowd.queue.append(p)
 g.zone_stock[0] = 1
 g.crowd.tick(0.01)
 assert(p.bubble.text=="1 artículo")
 assert(g.available_items(p).size()==1)
 g.player.position = g.CASHIER
 g.interact()
 assert(g.payment_method=="cash")
 g.set_payment("card")
 assert(g.payment_method=="cash")
 g.complete_sale()
 assert(g.zone_stock[0]==0 and g.money==104)
 await process_frame
 g.crowd.reset()
 g.crowd.spawn_in = 999
 g.crowd.spawn()
 var civilian = g.crowd.people[0]
 civilian.thief = false
 civilian.node.position = Vector2(192,192)
 civilian.path.clear()
 g.crowd.spawn()
 var thief = g.crowd.people[1]
 thief.node.position = Vector2(352,192)
 thief.path.clear()
 thief.thief = true
 thief.evidence = true
 thief.state = "concealing"
 thief.wait = -999
 g.security.closed = true
 var distance := 0.0
 var destinations := {}
 for i in range(1200):
  var before: Vector2 = civilian.node.position
  g.crowd.tick(1.0/60)
  distance += civilian.node.position.distance_to(before)
  destinations[str(civilian.get("panic_target",Vector2.ZERO))] = true
  assert(civilian.sprite.scale==Vector2.ONE and civilian.bubble.text=="")
  assert(civilian.node.position.y<=280)
  for obstacle in g.obstacles: assert(not obstacle.has_point(civilian.node.position))
 assert(distance>300 and destinations.size()>=2)
 assert(g.security.DOG_TROT_SPEED<75 and g.security.DOG_ESCAPE_SPEED<88)
 g.security._process(0.1)
 g.security.entrance_view._process(1)
 assert(g.security.entrance_view.closure==1)
 g.player.position = g.CASHIER
 g.security.hide_player()
 for i in range(60): g.security._process(1.0/60)
 assert(not g.actor.visible and g.security.hiding_actor.frame==3)
 assert(g.security.hiding_actor.scale==Vector2.ONE and g.actor.modulate.a==1)
 print("PASS: customer-chosen tender, real unit count, exact stock debit, civilian panic at full size without text, blocked exit, varied routes, slower dog, sliding closure and unscaled crouch")
 g.free()
 await process_frame
 quit()
