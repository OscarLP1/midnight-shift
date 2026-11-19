extends Node2D

const UIStyles = preload("res://scripts/ui_styles.gd")
const ExplorationUI = preload("res://scripts/exploration_ui.gd")
var exploration := ExplorationUI.new()
const MenuUI = preload("res://scripts/menu_ui.gd")
var menus := MenuUI.new()
var map_button: Button
var security_panel: PanelContainer
var hud_bands: Control
var street := 0
const District = preload("res://scripts/district_layout.gd")
var world_camera: Camera2D
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
var dry_night_material: ShaderMaterial
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
	UIStyles.selected = 0
	y_sort_enabled = true
	world_camera = Camera2D.new()
	world_camera.position = Vector2(320,204)
	add_child(world_camera)
	background = Sprite2D.new()
	background.texture = load("res://assets/store-modern.png")
	dry_night_material = ShaderMaterial.new()
	dry_night_material.shader = preload("res://scripts/dry_night.gdshader")
	dry_night_material.set_shader_parameter("dry_exterior",preload("res://assets/art_direction/store-night-sidewalks-source.png"))
	background.material = dry_night_material
	background.centered = false
	background.z_index = -10
	add_child(background)
	var prop_rects := [Rect2(157,121,72,59),Rect2(315,121,73,59),Rect2(472,121,73,59),Rect2(69,195,96,61)]
	for i in range(prop_rects.size()):
		var prop := Sprite2D.new()
		var rect: Rect2 = prop_rects[i]
		prop.texture = load("res://assets/store-prop-%d.png" % i)
		prop.centered = false
		if i==3:
			var cutout := ShaderMaterial.new()
			cutout.shader = preload("res://scripts/counter_cutout.gdshader")
			prop.material = cutout
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
		wall.set_meta("base_rect",rect)
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
	menus.setup(self)
	exploration.setup(self)
	wardrobe.setup(self)
	controls = CanvasLayer.new()
	add_child(controls)
	hud_bands = Control.new()
	hud_bands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_child(hud_bands)
	for rect in [Rect2(0,0,640,34),Rect2(0,360,640,48)]:
		var band := ColorRect.new()
		band.position = rect.position
		band.size = rect.size
		band.color = Color(0.045,0.075,0.11,0.94)
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud_bands.add_child(band)
	joystick = TouchStick.new()
	joystick.changed.connect(func(value: Vector2): touch_vector = value)
	controls.add_child(joystick)
	joystick.visible = touch_controls
	hud = Label.new()
	hud.position = Vector2(16,9)
	hud.size = Vector2(442,20)
	hud.clip_text = true
	UIStyles.apply_label(hud,UIStyles.FONT_BODY)
	controls.add_child(hud)
	atelier_sign = Label.new()
	atelier_sign.text = "← CALLE MODISTAS"
	atelier_sign.position = Vector2(14,107)
	UIStyles.apply_label(atelier_sign,UIStyles.FONT_CAPTION)
	atelier_sign.add_theme_color_override("font_color",Color("eac6be"))
	atelier_sign.visible = false
	add_child(atelier_sign)
	hour_banner = Label.new()
	hour_banner.position = Vector2(200,86)
	hour_banner.size = Vector2(240,36)
	hour_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_label(hour_banner,UIStyles.FONT_TITLE)
	hour_banner.add_theme_color_override("font_color",Color("ffdf9e"))
	hour_banner.visible = false
	controls.add_child(hour_banner)
	message = Label.new()
	message.position = Vector2(14,363)
	message.size = Vector2(485,18)
	message.clip_text = true
	UIStyles.apply_label(message,UIStyles.FONT_BODY)
	controls.add_child(message)
	hint = Label.new()
	hint.position = Vector2(14,384)
	hint.size = Vector2(485,20)
	hint.clip_text = true
	UIStyles.apply_label(hint,UIStyles.FONT_BODY)
	hint.add_theme_color_override("font_color",Color("f1d29b"))
	controls.add_child(hint)
	button("Cerrar turno",Vector2(508,5),finish)
	button("Pausa",Vector2(602,2),pause_shift)
	button("Reponer · R",Vector2(510,379),events.restock)
	button("Seguridad",Vector2(466,2),open_security_menu)
	button("Mapa · M",Vector2(510,379),open_map)
	menus.main_menu()

