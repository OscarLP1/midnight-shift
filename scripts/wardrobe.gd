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
	mat.set_shader_parameter("same_head",style[0]==0)
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
	for i in range(2):
		var gender_button: Button = ui.button(page,GENDERS[i],Rect2(233+i*180,97,172,32),set_gender.bind(i),draft[0]==i)
	ui.label(page,"SEIS CONJUNTOS · PRENDA Y PEINADO",Vector2(233,143),10,ui.MUTED)
	for i in range(6):
		var col := i%3
		var row := i/3
		var y := 161+row*48
		var outfit_button: Button = ui.button(page,OUTFIT_NAMES[i]+"\n"+HAIR_NAMES[i],Rect2(233+col*120,y,112,44),select_outfit.bind(i),draft[1]==i)
		outfit_button.clip_text = true
	ui.label(page,"Tu personaje mantiene cuerpo y animaciones.",Vector2(22,288),10,ui.MUTED,278)
	ui.button(page,"Cancelar",Rect2(314,282,112,32),game.close_city_panel)
	ui.button(page,"Guardar aspecto",Rect2(434,282,152,32),confirm,true)

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
