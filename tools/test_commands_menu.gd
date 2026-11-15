extends SceneTree
func _initialize() -> void: call_deferred("run")
func labels(node: Node) -> Array[String]:
 var result: Array[String] = []
 if node is Button or node is Label: result.append(node.text)
 for child in node.get_children(): result.append_array(labels(child))
 return result
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 g.SaveStore.PATH = "user://test_commands_menu.json"
 root.add_child(g)
 await process_frame
 g.set_physics_process(false)
 assert(not g.active and "Comandos" in labels(g.panel))
 for child in g.panel.get_child(0).get_children():
  if child is Control:
   assert(child.position.x+child.size.x<=606 and child.position.y+child.size.y<=326)
 for child in g.controls.get_children():
  if child is Button: assert(not child.text.contains("Interactuar"))
 g.menus.commands(false)
 await process_frame
 assert(g.menus.commands_open and not g.active)
 for key in ["E","R","B","P","H","M","F2","Shift","Esc"]: assert(key in labels(g.panel))
 assert(g.panel.position.y+g.panel.size.y<=360)
 for child in g.panel.get_child(0).get_children():
  if child is Control:
   assert(child.position.x+child.size.x<=606 and child.position.y+child.size.y<=326)
 var escape := InputEventKey.new()
 escape.keycode = KEY_ESCAPE
 escape.pressed = true
 g._input(escape)
 await process_frame
 assert(not g.menus.commands_open and "Nueva partida" in labels(g.panel))
 g.start(false)
 await process_frame
 assert(g.active and g.hud.visible)
 g.pause_shift()
 await process_frame
 assert(g.panel.position.y+g.panel.size.y<=360)
 g.menus.commands(true)
 await process_frame
 g._input(escape)
 await process_frame
 assert(g.paused and not g.active and "Reanudar" in labels(g.panel))
 g.resume_shift()
 await process_frame
 g.touch_controls = true
 g.player.position = Vector2(200,104)
 var tap := InputEventScreenTouch.new()
 tap.position = g.player.position
 tap.pressed = true
 g._unhandled_input(tap)
 assert(g.events.open_doors[1])
 g.touch_controls = false
 var interact := InputEventKey.new()
 interact.keycode = KEY_E
 interact.pressed = true
 g._input(interact)
 assert(not g.events.open_doors[1])
 print("PASS: no interact button, main menu commands, all shortcuts, return to main/pause, UI bounds, touch and keyboard interaction")
 g.free()
 await process_frame
 quit()
