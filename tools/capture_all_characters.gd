extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.start(false)
 g.set_physics_process(false)
 var layer=CanvasLayer.new()
 layer.layer=100
 root.add_child(layer)
 var bg=ColorRect.new()
 bg.color=Color("24323c")
 bg.size=Vector2(640,408)
 layer.add_child(bg)
 var assets=["customer-doctor","customer-pilot","customer-mechanic","customer-woman","customer-senior","customer-courier","customer-chef","customer-firefighter","customer-builder","police-officer","burglar","employee-modern"]
 for i in range(assets.size()):
  for d in range(4):
   var s=g.make_actor(assets[i])
   layer.add_child(s)
   s.position=Vector2(24+(i%6)*106+d*24,75+(i/6)*185)
   g.Motion.face(s,d)
  var l=Label.new()
  l.text=assets[i].replace("customer-","")
  l.position=Vector2(8+(i%6)*106,125+(i/6)*185)
  g.UIStyles.apply_label(l,10)
  layer.add_child(l)
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/all-character-review.png")
 quit()
