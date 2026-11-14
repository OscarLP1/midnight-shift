extends Node2D

const UIStyles = preload("res://scripts/ui_styles.gd")
const ExplorationUI = preload("res://scripts/exploration_ui.gd")
var exploration := ExplorationUI.new()
var map_button: Button
var street := 0
var soundscape: Node
var security: Node2D
const Wardrobe = preload("res://scripts/wardrobe.gd")
var wardrobe := Wardrobe.new()
var atelier_sign: Label
const CommerceUI = preload("res://scripts/commerce_ui.gd")
var commerce := CommerceUI.new()
var payment_method := "card"
var cafe_menu_open := false
const Motion = preload("res://scripts/character_motion.gd")

const CustomerCrowd = preload("res://scripts/customer_crowd.gd")
var crowd := CustomerCrowd.new()
var checkout_person: Dictionary = {}
var interior_bodies: Array[StaticBody2D] = []
const Progression = preload("res://scripts/progression.gd")
const StoreDetails = preload("res://scripts/store_details.gd")
var progression := Progression.new()
var location := "store"
var background: Sprite2D
var foreground_props: Array[Sprite2D] = []
var store_bodies: Array[StaticBody2D] = []
var city_bodies: Array[StaticBody2D] = []
var shift_buttons: Array[Button] = []
var revenue := 0
var expenses := 0
var cafe_used := false
var hint: Label
var restock_button: Button
var touch_controls := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
const SaveStore = preload("res://scripts/save_store.gd")
const NightEvents = preload("res://scripts/weather_events.gd")
var events: NightEvents
const TouchStick = preload("res://scripts/virtual_joystick.gd")
var joystick: TouchStick
var transaction_open := false
var paused := false
var player: CharacterBody2D
var actor: AnimatedSprite2D
var customer: AnimatedSprite2D
var hud: Label
var message: Label
var panel: PanelContainer
var controls: CanvasLayer
const SHIFT_SECONDS := 720.0
const SHIFT_GAME_HOURS := 8
const SHIFT_START_HOUR := 22
var money := 100
var night := 1
var sold := 0
var zone_stock: Array[int] = [2,2,2,2,1,1,1,1]
var stock: int:
	get: return zone_stock.reduce(func(a,b): return a+b,0)
	set(value):
		zone_stock.assign([0,0,0,0,0,0,0,0])
		for i in range(maxi(0,value)): zone_stock[i%8] += 1
var elapsed := 0.0
var last_announced_hour := SHIFT_START_HOUR
var hour_flash := 0.0
var hour_banner: Label
var active := false
var customer_state := 0
var browsing := 0.0
var touch_vector := Vector2.ZERO
var obstacles := [Rect2(160,158,66,20), Rect2(318,158,67,20), Rect2(475,158,67,20), Rect2(72,228,90,26)]
const CASHIER = Vector2(112,272)
const CUSTOMER_CHECKOUT = Vector2(112,200)

func walkable_store(p: Vector2, visitors := false) -> bool:
	if p.x<46 or p.x>594 or p.y<104: return false
	if p.y>272:
		return visitors and p.x>=288 and p.x<=352 and p.y<=344
	return true

