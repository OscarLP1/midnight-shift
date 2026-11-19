extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start(false)
 game.events.muted=true
 game.set_physics_process(false)
 game.player.position=Vector2(410,105)
 var details
 for child in game.get_children():
  if child.get_script()==game.StoreDetails: details=child
 assert(details!=null)
 assert(game.restock_button.size==Vector2(88,26))
 assert(is_equal_approx(game.restock_button.position.y+game.restock_button.size.y/2,384.0))
 assert(details.z_index+1<game.player.z_index)
 game.crowd.spawn()
 var customer=game.crowd.people[0]
 customer.node.position=Vector2(180,105)
 customer.path.clear()
 customer.state="queue"
 assert(details.z_index+1<customer.node.z_index)
 details.set_process(false)
 for frame in range(4):
  for i in range(5): details.amounts[i]=frame/3.0
  details._process(0)
  for i in range(5):
   assert(details.door_sprites[i*2+1].position.y==54)
   assert(details.door_sprites[i*2+1].rotation==0)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/fridge-doors-%d.png" % frame)
 game.events.open_doors.assign([true,false,true,false,true])
 details.set_process(true)
 for step in range(6): details._process(0.1)
 assert(details.amounts[0]>0.99 and details.amounts[1]<0.01 and details.amounts[2]>0.99)
 print("PASS: all four visual states rendered; independent door animation; live game")
 game.queue_free()
 await process_frame
 quit()
