extends RefCounted

const BASE_ASSET := "employee-modern"
const HEAD_ASSETS := ["employee-modern","customer-woman"]
const GENDERS := ["Hombre","Mujer"]
const HAIR_NAMES := ["Corte clásico","Flequillo suave","Rizo corto","Bob ondulado","Trenza alta","Recogido"]
const OUTFIT_NAMES := ["Uniforme petróleo","Chaqueta granate","Suéter lavanda","Abrigo arena","Uniforme nocturno","Chaqueta ciruela"]
const OUTFIT_COLORS := [0,1,2,3,0,1]
const HAIR_STYLES := [0,1,2,0,2,1]
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
		for i in range(4): saved[i] = clampi(int(cfg.get_value("look",str(i),0)),0,1 if i==0 else (5 if i==1 else 3))
	apply(game.actor,saved)

func normalized(look: Array) -> Array:
	var result: Array = look.duplicate()
	while result.size()<4: result.append(0)
	result[0] = clampi(int(result[0]),0,1)
	result[1] = clampi(int(result[1]),0,5)
	result[2] = OUTFIT_COLORS[result[1]]
	result[3] = HAIR_STYLES[result[1]]
	return result

func apply(sprite: AnimatedSprite2D, look: Array) -> void:
	var style := normalized(look)
	var source: AnimatedSprite2D = game.make_actor(BASE_ASSET)
	sprite.sprite_frames = source.sprite_frames
	game.Motion.copy_profile(sprite,source)
	source.free()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/appearance.gdshader")
	mat.set_shader_parameter("same_head",true)
	mat.set_shader_parameter("female",style[0]==1)
	mat.set_shader_parameter("female_head",load("res://assets/protagonist-female-head.png"))
	mat.set_shader_parameter("columns",float(sprite.get_meta("walk_columns",4)))
	mat.set_shader_parameter("haircut",float(style[1]))
	sprite.set_meta("uses_head_atlas",true)
	mat.set_shader_parameter("head",load("res://assets/"+HEAD_ASSETS[style[0]]+".png"))
	mat.set_shader_parameter("jacket",COLORS[style[2]])
	mat.set_shader_parameter("hair",HAIR_COLORS[style[3]])
	sprite.material = mat
	game.Motion.face(sprite,direction)

func open() -> void:
	draft = normalized(saved)
	direction = 0
	show_page()

func show_page() -> void:
	var ui = game.commerce
	var page: Control = ui.window("HILO Y SOMBRA · ATELIER","UN MISMO PERSONAJE  /  ELIGE GÉNERO Y UNA DE SEIS COMBINACIONES")
	ui.line(page,Vector2(20,80),Vector2(190,194),Color("203940"))
	var preview: AnimatedSprite2D = game.make_actor(BASE_ASSET)
	apply(preview,draft)
	preview.position = Vector2(114,174)
	preview.scale = Vector2(3,3)
	page.add_child(preview)
	ui.button(page,"Girar ↻",Rect2(45,239,140,30),rotate_preview)
	ui.label(page,"GÉNERO",Vector2(233,80),10,ui.MUTED)
	var genders := HBoxContainer.new()
	genders.position = Vector2(233,98)
	genders.size = Vector2(352,32)
	genders.add_theme_constant_override("separation",8)
	page.add_child(genders)
	for i in range(2):
		var button := Button.new()
		button.text = GENDERS[i]
		game.UIStyles.apply(button,draft[0]==i)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 32
		button.pressed.connect(set_gender.bind(i))
		genders.add_child(button)
	ui.label(page,"CONJUNTO Y PEINADO",Vector2(233,142),10,ui.MUTED)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(233,161)
	grid.size = Vector2(352,102)
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	page.add_child(grid)
	var names := ["Petróleo","Granate","Lavanda","Arena","Nocturno","Ciruela"]
	for i in range(6):
		var button := Button.new()
		button.text = names[i]
		button.tooltip_text = OUTFIT_NAMES[i]+" · "+HAIR_NAMES[i]
		game.UIStyles.apply(button,draft[1]==i)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(172,28)
		button.pressed.connect(select_outfit.bind(i))
		grid.add_child(button)
	ui.label(page,HAIR_NAMES[draft[1]],Vector2(233,266),10,ui.MUTED,352)
	ui.label(page,"Vista previa de tu personaje",Vector2(22,290),10,ui.MUTED,250)
	ui.button(page,"Cancelar",Rect2(314,290,112,28),game.close_city_panel)
	ui.button(page,"Guardar aspecto",Rect2(434,290,152,28),confirm,true)

func select_outfit(index: int) -> void:
	draft[1] = clampi(index,0,5)
	draft = normalized(draft)
	show_page()

func set_gender(index: int) -> void:
	draft[0] = clampi(index,0,1)
	show_page()

func cycle(index: int, step: int) -> void:
	if index==0: set_gender(posmod(draft[0]+step,2))
	else: select_outfit(posmod(draft[1]+step,6))

func rotate_preview() -> void:
	direction = (direction+1)%4
	show_page()

func confirm() -> void:
	draft = normalized(draft)
	var cfg := ConfigFile.new()
	for i in range(4): cfg.set_value("look",str(i),draft[i])
	if cfg.save(config_path)!=OK:
		game.message.text = "No se pudo guardar el aspecto. Inténtalo de nuevo."
		return
	saved = draft.duplicate()
	apply(game.actor,saved)
	game.close_city_panel()
	game.message.text = "Tu aspecto quedó guardado."
