extends RefCounted

var game
var selected_upgrade := "storage"
const INK = Color("e7ede7")
const MUTED = Color("91aaa9")
const ACCENT = Color("8ed7be")
const PAPER = Color("f0e4ce")
const COFFEE = Color("3e302a")

func setup(owner_game) -> void:
	game = owner_game

func box(color: Color, border: Color = Color("385458")) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(3)
	return result

func window(title: String, subtitle: String, warm := false) -> Control:
	if is_instance_valid(game.panel):
		game.panel.hide()
		game.panel.queue_free()
	game.active = false
	game.joystick.reset()
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.04,0.07,0.82)
	shade.size = Vector2(640,360)
	game.controls.add_child(shade)
	game.panel = PanelContainer.new()
	game.panel.position = Vector2(16,16)
	game.panel.size = Vector2(608,328)
	game.panel.add_theme_stylebox_override("panel",box(PAPER if warm else Color("12242b")))
	game.panel.tree_exited.connect(func():
		if is_instance_valid(shade): shade.queue_free())
	var page := Control.new()
	page.custom_minimum_size = Vector2(606,326)
	game.panel.add_child(page)
	game.controls.add_child(game.panel)
	label(page,title,Vector2(18,12),22,COFFEE if warm else INK)
	label(page,subtitle,Vector2(19,42),10,Color("806951") if warm else MUTED)
	line(page,Vector2(18,66),Vector2(572,1),Color("c8b79a") if warm else Color("385458"))
	return page

