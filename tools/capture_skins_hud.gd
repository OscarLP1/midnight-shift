extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.start(false)
 g.set_physics_process(false)
 g.events.muted=true
 await process_frame
 var buttons=[]
 for child in g.controls.get_children():
  if child is Button and child.visible and child.position.y<35:buttons.append(child)
 for i in range(buttons.size()):
  for j in range(i+1,buttons.size()):assert(not buttons[i].get_global_rect().intersects(buttons[j].get_global_rect()))
 for i in range(3):
  var asset=["police-officer","burglar","customer-doctor"][i]
  for d in range(4):
   var s=g.make_actor(asset)
   s.position=Vector2(260+d*75,145+i*55)
   g.add_child(s)
   g.Motion.face(s,d)
   if asset in ["police-officer","burglar"]:
    assert(s.sprite_frames.get_frame_texture(str(d),0)==s.sprite_frames.get_frame_texture("run_"+str(d),0) or s.sprite_frames.get_frame_texture(str(d),0).atlas==s.sprite_frames.get_frame_texture("run_"+str(d),0).atlas)
 g.message.text="Policía, ladrón y doctor: frente, espalda y perfiles"
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/skins-hud-review.png")
 print("PASS: HUD hit areas do not overlap; chase and walk share identity")
 g.queue_free()
 await process_frame
 quit()