func make_actor(asset: String, cell_size := Vector2i(32,48)) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var profile: Dictionary = Motion.PROFILES.get(asset,{})
	var walk_asset: String = profile.get("walk",asset)
	var texture: Texture2D = load("res://assets/"+walk_asset+".png")
	var columns := int(texture.get_width()/cell_size.x)
	add_actor_frames(frames,texture,cell_size,columns,"")
	sprite.set_meta("asset",asset)
	sprite.set_meta("walk_columns",columns)
	sprite.set_meta("walk_stride",32.0 if asset=="stray-dog" else (48.0 if asset.begins_with("monster-walk-") else profile.get("walk_stride",40.0)))
	sprite.set_meta("rest_frame",1 if columns==8 else (1 if asset in ["burglar","police-officer","customer-woman","customer-senior","customer-courier","stray-dog"] or asset.begins_with("monster-walk-") else 0))
	if profile.has("run"):
		var run_texture: Texture2D = load("res://assets/"+profile.run+".png")
		var run_columns := int(run_texture.get_width()/cell_size.x)
		add_actor_frames(frames,run_texture,cell_size,run_columns,"run_")
		sprite.set_meta("run_columns",run_columns)
		sprite.set_meta("run_threshold",profile.run_threshold)
		sprite.set_meta("run_stride",profile.run_stride)
	sprite.sprite_frames = frames
	sprite.position.y = -20
	Motion.face(sprite,0)
	return sprite

func add_actor_frames(frames: SpriteFrames, texture: Texture2D, cell_size: Vector2i, columns: int, prefix: String) -> void:
	for direction in range(4):
		var key := prefix+str(direction)
		frames.add_animation(key)
		frames.set_animation_speed(key,8)
		for frame in range(columns):
			var region := AtlasTexture.new()
			region.atlas = texture
			region.region = Rect2(frame*cell_size.x,direction*cell_size.y,cell_size.x,cell_size.y)
			frames.add_frame(key,region)