func label(parent: Node, text: String, pos: Vector2, font_size := 12, color := INK, width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size",maxi(10,font_size))
	l.add_theme_font_override("font",game.UIStyles.TITLE if font_size>=18 else game.UIStyles.BODY)
	l.add_theme_color_override("font_color",color)
	if width>0:
		l.size.x = width
		l.clip_text = true
	parent.add_child(l)
	return l

func line(parent: Node, pos: Vector2, extent: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = extent
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary := false, disabled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.disabled = disabled
	b.add_theme_font_size_override("font_size",12)
	b.add_theme_stylebox_override("normal",box(Color("84cbb4") if primary else Color("243b41")))
	b.add_theme_stylebox_override("hover",box(Color("a2e3ce") if primary else Color("36545a")))
	b.add_theme_stylebox_override("pressed",box(Color("75b9a5")))
	b.add_theme_stylebox_override("disabled",box(Color("293839")))
	b.add_theme_color_override("font_color",Color("12242b") if primary else INK)
	b.add_theme_color_override("font_disabled_color",MUTED)
	game.UIStyles.apply(b,primary)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func checkout() -> void:
	var count: int = game.checkout_items().size()
	var unit: int = game.progression.sale_price()
	var total: int = count*unit
	var cash := maxi(10,int(ceil(total/10.0))*10)
	var page := window("CAJA 01", "TURNO DE MEDIANOCHE  /  TICKET %04d  /  NOCHE %d" % [game.sold+1,game.night])
	line(page,Vector2(354,78),Vector2(1,228),Color("385458"))
	label(page,"ARTÍCULO",Vector2(20,80),10,MUTED)
	label(page,"UD.",Vector2(230,80),10,MUTED)
	label(page,"PRECIO",Vector2(265,80),10,MUTED)
	label(page,"IMPORTE",Vector2(306,80),9,MUTED)
	var grouped := {}
	var products: Array = game.checkout_items()
	for i in range(count):
		var name: String = products[i] if i<products.size() else "Agua Bruma"
		grouped[name] = int(grouped.get(name,0))+1
	var row := 0
	for name in grouped:
		var y := 109+row*40
		line(page,Vector2(19,y-3),Vector2(324,35),Color("1c3239") if row%2==0 else Color("172b32"))
		label(page,name,Vector2(26,y+4),12,INK,196)
		label(page,str(grouped[name]),Vector2(235,y+4),12)
		label(page,"$%d" % unit,Vector2(269,y+4),12)
		label(page,"$%d" % (grouped[name]*unit),Vector2(312,y+4),12,ACCENT)
		row += 1
	label(page,"%d unidades · %d referencias" % [count,grouped.size()],Vector2(22,239),11,MUTED)
	label(page,"Venta sin impuestos en esta simulación.",Vector2(22,259),10,MUTED)
	button(page,"Volver a la fila",Rect2(20,281,155,32),game.cancel_checkout)
	label(page,"RESUMEN DEL COBRO",Vector2(372,80),11,ACCENT)
	var names := ["Importe bruto", "Descuentos", "Neto", "Impuestos (0%)"]
	var values := [total,0,total,0]
	for i in range(4):
		label(page,names[i],Vector2(372,102+i*18),11,MUTED)
		var v := label(page,"$%d" % values[i],Vector2(544,102+i*18),11,INK)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size.x = 38
	line(page,Vector2(372,179),Vector2(210,1),Color("385458"))
	label(page,"TOTAL",Vector2(372,185),14)
	label(page,"$%d" % total,Vector2(524,181),24,ACCENT)
	button(page,"Tarjeta",Rect2(372,215,100,32),game.set_payment.bind("card"),game.payment_method=="card")
	button(page,"Efectivo",Rect2(480,215,102,32),game.set_payment.bind("cash"),game.payment_method=="cash")
	label(page,("Recibido $%d  ·  Cambio $%d" % [cash,cash-total]) if game.payment_method=="cash" else "Terminal lista · Pago con tarjeta",Vector2(372,255),10,MUTED)
	button(page,"Cobrar $%d" % total,Rect2(372,281,210,32),game.complete_sale,true,count==0)
	if count==0: label(page,"Sin existencias para esta compra.",Vector2(24,117),12,Color("efad8d"))

func upgrades() -> void:
	var page := window("FERRETERÍA DEL FARO", "EQUIPAMIENTO PARA TU TIENDA  /  INSTALACIÓN INCLUIDA")
	label(page,"Saldo disponible: $%d" % game.money,Vector2(374,82),12,ACCENT)
	var ids := ["storage","register","security"]
	var short := ["ALMACENAMIENTO","TERMINAL DE COBRO","SEGURIDAD"]
	var i := 0
	for id in ids:
		var item: Dictionary = game.Progression.CATALOG[id]
		var owned: bool = game.progression.owned.has(id)
		button(page,short[i]+"\n"+("INSTALADA" if owned else "$%d · Ver detalles" % item.price),Rect2(20,82+i*63,322,55),select_upgrade.bind(id),selected_upgrade==id)
		i+=1
	var item: Dictionary = game.Progression.CATALOG[selected_upgrade]
	var owned: bool = game.progression.owned.has(selected_upgrade)
	var titles := {"storage":"Más espacio\npara mercancía", "register":"Terminal de\nfidelización", "security":"Prevención\nde pérdidas"}
	label(page,titles[selected_upgrade],Vector2(374,109),21)
	var desc := {"storage":"Capacidad de la tienda\n24 → 40 unidades\nCajas adicionales visibles.","register":"Precio por artículo\n$4 → $5\nNuevo terminal visible.","security":"Probabilidad de hurto\n23% → 10%\nCámaras disuasorias visibles."}
	label(page,desc[selected_upgrade],Vector2(374,170),12,MUTED)
	label(page,"Ya instalada" if owned else "Inversión única: $%d" % item.price,Vector2(374,235),12,ACCENT)
	label(page,"No requiere pagos recurrentes.",Vector2(22,278),10,MUTED)
	button(page,"Cerrar catálogo",Rect2(20,294,150,26),game.close_city_panel)
	button(page,"Instalada" if owned else ("Fondos insuficientes" if game.money<int(item.price) else "Instalar · $%d" % item.price),Rect2(374,281,210,32),game.purchase_upgrade.bind(selected_upgrade),true,owned or game.money<int(item.price))

func select_upgrade(id: String) -> void:
	selected_upgrade = id
	upgrades()

func cafe() -> void:
	var page := window("Café del Faro", "CAFÉ RECIÉN HECHO  ·  PANADERÍA DE LA MAÑANA",true)
	label(page,"LA CARTA",Vector2(22,81),11,COFFEE)
	var menu := [["Espresso", "Corto, intenso y recién molido.",3],["Café con leche", "Una pausa cálida al terminar el turno.",5],["Desayuno del Faro", "Café y pan tostado de la casa.",7]]
	for i in range(menu.size()):
		var y := 106+i*52
		label(page,menu[i][0],Vector2(24,y),16,COFFEE)
		label(page,menu[i][1],Vector2(24,y+22),10,Color("806951"))
		button(page,"$%d · Pedir" % menu[i][2],Rect2(267,y,93,34),game.buy_cafe.bind(i),false,game.money<int(menu[i][2]))
	line(page,Vector2(378,82),Vector2(1,225),Color("c8b79a"))
	label(page,"TU DESCANSO",Vector2(397,84),11,Color("806951"))
	label(page,"Bienvenido\nde vuelta.",Vector2(397,109),24,COFFEE)
	label(page,"Saldo: $%d" % game.money,Vector2(397,177),14,COFFEE)
	label(page,"El barista siempre tiene\nalgo que contar sobre\nla noche en el barrio.",Vector2(397,205),11,Color("806951"))
	button(page,"Conversar",Rect2(397,275,184,38),game.rest_at_cafe,true)
	button(page,"Volver al local",Rect2(22,280,160,33),game.close_city_panel)

