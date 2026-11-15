extends RefCounted
var game
var commands_open := false
var return_to_pause := false

func setup(owner_game) -> void:
	game = owner_game

func main_menu() -> void:
	commands_open = false
	game.paused = false
	game.set_game_controls_visible(false)
	var ui = game.commerce
	var page: Control = ui.window("TURNO DE MEDIANOCHE","22:00 — 06:00  /  UNA TIENDA. UNA NOCHE POR DELANTE.")
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.texture = load("res://assets/store-modern.png")
	picture.position = Vector2(20,84)
	picture.size = Vector2(316,178)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	page.add_child(picture)
	ui.label(page,"Atiende la tienda. Recorre el barrio.",Vector2(22,274),12,ui.INK)
	ui.label(page,"Sobrevive a las últimas horas del turno.",Vector2(22,293),11,ui.MUTED)
	var saved: bool = not game.SaveStore.load_game().is_empty()
	ui.label(page,"BIENVENIDO AL TURNO",Vector2(366,84),11,ui.ACCENT)
	ui.button(page,"Continuar" if saved else "Sin partida guardada",Rect2(365,108,217,38),game.start.bind(true),saved,not saved)
	ui.button(page,"Nueva partida",Rect2(365,156,217,38),game.start.bind(false),not saved)
	ui.button(page,"Comandos",Rect2(365,214,217,38),commands.bind(false))
	ui.label(page,"Teclado y controles táctiles",Vector2(367,274),11,ui.MUTED)
	ui.label(page,"Consulta la guía antes de empezar.",Vector2(367,293),10,ui.MUTED)

func commands(from_pause := false) -> void:
	commands_open = true
	return_to_pause = from_pause
	var ui = game.commerce
	var page: Control = ui.window("COMANDOS","CONTROLES Y ACCIONES  /  PUEDES CONSULTAR ESTA GUÍA DESDE PAUSA")
	var groups := [
		[["WASD","Moverse · también flechas"],["Shift","Correr"],["E","Interactuar y atender"],["R","Reponer la zona cercana"],["Esc","Pausar / cerrar Seguridad"]],
		[["B","Abrir / cerrar la entrada"],["P","Llamar a la policía"],["H","Esconderse / salir"],["M","Mapa del barrio"],["F2","Estilo de controles"]]
	]
	for column in range(2):
		var x := 20+column*292
		for row in range(5):
			var y := 86+row*34
			ui.line(page,Vector2(x,y),Vector2(78,27),Color("28434a"))
			ui.label(page,groups[column][row][0],Vector2(x+6,y+5),11,ui.ACCENT)
			ui.label(page,groups[column][row][1],Vector2(x+86,y+5),11,ui.INK)
	ui.label(page,"E: examinar productos, cobrar, recuperar mercancía y limpiar, según dónde estés.",Vector2(21,250),11,ui.MUTED)
	ui.label(page,"Táctil: arrastra el mando y toca cerca de tu personaje para interactuar.",Vector2(21,269),11,ui.MUTED)
	ui.button(page,"Volver a Pausa" if from_pause else "Menú principal",Rect2(398,292,184,30),back)

func back() -> void:
	commands_open = false
	if return_to_pause:
		game.active = true
		game.pause_shift()
	else: main_menu()