func button(text: String, pos: Vector2, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	if touch_controls and b.position.y>360: b.position.y = 370
	b.custom_minimum_size = Vector2(64,34 if touch_controls else 23)
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
	b.set_meta("compact_hud",true)
	UIStyles.apply(b)
	if text in ["Pausa","Seguridad"]:
		var kind := "pause" if text=="Pausa" else "badge"
		b.set_meta("hud_icon",kind)
		b.text = ""
		b.icon = UIStyles.icon(kind)
		b.tooltip_text = "Pausa · Esc" if kind=="pause" else "Seguridad · La tienda sigue activa"
		b.custom_minimum_size = Vector2(30,30)
		b.size = Vector2(30,30)
		b.flat = true
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width",20 if text in ["Pausa","Seguridad"] else 14)
	controls.add_child(b)

func show_panel(text: String, action: String, callback: Callable, continuation := false) -> void:
	close_security_menu()
	if is_instance_valid(panel): panel.queue_free()
	joystick.reset()
	panel = preload("res://scripts/centered_panel.gd").new()
	panel.custom_minimum_size = Vector2(420,190)
	style_control(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var label := Label.new()
	UIStyles.apply_label(label,UIStyles.FONT_BODY)
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
	set_game_controls_visible(true)
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
	player.position = player.position.clamp(Vector2(46,104),Vector2(594,272)) if location == "store" else (player.position.clamp(District.walk_min(street),District.WALK_MAX) if location == "city" else player.position.clamp(District.room_point(location,Vector2(40,158)),District.room_point(location,Vector2(600,320))))
	update_world_camera()
	Motion.animate(actor,player.position-before,player.velocity.length())
	update_hint()
	if location == "city":
		hud.text = "06:15  ·  BARRIO DEL FARO     $%d     Próxima noche %d" % [money,night]
		return
	if location in ["cafe","hardware","atelier"]:
		hud.text = "%s · $%d" % [{"cafe":"CAFÉ DEL FARO","hardware":"FERRETERÍA DEL FARO","atelier":"ATELIER · HILO Y SOMBRA"}[location],money]
		return
	var hour := shift_hour()
	hud.text = "N%d  ·  %02d:00    $%d    Neveras %d / Estantes %d" % [night,hour,money,cold_stock(),shelf_stock()]
	if hour_flash>0: hud.add_theme_color_override("font_color",Color("ffdf9e"))
	else: hud.remove_theme_color_override("font_color")
	if elapsed >= SHIFT_SECONDS: finish()

func interact() -> void:
	if not active: return
	if security.hiding:
		message.text = "Pulsa H para salir del escondite antes de atender."
		return
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
	payment_method = checkout_person.get("payment","card")
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R: events.restock()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E: interact()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if menus.commands_open:
			menus.back()
		elif is_instance_valid(security_panel):
			close_security_menu()
		else: pause_shift()

func pause_shift() -> void:
	if not active: return
	active = false
	paused = true
	joystick.reset()
	show_panel("PAUSA\nTu partida está detenida.", "Reanudar", resume_shift)
	add_panel_button("Comandos",menus.commands.bind(true))
	add_panel_button("Activar sonido" if events.muted else "Silenciar música y efectos",toggle_audio)
	add_audio_slider("Música",true)
	add_audio_slider("Efectos",false)

func add_audio_slider(title: String, music: bool) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title+" · %d %%" % int((events.music_volume if music else events.effects_volume)*100)
	label.custom_minimum_size.x = 150
	UIStyles.apply_label(label,UIStyles.FONT_BODY
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
		control.add_theme_color_override("font_color",Color("f2ddbc"))
		UIStyles.apply(control)
	else:
		control.add_theme_stylebox_override("panel",box)

func set_location(value: String) -> void:
	if is_instance_valid(soundscape): soundscape.play("door-soft")
	location = value
	if is_instance_valid(atelier_sign): atelier_sign.visible = false
	if is_instance_valid(map_button): map_button.visible = value=="city"
	actor.scale = Vector2.ONE*(1.6 if value in ["cafe","hardware","atelier"] else 1.0)
	actor.position.y = -20 * actor.scale.y
	player.velocity = Vector2.ZERO
	var store := value == "store"
	background.material = dry_night_material if store else null
	background.texture = load("res://assets/" + {"store":"store-modern","city":"city","cafe":"cafe","hardware":"hardware","atelier":"atelier"}[value] + ".png")
	background.position = District.origin_for(value)
	background.scale = Vector2.ONE*District.scale_for(value)
	if value=="city": update_street_geometry()
	for body in interior_bodies:
		var rect: Rect2 = body.get_meta("base_rect")
		body.position = District.room_point(value,rect.get_center())
		body.get_child(0).shape.size = rect.size*District.scale_for(value)
	update_world_camera()
	for body in store_bodies: body.collision_layer = 1 if store else 0
	for body in city_bodies: body.collision_layer = 1 if value=="city" else 0
	for body in interior_bodies: body.collision_layer = 1 if value in ["cafe","hardware","atelier"] else 0
	for prop in foreground_props: prop.visible = store
	customer.visible = false
	for p in crowd.people: p.node.visible = store
	events.visible = store or value=="city"
	for b in shift_buttons: b.visible = store
	if is_instance_valid(hour_banner): hour_banner.visible = store and hour_flash > 0.0

func enter_city() -> void:
	if is_instance_valid(panel): panel.queue_free()
	set_location("city")
	update_street_geometry()
	active = true
	paused = false
	joystick.reset()
	player.position = Vector2(District.DOORS.store,258)
	update_world_camera()
	message.text = "Ferretería: mejoras · Cafetería: descanso · Tienda: volver."
	update_hint()

func update_hint() -> void:
	restock_button.visible = location == "store" and (player.position.y<116 or events.shelf_near(player.position)>=0)
	if location == "city":
		var x := player.position.x
		if (street==0 and x<60) or (street==1 and x>580):
			hint.text = "E · " + ("Calle Modistas" if street==0 else "Avenida del Faro")
			return
		var nearby := nearby_shop()
		hint.text = "E · " + {"store":"Volver a la tienda","hardware":"Entrar a ferretería","cafe":"Entrar a cafetería","atelier":"Entrar al atelier"}.get(nearby,"Pasear · M abre el mapa")
	elif location in ["cafe","hardware","atelier"]:
		var local_pos := District.local_point(location,player.position)
		hint.text = "E · Salir a la calle" if local_pos.y>285 else ("E · Hablar en el mostrador" if local_pos.y<185 else "Acércate al mostrador o explora el local")
	else:
		if security.hiding:
			hint.text = "H · Salir del mostrador"
			return
		hint.text = "E · Abrir / cerrar nevera · R reponer" if player.position.y<116 else ("E · Atender en caja" if player.position.distance_to(CASHIER)<28 else ("E · Examinar productos y precios" if events.shelf_near(player.position)>=0 else "Explora los pasillos"))

func nearby_shop() -> String:
	for place in (["atelier"] if street==1 else ["store","hardware","cafe"]):
		if absf(player.position.x-District.DOORS[place])<36 and player.position.y<270: return place
	return ""

func city_interact() -> void:
	var x := player.position.x
	if (street==0 and x<60) or (street==1 and x>580):
		street = 1-street
		update_street_geometry()
		player.position = Vector2(564 if street==1 else 76,276)
		update_world_camera()
		message.text = "Calle Modistas" if street==1 else "Avenida del Faro"
		update_hint()
		return
	var place := nearby_shop()
	if place=="store":
		active = false
		show_panel("VOLVER AL TRABAJO\nNoche %d · Stock %d · Saldo $%d\nLas mejoras compradas ya están instaladas." % [night,stock,money],"Comenzar siguiente turno",begin_shift)
		add_panel_button("Seguir paseando",close_city_panel)
	elif not place.is_empty(): enter_interior(place)
	else: message.text = "Acércate a una puerta. M · Mapa del barrio."

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
	player.position = District.room_point(kind,Vector2(320,305))
	joystick.reset()
	active = true
	message.text = "Bienvenido. Acércate al mostrador para conversar."
	update_hint()

func interior_interact() -> void:
	var local_pos := District.local_point(location,player.position)
	if local_pos.y>285 and absf(local_pos.x-320)<70:
		var destination: float = District.DOORS[location]
		enter_city()
		player.position = Vector2(destination,258)
		update_world_camera()
		update_hint()
	elif local_pos.y<185:
		if location=="atelier": wardrobe.open()
		elif location=="hardware": show_upgrades()
		else:
			cafe_menu_open = true
			commerce.cafe()
	else:
		message.text = "Mostrador al fondo · Salida por la alfombra de entrada."

func set_payment(_method: String) -> void:
	# The customer keeps the same tender even if the checkout is reopened.
	if transaction_open: payment_method = checkout_person.get("payment","card")

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

func refresh_buttons(node: Node = null) -> void:
	if node==null: node = controls
	for child in node.get_children():
		if child is Button:
			UIStyles.apply(child)
			if child.has_meta("hud_icon"): child.icon = UIStyles.icon(child.get_meta("hud_icon"))
			elif child==map_button: child.icon = UIStyles.icon("map")
		refresh_buttons(child)

func toggle_audio() -> void:
	events.muted = not events.muted
	resume_shift()

func product_zone(product: String) -> int:
	for i in range(3):
		if product in exploration.PRODUCTS[i]: return i
	return ["Agua Bruma","Jugo Aurora","Leche Alba","Yogur Nieve","Queso Fresco"].find(product)+3

func checkout_items() -> Array[String]:
	return available_items(checkout_person)

func available_items(person: Dictionary) -> Array[String]:
	var available := zone_stock.duplicate()
	var result: Array[String] = []
	for product in person.get("items",[]):
		var zone := product_zone(product)
		if zone>=0 and zone<8 and available[zone]>0:
			result.append(product)
			available[zone] -= 1
	return result

func update_street_geometry() -> void:
	background.texture = load(District.street_texture(street))
	background.position = Vector2.ZERO
	background.scale = District.STREET_SIZE / background.texture.get_size()
	var rects := [Rect2(0,0,640,245 if street==1 else 237),Rect2(0,290,640,70),Rect2(0,0,16,360),Rect2(624,0,16,360)]
	for i in range(city_bodies.size()):
		city_bodies[i].position = rects[i].get_center()
		city_bodies[i].get_child(0).shape.size = rects[i].size

func update_world_camera() -> void:
	if not is_instance_valid(world_camera): return
	world_camera.position = Vector2(320,204)
	world_camera.reset_smoothing()

func open_security_menu() -> void:
	if not active or location!="store": return
	if is_instance_valid(security_panel):
		close_security_menu()
		return
	security_panel = preload("res://scripts/security_controls.gd").new()
	security_panel.setup(self)
	controls.add_child(security_panel)

func close_security_menu() -> void:
	if is_instance_valid(security_panel):
		security_panel.hide()
		security_panel.queue_free()
	security_panel = null

func cold_stock() -> int:
	return zone_stock.slice(3).reduce(func(a,b): return a+b,0)
func shelf_stock() -> int:
	return zone_stock.slice(0,3).reduce(func(a,b): return a+b,0)

func _process(_delta: float) -> void:
	if is_instance_valid(security_panel) and (not active or location!="store"): close_security_menu()
	if active: return
	if is_instance_valid(actor): actor.pause()
	for person in crowd.people: person.sprite.pause()
	if is_instance_valid(security):
		if is_instance_valid(security.officer): security.officer.pause()
		if is_instance_valid(security.dog_sprite): security.dog_sprite.pause()

func _unhandled_input(event: InputEvent) -> void:
	if not active or not touch_controls: return
	if event is InputEventScreenTouch and event.pressed:
		if joystick.get_global_rect().has_point(event.position): return
		if (get_canvas_transform().affine_inverse()*event.position).distance_to(player.position)<=55:
			interact()
			get_viewport().set_input_as_handled()

func set_game_controls_visible(value: bool) -> void:
	for child in controls.get_children():
		if child is Button: child.visible = value
	joystick.visible = value and touch_controls
	hud_bands.visible = value
	hud.visible = value
	hint.visible = value
	message.visible = value
	if value:
		map_button.visible = location=="city"
		update_hint()
