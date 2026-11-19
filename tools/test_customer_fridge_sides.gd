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
 for zone in range(3,8):
  for p in [a,b]:
   p.state="shopping"
   p.targets=[g.crowd.SPOTS[zone]]
   g.crowd.plan(p,p.targets[0])
   assert(not p.path.is_empty())
   assert(absf(p.path[-1].x-g.crowd.SPOTS[zone].x)==24)
   assert(p.path[-1].y==104)
  assert(a.fridge_side!=b.fridge_side)
 for p in [a,b]:
  p.node.position=p.path[-1]
  p.path.clear()
  p.wait=1.0
 g.crowd.update_fridge_doors()
 assert(g.events.open_doors[4])
 if DisplayServer.get_name()!="headless":
  await create_timer(0.7).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/customer-fridge-sides.png")
 print("PASS: both side positions navigable in all five fridges; paired customers choose opposite sides; correct door opens")
 g.queue_free()
 await process_frame
 quit()
