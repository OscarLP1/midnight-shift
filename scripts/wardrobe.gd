extends RefCounted

const ASSETS = ["employee-modern","customer-woman","customer-senior"]
const HAIR_NAMES = ["Corto", "Ondulado", "Bob"]
const OUTFITS = ["Camisa de trabajo", "Chaqueta", "Falda y abrigo"]
const COLORS = [Color("317879"),Color("864851"),Color("77718d"),Color("b59b72")]
const HAIR_COLORS = [Color("302821"),Color("76503b"),Color("bd945d"),Color("9998a0")]
var game
var saved := [0,0,0,0]
var draft := [0,0,0,0]
var direction := 0
var config_path := "user://appearance.cfg"

func setup(owner_game) -> void:
	game = owner_game
	var cfg := ConfigFile.new()
	if cfg.load(config_path)==OK:
		for i in range(4): saved[i] = clampi(int(cfg.get_value("look",str(i),0)),0,2 if i<2 else 3)
	apply(game.actor,saved)

func apply(sprite: AnimatedSprite2D, look: Array) -> void:
	var source: AnimatedSprite2D = game.make_actor(ASSETS[look[1]])
	sprite.sprite_frames = source.sprite_frames
	game.Motion.copy_profile(sprite,source)
	source.free()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/appearance.gdshader")
	mat.set_shader_parameter("same_head",look[0]==look[1])
	mat.set_shader_parameter("columns",float(sprite.get_meta("walk_columns",4)))
	sprite.set_meta("uses_head_atlas",true)
	mat.set_shader_parameter("head",load("res://assets/"+ASSETS[look[0]]+".png"))
	mat.set_shader_parameter("jacket",COLORS[look[2]])
	mat.set_shader_parameter("hair",HAIR_COLORS[look[3]])
	sprite.material = mat
	game.Motion.face(sprite,direction)

func open() -> void:
	draft = saved.duplicate()
	direction = 0
	show_page()

func show_page() -> void:
	var ui = game.commerce
	var page: Control = ui.window("HILO Y SOMBRA · ATELIER","PELUQUERÍA Y VESTUARIO  /  PRUEBA TU ASPECTO ANTES DE GUARDAR")
	ui.line(page,Vector2(20,80),Vector2(190,194),Color("203940"))
	var preview: AnimatedSprite2D = game.make_actor(ASSETS[draft[1]])
	apply(preview,draft)
	preview.position = Vector2(114,174)
	preview.scale = Vector2(3,3)
	page.add_child(preview)
	ui.button(page,"Girar ↻",Rect2(45,239,140,30),rotate_preview)
	var values := [HAIR_NAMES[draft[0]],OUTFITS[draft[1]],["Petróleo","Granate","Lavanda","Arena"][draft[2]],["Oscuro","Castaño","Rubio","Plata"][draft[3]]]
	for i in range(4):
		var y := 80+i*47
		ui.label(page,["PEINADO","PRENDA","COLOR DE ROPA","COLOR DE CABELLO"][i],Vector2(235,y),10,ui.MUTED)
		ui.button(page,"‹",Rect2(234,y+16,30,29),cycle.bind(i,-1))
		ui.label(page,values[i],Vector2(275,y+21),13)
		ui.button(page,"›",Rect2(550,y+16,30,29),cycle.bind(i,1))
	ui.label(page,"Vista previa · servicio de cortesía",Vector2(22,288),11,ui.MUTED)
	ui.button(page,"Cancelar",Rect2(287,282,120,32),game.close_city_panel)
	ui.button(page,"Guardar aspecto",Rect2(420,282,160,32),confirm,true)

func cycle(index: int, step: int) -> void:
	draft[index] = posmod(draft[index]+step,3 if index<2 else 4)
	show_page()

func rotate_preview() -> void:
	direction = (direction+1)%4
	show_page()

func confirm() -> void:
	var cfg := ConfigFile.new()
	for i in range(4): cfg.set_value("look",str(i),draft[i])
	if cfg.save(config_path)!=OK:
		game.message.text = "No se pudo guardar el aspecto. Inténtalo de nuevo."
		return
	saved = draft.duplicate()
	apply(game.actor,saved)
	game.close_city_panel()
	game.message.text = "Tu nuevo aspecto quedó guardado."
