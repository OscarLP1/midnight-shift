extends SceneTree
func _initialize(): call_deferred("run")
func snap(name):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/"+name+".png")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.start(false)
 g.set_physics_process(false)
 g.events.next_apparition=INF
 for kind in range(3):
  g.events.monster_index=kind
  g.events.event_count=kind
  g.events.apparition=1.0
  g.events.disturbance_in=0
  g.events.tick(0.2)
 assert(g.events.fallen.size()==9)
 for zone in range(3): assert(g.events.damaged[zone])
 assert(g.events.open_doors.has(true))
 g.events.apparition=0.1
 g.events.tick(0.2)
 assert(g.events.damaged.has(true))
 var stock=g.zone_stock.duplicate()
 if DisplayServer.get_name()!="headless": await snap("haunt-damage")
 for zone in range(8):
  if not g.events.damaged[zone]: continue
  g.player.position=g.crowd.SPOTS[zone]
  assert(g.events.interact())
  assert(g.events.repairing==zone)
  assert(g.active)
  g.events.tick(3.1)
  assert(not g.events.damaged[zone])
  if zone>=3:
   assert(not g.events.open_doors[zone-3])
   assert(g.events.open_time[zone-3]==0)
 assert(g.events.fallen.is_empty())
 assert(g.zone_stock==stock)
 if DisplayServer.get_name()!="headless": await snap("haunt-repaired")
 print("PASS: all monster types disturb doors and shelves; damage persists; live repairs clear damage and reset fridge timer without adding stock")
 g.queue_free()
 await process_frame
 quit()
