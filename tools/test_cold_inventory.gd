extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_physics_process(false)
 g.start(false)
 g.events.muted = true
 g.player.position = Vector2(96,104)
 g.events.interact()
 g.player.position = Vector2(200,104)
 g.events.interact()
 assert(g.events.open_doors[0] and g.events.open_doors[1])
 var shelves: int = g.zone_stock[0]
 g.events.tick(269)
 assert(not g.events.spoiled[0])
 g.events.tick(1)
 assert(g.events.spoiled[0] and g.events.spoiled[1])
 assert(g.zone_stock[3]==0 and g.zone_stock[4]==0 and g.zone_stock[0]==shelves)
 g.events.interact()
 assert(not g.events.open_doors[1] and g.events.open_doors[0])
 g.events.restock()
 assert(g.zone_stock[4]==4 and not g.events.spoiled[1] and g.zone_stock[3]==0)
 g.player.position = Vector2(192,192)
 g.events.restock()
 assert(g.zone_stock[0]==shelves+4)
 g.checkout_person = {"items":["Leche Alba","Papas Crujín","Agua Bruma"]}
 var products = g.checkout_items()
 assert("Papas Crujín" in products and not "Agua Bruma" in products)
 assert(g.product_zone("Leche Alba")==5 and g.product_zone("Queso Fresco")==7)
 print("PASS: independent doors, 3-hour spoilage, isolated stock, targeted restocking, refrigerated products and checkout availability")
 g.free()
 await process_frame
 quit()
