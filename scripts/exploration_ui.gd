extends RefCounted

var game
const ZONES = ["Snacks", "Alimentos", "Hogar"]
const PRODUCTS = [["Papas Crujín","Galletas Luna","Chocolate Eclipse"],["Fideos Nube","Cereal Amanecer","Pan Trigal"],["Jabón Claro","Pañuelos Niebla","Limpiador Brisa"]]

func setup(owner_game) -> void:
	game = owner_game

func shelf(index: int) -> void:
	var ui = game.commerce
	var page: Control = ui.window("ESTANTE · " + ZONES[index].to_upper(),"VISTA FRONTAL  /  EXAMINA LOS ENVASES Y SUS PRECIOS")
	var picture := TextureRect.new()
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/store-prop-%d.png" % index)
	texture.region = Rect2(2,8,68,48)
	picture.texture = texture
	picture.position = Vector2(20,85)
	picture.size = Vector2(320,190)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	page.add_child(picture)
	ui.label(page,"PRECIO POR UNIDAD",Vector2(365,83),11,ui.MUTED)
	for i in range(3):
		var y := 111+i*49
		ui.label(page,PRODUCTS[index][i],Vector2(366,y),14)
		ui.label(page,"$%d" % game.progression.sale_price(),Vector2(366,y+19),17,ui.ACCENT)
	ui.label(page,"Existencias de este estante: %d unidades" % game.zone_stock[index],Vector2(23,282),12,ui.MUTED)
	ui.button(page,"Volver al pasillo",Rect2(365,279,215,34),game.close_city_panel,true)

func city_map() -> void:
	if game.location != "city": return
	var ui = game.commerce
	var page: Control = ui.window("MAPA DEL BARRIO", "EL FARO  /  NEGOCIOS ABIERTOS Y FUTURAS ZONAS")
	ui.line(page,Vector2(20,82),Vector2(566,175),Color("1c333b"))
	ui.line(page,Vector2(24,158),Vector2(558,22),Color("547077"))
	ui.line(page,Vector2(305,85),Vector2(18,168),Color("547077"))
	ui.label(page,"AVENIDA DEL FARO",Vector2(346,160),10,Color("e2efdf"))
	for i in range(3):
		var x := 35+i*185
		ui.button(page,["Tienda","Ferretería","Cafetería"][i],Rect2(x,103,160,37),map_place.bind(i),true)
	ui.button(page,"Atelier · Calle Modistas",Rect2(35,200,175,44),map_place.bind(3),true)
	var future := [["Parque",220],["Callejón",405]]
	for place in future:
		ui.button(page,place[0]+"\nPróximamente",Rect2(place[1],200,160,44),func(): pass,false,true)
	var near := 3 if game.player.position.x<78 else (0 if game.player.position.x<260 else (1 if game.player.position.x<450 else 2))
	ui.label(page,("● Tú · Calle Modistas" if game.street==1 else "● Tú · junto a " + ["la tienda","la ferretería","la cafetería","el atelier"][near]),Vector2(25,265),13,ui.ACCENT)
	ui.button(page,"Cerrar mapa",Rect2(420,280,162,33),game.close_city_panel)

func map_place(index: int) -> void:
	game.close_city_panel()
	game.message.text = ["Tienda: puerta izquierda. Pulsa E para volver al turno.","Ferretería: puerta central. E para entrar.","Cafetería: puerta derecha. E para entrar.","Atelier: ve al extremo izquierdo y pulsa E para ir a Calle Modistas; busca la puerta central."][index]

func styles() -> void:
	var ui = game.commerce
	var page: Control = ui.window("ELIGE EL ESTILO DE CONTROLES", "TRES PROPUESTAS  /  PUEDES CAMBIARLAS SIN REINICIAR")
	for i in range(3):
		var x := 20+i*194
		ui.label(page,["A · NOCTURNO","B · PIXEL ÁMBAR","C · PAPEL"][i],Vector2(x,87),16)
		for j in range(3):
			var b: Button = ui.button(page,["Interactuar","Mapa","Productos"][j],Rect2(x,119+j*42,176,34),func(): pass,j==0)
			game.UIStyles.apply(b,j==0,i)
			b.icon = game.UIStyles.icon(["hand","map","bag"][j],i)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width",18)
		ui.button(page,"Usar " + ["A","B","C"][i],Rect2(x,256,176,34),choose_style.bind(i),game.UIStyles.selected==i)
	ui.button(page,"Volver al juego",Rect2(420,294,176,27),game.close_city_panel)

func choose_style(index: int) -> void:
	game.UIStyles.selected = index
	var settings := ConfigFile.new()
	settings.set_value("interface","style",index)
	settings.save("user://interface.cfg")
	game.refresh_buttons()
	styles()
