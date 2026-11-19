extends SceneTree
func _initialize(): call_deferred("run")
func snap(name):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/"+name+".png")
func check_text(node):
 if node is Label or node is Button:
  var regex=RegEx.new()
  regex.compile("\\b(WASD|Shift|Esc)\\b|\\b[ERVHPMB] ·|· [ERVHPMB]\\b")
  assert(regex.search(node.text)==null,"Keyboard hint on mobile: "+node.text)
 for child in node.get_children(): check_text(child)
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_physics_process(false)
 for dimensions in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1440,1080)]:
  root.size=dimensions
  await process_frame
  await process_frame
  var full=root.get_visible_rect()
  var safe=Rect2(full.position+Vector2(24,6),full.size-Vector2(40,14))
  root.set_meta("test_safe_rect",safe)
  g.touch_controls=true
  g.start(false)
  g.player.position=Vector2(96,104)
  g._physics_process(0)
  await process_frame
  g.responsive_ui.refresh()
  for child in g.controls.get_children():
   if child is Button and child.visible: assert(safe.grow(1).encloses(child.get_global_rect()),str(child.get_global_rect()))
  assert(safe.encloses(g.joystick.get_global_rect()))
  assert(g.responsive_ui.primary.visible)
  assert(g.responsive_ui.primary.text=="Abrir nevera")
  g.responsive_ui.primary.pressed.emit()
  g.responsive_ui.refresh()
  assert(g.events.open_doors[0])
  assert(g.responsive_ui.inspect.visible)
  check_text(g.controls)
  assert(not "Vevisar" in g.message.text)
  assert(not "Cerrareponer" in g.message.text)
  await snap("mobile-responsive-"+str(dimensions.x))
  g.menus.commands(true)
  await process_frame
  await process_frame
  g.panel.center_in_viewport()
  g.responsive_ui.refresh()
  assert(safe.grow(1).encloses(g.panel.get_global_rect()))
  assert(not g.joystick.visible)
  check_text(g.controls)
  await snap("mobile-controls-"+str(dimensions.x))
  for open_menu in [g.exploration.shelf.bind(0),g.exploration.fridge.bind(0),g.commerce.cafe,g.commerce.upgrades,g.wardrobe.open,g.exploration.purchase_stock]:
   open_menu.call()
   await process_frame
   await process_frame
   g.panel.center_in_viewport()
   g.responsive_ui.refresh()
   assert(safe.grow(1).encloses(g.panel.get_global_rect()))
   check_text(g.controls)

 g.menus.commands_open=false
 g.close_city_panel()
 g.open_security_menu()
 assert(g.active)
 g._notification(g.NOTIFICATION_WM_GO_BACK_REQUEST)
 await process_frame
 assert(not is_instance_valid(g.security_panel))
 g._notification(g.NOTIFICATION_WM_GO_BACK_REQUEST)
 assert(g.paused)
 g._notification(g.NOTIFICATION_WM_GO_BACK_REQUEST)
 assert(g.active and not g.paused)
 root.remove_meta("test_safe_rect")
 root.size=Vector2i(1280,816)
 g.touch_controls=false
 g.menus.commands(false)
 await process_frame
 var texts=[]
 for child in g.panel.get_child(0).get_children():
  if child is Label: texts.append(child.text)
 assert("WASD" in texts)
 print("PASS: 16:9, 21:9, 4:3 plus cutout insets; contained HUD and menus; mobile actions work; no keyboard hints; desktop commands preserved")
 g.queue_free()
 await process_frame
 quit()