func _ready() -> void:
	ThemeDB.fallback_font = UIStyles.BODY
	ThemeDB.fallback_font_size = 13
	var settings := ConfigFile.new()
	if settings.load("user://interface.cfg")==OK:
		UIStyles.selected = clampi(int(settings.get_value("interface","style",0)),0,2)
	y_sort_enabled = true
	background = Sprite2D.new()
	background.texture = load("res://assets/store-modern.png")
	background.centered = false
	background.z_index = -10
	add_child(background)
	var prop_rects := [Rect2(157,121,72,59),Rect2(315,121,73,59),Rect2(472,121,73,59),Rect2(69,195,96,61)]
	for i in range(prop_rects.size()):
		var prop := Sprite2D.new()
		var rect: Rect2 = prop_rects[i]
		prop.texture = load("res://assets/store-prop-%d.png" % i)
		prop.centered = false
		var depth: float = 228 if i==3 else rect.end.y
		prop.position = Vector2(rect.position.x,depth)
		prop.offset.y = rect.position.y-depth
		add_child(prop)
		foreground_props.append(prop)
	for rect in obstacles + [Rect2(16,40,24,260),Rect2(600,40,24,260),Rect2(24,48,592,48),Rect2(24,280,250,24),Rect2(366,280,250,24)]:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		body.position = rect.get_center()
		body.add_child(shape)
		add_child(body)
		store_bodies.append(body)
	for rect in [Rect2(0,0,640,187),Rect2(0,230,640,130),Rect2(0,0,22,360),Rect2(618,0,22,360)]:
		var wall := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		wall.position = rect.get_center()
		wall.collision_layer = 0
		wall.add_child(shape)
		add_child(wall)
		city_bodies.append(wall)
	for rect in [Rect2(0,0,640,148),Rect2(0,0,30,360),Rect2(610,0,30,360),Rect2(0,330,640,30),Rect2(60,175,155,83),Rect2(425,175,155,83)]:
		var wall := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		wall.position = rect.get_center()
		wall.collision_layer = 0
		wall.add_child(shape)
		add_child(wall)
		interior_bodies.append(wall)
	crowd.setup(self)
	player = CharacterBody2D.new()
	player.position = CASHIER
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7
	collision.shape = circle
	player.add_child(collision)
	actor = make_actor("employee-modern")
	player.add_child(actor)
	add_child(player)
	customer = make_actor("customer-modern")
	customer.position = Vector2(320,340)
	customer.offset.y = -20
	customer.visible = false
	add_child(customer)
	events = NightEvents.new()
	add_child(events)
	events.setup(self)
	soundscape = preload("res://scripts/soundscape.gd").new()
	add_child(soundscape)
	soundscape.setup(self)
	security = preload("res://scripts/store_security.gd").new()
	add_child(security)
	security.game = self
	var details := StoreDetails.new()
	details.game = self
	add_child(details)
	commerce.setup(self)
	exploration.setup(self)
	wardrobe.setup(self)
	controls = CanvasLayer.new()
	add_child(controls)
	joystick = TouchStick.new()
	joystick.changed.connect(func(value: Vector2): touch_vector = value)
	controls.add_child(joystick)
	joystick.visible = touch_controls
	hud = Label.new()
	hud.position = Vector2(16,9)
	hud.add_theme_font_size_override("font_size",12)
	controls.add_child(hud)
	atelier_sign = Label.new()
	atelier_sign.text = "← CALLE MODISTAS"
	atelier_sign.position = Vector2(14,107)
	atelier_sign.add_theme_font_size_override("font_size",10)
	atelier_sign.add_theme_color_override("font_color",Color("eac6be"))
	atelier_sign.visible = false
	add_child(atelier_sign)
	hour_banner = Label.new()
	hour_banner.position = Vector2(200,86)
	hour_banner.size = Vector2(240,36)
	hour_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hour_banner.add_theme_font_size_override("font_size",22)
	hour_banner.add_theme_color_override("font_color",Color("ffdf9e"))
	hour_banner.visible = false
	controls.add_child(hour_banner)
	message = Label.new()
	message.position = Vector2(16,282)
	message.size = Vector2(600,20)
	message.clip_text = true
	message.add_theme_font_size_override("font_size",12)
	controls.add_child(message)
	hint = Label.new()
	hint.position = Vector2(16,303)
	hint.add_theme_font_size_override("font_size",12)
	hint.add_theme_color_override("font_color",Color("f1d29b"))
	controls.add_child(hint)
	button("Interactuar · E",Vector2(510,328),interact)
	button("Cerrar turno",Vector2(510,4),finish)
	button("Pausa",Vector2(425,4),pause_shift)
	button("Reponer · R",Vector2(370,328),events.restock)
	button("Seguridad",Vector2(16,328),open_security_menu)
	button("Mapa · M",Vector2(510,48),open_map)
	show_panel("TURNO DE MEDIANOCHE\nNoche tranquila, trabajo pendiente.\nWASD / flechas · E para interactuar\nTáctil: arrastra a la izquierda", "Nueva partida", start.bind(false), true)

