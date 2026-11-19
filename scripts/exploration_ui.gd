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
	var page: Control = ui.window("MAPA DEL BARRIO", "DOS CALLES / NEGOCIOS DEL BARRIO")
	ui.label(page,"OESTE · CALLE MODISTAS",Vector2(22,76),11,ui.MUTED)
	ui.label(page,"ESTE · AVENIDA DEL FARO",Vector2(22,179),11,ui.MUTED)
	var scale := 564.0/640.0
	for data in [[20,85,"Viviendas",-1],[110,100,"Lavandería",-1],[230,190,"Atelier",3],[440,180,"Muebles",-1]]:
		var place_button: Button = ui.button(page,data[2]+("\nPróximamente" if data[3]<0 else ""),Rect2(22+data[0]*scale,98,data[1]*scale,34),map_place.bind(data[3]),data[3]>=0,data[3]<0)
		place_button.clip_text = true
		place_button.size = Vector2(data[1]*scale,34)
	for data in [[20,370,"Supermercado",0],[400,100,"Ferretería",1],[510,110,"Café",2]]:
		ui.button(page,data[2],Rect2(22+data[0]*scale,201,data[1]*scale,34),map_place.bind(data[3]),true)
	for y in [142,245]: ui.line(page,Vector2(22,y),Vector2(564,12),Color("354a59"))
	ui.label(page,"Salida este → avenida     /     ← Salida oeste a Modistas",Vector2(22,159),11,ui.MUTED)
	var dot := Vector2(22+game.player.position.x*scale,140 if game.street==1 else 243)
	ui.label(page,"●",dot,12,ui.ACCENT)
	ui.label(page,"Tú · "+("Calle Modistas" if game.street==1 else "Avenida del Faro"),Vector2(22,280),12,ui.ACCENT)
	ui.button(page,"Cerrar mapa",Rect2(420,280,162,33),game.close_city_panel)

func map_place(index: int) -> void:
	if index<0: return
	game.close_city_panel()
	game.message.text = ["Supermercado: edificio más ancho de Avenida del Faro.","Ferretería: entre el supermercado y el café.","Cafetería: extremo este de Avenida del Faro.","Atelier: Calle Modistas, al oeste de Avenida del Faro."][index]
