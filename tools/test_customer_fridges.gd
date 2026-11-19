extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.start(false)
 g.set_physics_process(false)
 g.crowd.spawn()
 g.crowd.spawn()
 var a=g.crowd.people[0]
 var b=g.crowd.people[1]
 for p in [a,b]:
  p.thief=false
  p.state="shopping"
  p.path.clear()
  p.targets=[g.crowd.SPOTS[3]]
  p.node.position=g.crowd.SPOTS[3]
  p.wait=1.0
 g.crowd.update_fridge_doors()
 assert(g.events.open_doors[0])
 assert(g.active)
 if DisplayServer.get_name()!="headless":
  await create_timer(0.6).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/customer-fridge-browsing.png")
 g.crowd.leave(a)
 g.crowd.update_fridge_doors()
 assert(g.events.open_doors[0])
 g.crowd.leave(b)
 g.crowd.update_fridge_doors()
 assert(not g.events.open_doors[0])
 assert(g.events.open_time[0]==0)
 g.events.open_doors[0]=true
 b.state="shopping"
 b.path.clear()
 g.crowd.update_fridge_doors()
 g.crowd.leave(b)
 g.crowd.update_fridge_doors()
 assert(g.events.open_doors[0])
 print("PASS: browsing opens fridge; last customer closes it; player-open door preserved; no pause")
 g.queue_free()
 await process_frame
 quit()