func make_actor(asset: String) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var texture: Texture2D = load("res://assets/" + asset + ".png")
	for direction in range(4):
		var key := str(direction)
		frames.add_animation(key)
		frames.set_animation_speed(key, 8)
		for frame in range(4):
			var region := AtlasTexture.new()
			region.atlas = texture
			region.region = Rect2(frame*32,direction*48,32,48)
			frames.add_frame(key,region)
	sprite.sprite_frames = frames
	sprite.position.y = -20
	sprite.play("0")
	return sprite

func button(text: String, pos: Vector2, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	if touch_controls and b.position.y>316: b.position.y = 316
	b.custom_minimum_size = Vector2(76,40 if touch_controls else 28)
	b.pressed.connect(action)
	style_control(b)
	if text in ["Cerrar turno", "Reponer · R", "Seguridad"]: shift_buttons.append(b)
	if text == "Reponer · R":
		restock_button = b
		b.visible = false
	if text == "Mapa · M":
		map_button = b
		b.visible = false
		b.icon = UIStyles.icon("map")
	if text == "Interactuar · E": b.icon = UIStyles.icon("hand")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width",18)
	controls.add_child(b)

func show_panel(text: String, action: String, callback: Callable, continuation := false) -> void:
	if is_instance_valid(panel): panel.queue_free()
	joystick.reset()
	panel = PanelContainer.new()
	panel.position = Vector2(110,72)
	panel.custom_minimum_size = Vector2(420,190)
	style_control(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var label := Label.new()
	label.add_theme_font_size_override("font_size",14)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	var b := Button.new()
	b.text = action
	style_control(b)
	b.custom_minimum_size.y = 44
	b.pressed.connect(callback)
	column.add_child(b)
	if continuation and not SaveStore.load_game().is_empty():
		var resume := Button.new()
		resume.text = "Continuar"
		style_control(resume)
		resume.pressed.connect(start.bind(true))
		column.add_child(resume)
	controls.add_child(panel)

func start(resume: bool) -> void:
	if resume:
		var data := SaveStore.load_game()
		money = clampi(int(data.get("money",100)),0,1000000)
		night = maxi(1,int(data.get("night",1)))
		progression.restore(data.get("upgrades",[]) if data.get("upgrades",[]) is Array else [])
		stock = clampi(int(data.get("stock",12)),0,progression.capacity())
		if data.get("inventory") is Array and data.inventory.size()==8:
			for i in range(8): zone_stock[i] = clampi(int(data.inventory[i]),0,progression.capacity())
		if data.get("location") == "city":
			enter_city()
			return
	else:
		money = 100
		night = 1
		stock = 12
		progression.owned.clear()
	begin_shift()

func seconds_per_game_hour() -> float:
	return SHIFT_SECONDS / float(SHIFT_GAME_HOURS)

func shift_hours_passed() -> int:
	return mini(int(elapsed / seconds_per_game_hour()), SHIFT_GAME_HOURS)

func shift_hour() -> int:
	return (SHIFT_START_HOUR + shift_hours_passed()) % 24

func advance_shift_clock(delta: float) -> void:
	hour_flash = maxf(0.0, hour_flash - delta)
	var hour := shift_hour()
	if hour != last_announced_hour:
		last_announced_hour = hour
		hour_flash = 2.4
		if is_instance_valid(hour_banner) and hour != 6:
			hour_banner.text = "%02d:00  ·  la noche avanza" % hour
	if is_instance_valid(hour_banner):
		hour_banner.visible = hour_flash > 0.0 and location == "store"
		hour_banner.modulate.a = clampf(hour_flash / 0.45, 0.0, 1.0)

func begin_shift() -> void:
	if is_instance_valid(panel): panel.queue_free()
	set_location("store")
	revenue = 0
	expenses = 0
	active = true
	elapsed = 0
	last_announced_hour = SHIFT_START_HOUR
	hour_flash = 0
	if is_instance_valid(hour_banner): hour_banner.visible = false
	sold = 0
	browsing = 0
	transaction_open = false
	paused = false
	joystick.reset()
	player.position = CASHIER
	events.reset_shift()
	security.reset()
	crowd.reset()
	customer_state = 0
	customer.position = Vector2(320,340)
	message.text = "Espera al cliente y acércate a la caja."

func _physics_process(delta: float) -> void:
	if not active: return
	if location == "store":
		elapsed += delta
		advance_shift_clock(delta)
		events.tick(delta)
		crowd.tick(delta)
		security.tick(delta)
	var axis := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if touch_vector.length() > 0.1: axis = touch_vector
	var before := player.position
	player.velocity = player.velocity.move_toward(axis.limit_length()*(145 if Input.is_physical_key_pressed(KEY_SHIFT) else 90)*(0 if security.hiding else 1),720*delta)
	player.move_and_slide()
	player.position = player.position.clamp(Vector2(46,104),Vector2(594,272)) if location == "store" else (player.position.clamp(Vector2(30,195),Vector2(610,223)) if location == "city" else player.position.clamp(Vector2(40,158),Vector2(600,320)))
	Motion.animate(actor,player.position-before,player.velocity.length())
	update_hint()
	if location == "city":
		hud.text = "06:15  ·  BARRIO DEL FARO     $%d     Próxima noche %d" % [money,night]
		return
	if location in ["cafe","hardware","atelier"]:
		hud.text = "%s · $%d" % [{"cafe":"CAFÉ DEL FARO","hardware":"FERRETERÍA DEL FARO","atelier":"ATELIER · HILO Y SOMBRA"}[location],money]
		return
	var hour := shift_hour()
	hud.text = "NOCHE %d   %02d:00   $%d   Neveras %d · Estantes %d" % [night,hour,money,cold_stock(),shelf_stock()]
	if hour_flash>0: hud.add_theme_color_override("font_color",Color("ffdf9e"))
	else: hud.remove_theme_color_override("font_color")
	if elapsed >= SHIFT_SECONDS: finish()

func interact() -> void:
	if not active: return
	if location == "city":
		city_interact()
		return
	if location in ["cafe","hardware","atelier"]:
		interior_interact()
		return
	if security.interact(): return
	if crowd.intervene(): return
	if events.interact(): return
	if player.position.distance_to(CASHIER) > 28:
		message.text = "Acércate a la caja para atender."
		return
	checkout_person = crowd.first()
	if checkout_person.is_empty():
		message.text = "Espera a que llegue el primero de la fila."
		return
	active = false
	transaction_open = true
	joystick.reset()
	payment_method = "card"
	soundscape.play("scan")
	commerce.checkout()

func complete_sale() -> void:
	if not transaction_open or checkout_person.is_empty() or payment_method not in ["card","cash"]: return
	transaction_open = false
	var products := checkout_items()
	var count: int = products.size()
	if count<=0:
		crowd.leave(checkout_person)
		checkout_person = {}
		panel.queue_free()
		active = true
		message.text = "Sin existencias: el cliente se marcha sin pagar."
		return
	soundscape.play("register")
	for product in products: zone_stock[product_zone(product)] -= 1
	var total := count*progression.sale_price()
	money += total
	revenue += total
	if count>0: sold += 1
	crowd.leave(checkout_person)
	checkout_person = {}
	panel.queue_free()
	active = true
	message.text = ("Cobrado $%d · %s" % [total,"Tarjeta" if payment_method=="card" else "Efectivo · cambio $%d" % (maxi(10,int(ceil(total/10.0))*10)-total)]) if count>0 else "Sin existencias. Repón las neveras."

func finish() -> void:
	if not active or location != "store": return
	active = false
	joystick.reset()
	night += 1
	cafe_used = false
	var saved := SaveStore.write_game(money,night,progression.owned,stock,"city",zone_stock)
	show_panel("TURNO CERRADO · 06:00\n%d ventas · Ingresos $%d · Reposición $%d\nPérdidas en mercancía $%d · Saldo $%d\n%s\nLa ciudad despierta. Puedes salir." % [sold,revenue,expenses,events.losses,money,"Progreso guardado" if saved else "Error de guardado"],"Salir a la ciudad",enter_city)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_B: security.toggle_door()
		if event.keycode==KEY_P: security.call_police()
		if event.keycode==KEY_H: security.hide_player()
		if event.keycode==KEY_M: open_map()
		if event.keycode==KEY_F2: open_styles()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R: events.restock()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E: interact()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		pause_shift()

func pause_shift() -> void:
	if not active: return
	active = false
	paused = true
	joystick.reset()
	show_panel("PAUSA\nTu partida está detenida.", "Reanudar", resume_shift)
	add_panel_button("Diseño de botones e iconos · F2",open_styles)
	add_panel_button("Activar sonido" if events.muted else "Silenciar música y efectos",toggle_audio)
	add_audio_slider("Música",true)
	add_audio_slider("Efectos",false)

func add_audio_slider(title: String, music: bool) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title+" · %d %%" % int((events.music_volume if music else events.effects_volume)*100)
	label.custom_minimum_size.x = 150
	row.add_child(label)
	var slider := HSlider.new()
	slider.max_value = 200
	slider.tooltip_text = "Volumen: 0–200 %"
	slider.value = (events.music_volume if music else events.effects_volume)*100
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 26
	slider.value_changed.connect(func(value: float):
		label.text = title+" · %d %%" % int(value)
		if music: events.music_volume = value/100.0
		else: events.effects_volume = value/100.0)
	row.add_child(slider)
	panel.get_child(0).add_child(row)

func resume_shift() -> void:
	if not paused: return
	events.save_audio_settings()
	paused = false
	panel.queue_free()
	joystick.reset()
	active = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(joystick):
		joystick.reset()
		pause_shift()


func style_control(control: Control) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("182638")
	box.border_color = Color("527d82")
	box.set_border_width_all(1)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	if control is Button:
		control.add_theme_stylebox_override("normal",box)
		var hover := box.duplicate()
		hover.bg_color = Color("315058")
		control.add_theme_stylebox_override("hover",hover)
		control.add_theme_stylebox_override("pressed",hover)
		control.add_theme_font_size_override("font_size",12)
		control.add_theme_color_override("font_color",Color("f2ddbc"))
		UIStyles.apply(control)
	else:
		control.add_theme_stylebox_override("panel",box)

func set_location(value: String) -> void:
	if is_instance_valid(soundscape): soundscape.play("door-soft")
	location = value
	if is_instance_valid(atelier_sign): atelier_sign.visible = value=="city"
	if is_instance_valid(map_button): map_button.visible = value=="city"
	var interior := value in ["cafe","hardware","atelier"]
	actor.scale = Vector2.ONE * (1.6 if interior else 1.0)
	actor.position.y = -20 * actor.scale.y
	player.velocity = Vector2.ZERO
	var store := value == "store"
	background.texture = load("res://assets/" + {"store":"store-modern","city":"city","cafe":"cafe","hardware":"hardware","atelier":"atelier"}[value] + ".png")
	for body in store_bodies: body.collision_layer = 1 if store else 0
	for body in city_bodies: body.collision_layer = 1 if value=="city" else 0
	for body in interior_bodies: body.collision_layer = 1 if value in ["cafe","hardware","atelier"] else 0
	for prop in foreground_props: prop.visible = store
	customer.visible = false
	for p in crowd.people: p.node.visible = store
	events.visible = store
	for b in shift_buttons: b.visible = store
	if is_instance_valid(hour_banner): hour_banner.visible = store and hour_flash > 0.0

func enter_city() -> void:
	if is_instance_valid(panel): panel.queue_free()
	set_location("city")
	if street==1: background.texture = load("res://assets/modistas.png")
	update_street_geometry()
	active = true
	paused = false
	joystick.reset()
	player.position = Vector2(162,210)
	message.text = "Ferretería: mejoras · Cafetería: descanso · Tienda: volver."
	update_hint()

func update_hint() -> void:
	restock_button.visible = location == "store" and (player.position.y<116 or events.shelf_near(player.position)>=0)
	if location == "city":
		var x := player.position.x
		if street==1 and x>=78:
			hint.text = "E · Atelier: cabello y ropa" if absf(x-326)<35 else "Calle Modistas · Atelier en el centro"
			return
		if x<78:
			hint.text = "E · Cambiar de calle"
			return
		hint.text = "E · Volver a la tienda" if absf(x-162)<40 else ("E · Entrar a ferretería" if absf(x-367)<45 else ("E · Cafetería" if absf(x-530)<40 else "Pasea por el barrio"))
	elif location in ["cafe","hardware","atelier"]:
		hint.text = "E · Salir a la calle" if player.position.y>285 else ("E · Hablar en el mostrador" if player.position.y<175 else "Acércate al mostrador o explora el local")
	else:
		hint.text = "E · Abrir / cerrar nevera · R reponer" if player.position.y<116 else ("E · Atender en caja" if player.position.distance_to(CASHIER)<28 else ("E · Examinar productos y precios" if events.shelf_near(player.position)>=0 else "Explora los pasillos"))

func city_interact() -> void:
	var x := player.position.x
	if x<78:
		street = 1-street
		background.texture = load("res://assets/modistas.png" if street==1 else "res://assets/city.png")
		update_street_geometry()
		player.position.y = 210
		player.position.x = 100
		atelier_sign.text = "← VOLVER · ATELIER →" if street==1 else "← CALLE MODISTAS"
		message.text = "Calle de las Modistas · Atelier en la puerta central" if street==1 else "Avenida del Faro"
	elif street==1:
		if absf(x-326)<35: enter_interior("atelier")
		else: message.text = "Atelier: puerta central · Otros locales cerrados"
	elif absf(x-367)<45:
		enter_interior("hardware")
	elif absf(x-162)<40:
		active = false
		show_panel("VOLVER AL TRABAJO\nNoche %d · Stock %d · Saldo $%d\nLas mejoras compradas ya están instaladas." % [night,stock,money],"Comenzar siguiente turno",begin_shift)
		add_panel_button("Seguir paseando",close_city_panel)
	elif absf(x-530)<40:
		enter_interior("cafe")
	else:
		message.text = "Atelier al extremo izquierdo · Tienda · Ferretería · Café."

func rest_at_cafe() -> void:
	cafe_used = true
	close_city_panel()
	message.text = "El barista: «Anoche volvieron a fallar las luces del callejón»."

func show_upgrades() -> void:
	commerce.upgrades()

func add_panel_button(text: String, callback: Callable, disabled := false) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 40
	b.disabled = disabled
	style_control(b)
	b.pressed.connect(callback)
	panel.get_child(0).add_child(b)

func purchase_upgrade(id: String) -> void:
	if location != "hardware": return
	var result := progression.buy(id,money)
	if result.ok:
		money = result.balance
		if not SaveStore.write_game(money,night,progression.owned,stock,"city",zone_stock):
			message.text = "Mejora aplicada, pero no se pudo guardar."
		else:
			message.text = result.message
	else:
		message.text = result.message
	show_upgrades()

func close_city_panel() -> void:
	cafe_menu_open = false
	if is_instance_valid(panel): panel.queue_free()
	joystick.reset()
	active = true

func enter_interior(kind: String) -> void:
	set_location(kind)
	player.position = Vector2(320,305)
	joystick.reset()
	active = true
	message.text = "Bienvenido. Acércate al mostrador para conversar."
	update_hint()

func interior_interact() -> void:
	if player.position.y>285 and absf(player.position.x-320)<70:
		var destination: int = {"hardware":367,"cafe":530,"atelier":326}[location]
		enter_city()
		player.position = Vector2(destination,210)
		update_hint()
	elif player.position.y<175:
		if location=="atelier": wardrobe.open()
		elif location=="hardware": show_upgrades()
		else:
			cafe_menu_open = true
			commerce.cafe()
	else:
		message.text = "Mostrador al fondo · Salida por la alfombra de entrada."

func set_payment(method: String) -> void:
	if not transaction_open or method not in ["card","cash"]: return
	payment_method = method
	commerce.checkout()

func cancel_checkout() -> void:
	transaction_open = false
	checkout_person = {}
	close_city_panel()
	message.text = "Cobro pendiente. El cliente continúa en la fila."

func buy_cafe(index: int) -> void:
	if location != "cafe" or not cafe_menu_open or index<0 or index>2: return
	var prices := [3,5,7]
	var names := ["Espresso", "Café con leche", "Desayuno del Faro"]
	var price: int = prices[index]
	if money<price: return
	cafe_menu_open = false
	money -= price
	cafe_used = true
	var saved := SaveStore.write_game(money,night,progression.owned,stock,"city",zone_stock)
	if is_instance_valid(panel): panel.hide()
	show_panel("CAFÉ DEL FARO · PEDIDO SERVIDO\n%s · $%d\nSaldo restante: $%d\n%s" % [names[index],price,money,"Gracias por tu visita." if saved else "No se pudo guardar el pedido."],"Volver al local",close_city_panel)

func open_map() -> void:
	if active and location=="city": exploration.city_map()

func open_styles() -> void:
	if transaction_open or (not active and not paused): return
	paused = false
	exploration.styles()

func refresh_buttons(node: Node = null) -> void:
	if node==null: node = controls
	for child in node.get_children():
		if child is Button:
			UIStyles.apply(child)
			if child==map_button: child.icon = UIStyles.icon("map")
			elif child.text=="Interactuar · E": child.icon = UIStyles.icon("hand")
		refresh_buttons(child)

func toggle_audio() -> void:
	events.muted = not events.muted
	resume_shift()

func product_zone(product: String) -> int:
	for i in range(3):
		if product in exploration.PRODUCTS[i]: return i
	return ["Agua Bruma","Jugo Aurora","Leche Alba","Yogur Nieve","Queso Fresco"].find(product)+3

func checkout_items() -> Array[String]:
	var available := zone_stock.duplicate()
	var result: Array[String] = []
	for product in checkout_person.get("items",[]):
		var zone := product_zone(product)
		if zone>=0 and zone<8 and available[zone]>0:
			result.append(product)
			available[zone] -= 1
	return result

func update_street_geometry() -> void:
	var top: float = 187
	var bottom: float = 230
	city_bodies[0].position.y = top/2
	city_bodies[0].get_child(0).shape.size.y = top
	city_bodies[1].position.y = (bottom+360)/2
	city_bodies[1].get_child(0).shape.size.y = 360-bottom

func open_security_menu() -> void:
	if not active or location!="store": return
	active = false
	show_panel("SEGURIDAD
Entrada: %s · Patrulla: %s" % ["cerrada" if security.closed else "abierta",security.police_state],"Volver",close_city_panel)
	add_panel_button("Abrir entrada · B" if security.closed else "Cerrar entrada · B",func():
		close_city_panel()
		security.toggle_door())
	add_panel_button("Llamar a la policía · P",func():
		close_city_panel()
		security.call_police(),security.police>=0 or security.police_state!="idle")
	add_panel_button("Salir del escondite · H" if security.hiding else "Esconderse · H",func():
		close_city_panel()
		security.hide_player())

func cold_stock() -> int:
	return zone_stock.slice(3).reduce(func(a,b): return a+b,0)
func shelf_stock() -> int:
	return zone_stock.slice(0,3).reduce(func(a,b): return a+b,0)
