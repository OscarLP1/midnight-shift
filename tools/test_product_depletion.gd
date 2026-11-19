extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.start(false)
 g.set_physics_process(false)
 g.events.muted = true
 g.zone_stock[0]=3
 g.sync_products()
 assert(g.product_quantity("Papas Crujín")==1)
 g.take_product("Papas Crujín")
 assert(g.product_quantity("Papas Crujín")==0)
 assert(g.product_quantity("Galletas Luna")==1)
 assert(g.available_items({"items":["Papas Crujín"]}).is_empty())
 g.exploration.shelf(0)
 await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/product-empty-slot.png")
 g.close_city_panel()
 g.zone_stock[0]+=1
 g.sync_products()
 assert(g.product_quantity("Papas Crujín")==1)
 print("PASS: individual depletion, other products preserved, no empty-product sale, targeted replenishment")
 g.queue_free()
 await process_frame
 quit()
