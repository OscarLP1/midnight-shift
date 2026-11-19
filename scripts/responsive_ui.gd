extends Node
var game
var primary: Button
var inspect: Button
var prefix_regex := RegEx.new()
var suffix_regex := RegEx.new()

static func safe_rect(viewport: Viewport) -> Rect2:
	var full := viewport.get_visible_rect()
	if viewport.has_meta("test_safe_rect"): return viewport.get_meta("test_safe_rect")
	if OS.get_name()=="Android":
		var physical := Rect2(DisplayServer.get_display_safe_area())
		if physical.has_area():
			var inverse := viewport.get_screen_transform().affine_inverse()
			var safe := Rect2(inverse*physical.position,inverse*physical.end-inverse*physical.position).intersection(full)
			if safe.has_area(): return safe
	return full

func _ready() -> void:
	prefix_regex.compile("\\b(?:E|R|V|H|B|P|M|Esc)\\s*·\\s*")
	suffix_regex.compile("\\s*·\\s*(?:E|R|V|H|B|P|M|Esc)\\b")
	primary = make_action()
	inspect = make_action()
	primary.pressed.connect(use_action)
	inspect.text = "Ver productos"
	inspect.pressed.connect(game.events.inspect_fridge)
	refresh()

func make_action() -> Button:
	var button := Button.new()
	button.clip_text = true
	button.custom_minimum_size = Vector2(112,34)
	button.size = Vector2(112,34)
	button.set_meta("compact_hud",true)
	game.UIStyles.apply(button)
	button.hide()
	game.controls.add_child(button)
	return button

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	var safe := safe_rect(get_viewport())
	get_viewport().set_meta("ui_safe_rect",safe)
	layout(safe)
	var show_touch: bool = game.touch_controls and game.active and game.hud.visible
	var show_actions: bool = show_touch and not is_instance_valid(game.security_panel)
	game.joystick.visible = show_touch
	var action := context_action()
	primary.visible = show_actions and not action.is_empty()
	primary.text = action
	inspect.visible = show_actions and game.location=="store" and game.player.position.y<116 and game.events.nearby_damage()<0 and game.events.open_doors[clampi(int((game.player.position.x-40)/112),0,4)]
	if game.touch_controls:
		sanitize(game.controls)
		if game.security.hiding: game.hint.text = "Toca Salir del escondite"
		elif game.events.nearby_damage()>=0: game.hint.text = "Toca Reparar y permanece cerca" if game.events.apparition<=0 else "Espera a que se vaya para reparar"
		elif game.location=="store" and game.player.position.y<116: game.hint.text = "Toca Abrir / Cerrar · Ver productos para examinar"
		elif not action.is_empty(): game.hint.text = "Toca "+action
		else: game.hint.text = "Mando izquierdo: moverse · Al borde: correr"

func layout(safe: Rect2) -> void:
	var full := get_viewport().get_visible_rect()
	var top: ColorRect = game.hud_bands.get_child(0)
	top.position = Vector2.ZERO
	top.size = Vector2(full.size.x,safe.position.y+34)
	var bottom: ColorRect = game.hud_bands.get_child(1)
	bottom.position = Vector2(0,safe.end.y-48)
	bottom.size = Vector2(full.size.x,full.end.y-bottom.position.y)
	game.hud.position = safe.position+Vector2(14,9)
	game.hud.size.x = maxf(100,safe.size.x-196)
	for child in game.controls.get_children():
		if not child is Button or not child.has_meta("hud_action"): continue
		match child.get_meta("hud_action"):
			"Pausa": child.position = Vector2(safe.end.x-38,safe.position.y+2)
			"Seguridad": child.position = Vector2(safe.end.x-172,safe.position.y+2)
			"Cerrar turno": child.position = Vector2(safe.end.x-134,safe.position.y+4)
			"Reponer · R", "Mapa · M": child.position = Vector2(safe.end.x-102,safe.end.y-37)
	game.message.position = Vector2(safe.position.x+14,safe.end.y-45)
	game.hint.position = Vector2(safe.position.x+14,safe.end.y-24)
	game.message.size.x = maxf(120,safe.size.x-126)
	game.hint.size.x = game.message.size.x
	game.hour_banner.position = Vector2(safe.get_center().x-120,safe.position.y+70)
	game.joystick.position = Vector2(safe.position.x+16,safe.end.y-154)
	primary.position = Vector2(safe.end.x-128,safe.end.y-94)
	inspect.position = Vector2(safe.end.x-128,safe.end.y-136)

func context_action() -> String:
	if game.location=="city":
		if not game.nearby_shop().is_empty(): return "Entrar"
		if (game.street==0 and game.player.position.x<60) or (game.street==1 and game.player.position.x>580): return "Otra calle"
		return ""
	if game.location!="store":
		var p: Vector2 = game.District.local_point(game.location,game.player.position)
		if p.y>285 and absf(p.x-320)<65: return "Salir"
		return "Hablar" if p.y<185 else ""
	if game.security.hiding: return "Salir del escondite"
	if game.events.nearby_damage()>=0: return "Reparar" if game.events.apparition<=0 else ""
	if is_instance_valid(game.security.dog) and game.security.dog.position.distance_to(game.player.position)<38: return "Atrapar perro"
	for dirt in game.security.dirt:
		if dirt.distance_to(game.player.position)<30: return "Limpiar"
	for person in game.crowd.people:
		if person.evidence and person.node.position.distance_to(game.player.position)<48: return "Recuperar"
	if game.player.position.y<116:
		var index := clampi(int((game.player.position.x-40)/112),0,4)
		return "Cerrar nevera" if game.events.open_doors[index] else "Abrir nevera"
	if game.player.position.distance_to(game.CASHIER)<28: return "Cobrar"
	return "Ver productos" if game.events.shelf_near(game.player.position)>=0 else ""

func use_action() -> void:
	if not game.active: return
	if game.security.hiding: game.security.hide_player()
	else: game.interact()

func sanitize(node: Node) -> void:
	if node is Label or node is Button:
		var text: String = node.text
		text = prefix_regex.sub(text,"",true)
		text = suffix_regex.sub(text,"",true)
		text = text.replace("Comandos","Controles").replace("Pulsa H para salir del escondite antes de atender.","Toca Salir del escondite antes de atender.")
		text = text.replace("pulsa E para reparar","toca Reparar").replace("E: ","")
		node.text = text
	for child in node.get_children(): sanitize(child)
