extends RefCounted

var game
const ZONES = ["Snacks", "Alimentos", "Hogar"]
const PRODUCTS = [["Papas Crujín","Galletas Luna","Chocolate Eclipse"],["Fideos Nube","Cereal Amanecer","Pan Trigal"],["Jabón Claro","Pañuelos Niebla","Limpiador Brisa"]]

func setup(owner_game) -> void:
	game = owner_game

func shelf(index: int) -> void:
	var ui = game.commerce
	var page: Control = ui.window("ESTANTE · "+ZONES[index].to_upper(),"VISTA FRONTAL / PRODUCTOS Y PRECIOS")
	var view := preload("res://scripts/product_shelf_view.gd").new()
	view.game = game
	view.zone = index
	view.position = Vector2(20,80)
	view.size = Vector2(566,188)
	page.add_child(view)
	ui.button(page,"Volver al pasillo",Rect2(396,279,190,34),game.close_city_panel,true)

func city_map() -> void:
	if game.location != "city": return
	var ui = game.commerce
	var page: Control = ui.window("MAPA DEL BARRIO", "UBICACIÓN ACTUAL / EL FARO")
	var map := preload("res://scripts/live_district_map.gd").new()
	map.game = game
	map.position = Vector2(20,76)
	map.size = Vector2(566,194)
	page.add_child(map)
	ui.label(page,"● Tú · " + ("Calle Modistas" if game.street==1 else "Avenida del Faro"),Vector2(22,284),12,ui.ACCENT)
	ui.button(page,"Cerrar mapa",Rect2(420,280,162,33),game.close_city_panel)

func map_place(index: int) -> void:
	if index<0: return
	game.close_city_panel()
	game.message.text = ["Supermercado: edificio más ancho de Avenida del Faro.","Ferretería: entre el supermercado y el café.","Cafetería: extremo este de Avenida del Faro.","Atelier: Calle Modistas, al oeste de Avenida del Faro."][index]

func fridge(index: int) -> void:
	var ui = game.commerce
	var page: Control = ui.window("NEVERA", "VISTA FRONTAL / PRODUCTOS REFRIGERADOS")
	var view := preload("res://scripts/product_shelf_view.gd").new()
	view.game = game
	view.zone = index+3
	view.position = Vector2(20,80)
	view.size = Vector2(566,188)
	page.add_child(view)
	ui.button(page,"Volver al pasillo",Rect2(396,279,190,34),game.close_city_panel,true)

func purchase_stock() -> void:
	var ui = game.commerce
	var page: Control = ui.window("PEDIDO DE MERCANCÍA", "ELIGE PRODUCTOS / COSTE POR UNIDAD: $2")
	game.panel.set_meta("back_closes",false)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20,76)
	scroll.size = Vector2(566,188)
	page.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.custom_minimum_size.x = 546
	rows.add_theme_constant_override("separation",8)
	scroll.add_child(rows)
	var quantities := {}
	for zone in range(8):
		var heading := Label.new()
		heading.text = ("ESTANTES · "+ZONES[zone]) if zone<3 else "NEVERA · "+str(zone-2)
		game.UIStyles.apply_label(heading,12)
		rows.add_child(heading)
		for product in game.zone_products(zone):
			var row := HBoxContainer.new()
			rows.add_child(row)
			var name_label := Label.new()
			name_label.text = "%s · Stock: %d" % [product,game.product_quantity(product)]
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			game.UIStyles.apply_label(name_label,12)
			row.add_child(name_label)
			var count := SpinBox.new()
			count.min_value = 0
			count.max_value = maxi(0,game.progression.capacity()-game.stock)
			count.step = 1
			count.custom_minimum_size.x = 100
			row.add_child(count)
			quantities[product] = count
	var total_label = ui.label(page,"Total: $0 · Saldo: $%d" % game.money,Vector2(22,270),12)
	var buy = ui.button(page,"Comprar y salir",Rect2(398,290,188,28),func():
		var units := 0
		for product in quantities: units += int(quantities[product].value)
		if units*2>game.money or units+game.stock>game.progression.capacity(): return
		game.sync_products()
		for product in quantities:
			var amount := int(quantities[product].value)
			game.product_counts[product] += amount
			game.zone_stock[game.product_zone(product)] += amount
		game.money -= units*2
		game.expenses += units*2
		game.SaveStore.write_game(game.money,game.night,game.progression.owned,game.stock,"city",game.zone_stock,game.product_counts)
		game.enter_city(),true)
	var refresh := func(_value):
		var units := 0
		for product in quantities: units += int(quantities[product].value)
		total_label.text = "Total: $%d · Saldo: $%d · %d/%d uds." % [units*2,game.money,game.stock+units,game.progression.capacity()]
		buy.disabled = units*2>game.money or units+game.stock>game.progression.capacity()
	for product in quantities: quantities[product].value_changed.connect(refresh)
