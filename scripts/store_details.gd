extends Node2D

var game: Node2D
var door_amount := 0.0
var door_index := 0
var amounts := [0.0,0.0,0.0,0.0,0.0]
var door_sprites: Array[Sprite2D] = []

func _ready() -> void:
	# Door leaves stay above the background (-10), below every walking actor (0).
	z_index = -2
	for i in range(5):
		# Two coplanar glass leaves. The right leaf slides behind the left leaf.
		for leaf in range(2):
			var sprite := Sprite2D.new()
			var atlas := AtlasTexture.new()
			atlas.atlas = preload("res://assets/fridge-doors.png")
			atlas.region = Rect2(leaf*52,10,52,34)
			atlas.filter_clip = true
			sprite.texture = atlas
			sprite.centered = false
			sprite.position = Vector2(46+i*112+leaf*52,54)
			var glass := ShaderMaterial.new()
			glass.shader = preload("res://scripts/fridge_glass.gdshader")
			glass.set_shader_parameter("leaf_origin",Vector2(leaf*52,10))
			sprite.material = glass
			sprite.z_index = 1 if leaf==0 else 0
			add_child(sprite)
			door_sprites.append(sprite)

func _process(delta: float) -> void:
	if game == null: return
	visible = game.location == "store"
	if not visible: return
	if game.events.door >= 0: door_index = game.events.door
	if game.events.haunt_door >= 0: door_index = game.events.haunt_door
	if game.active:
		door_amount = move_toward(door_amount,1.0 if game.events.door>=0 or game.events.haunt_door>=0 else 0.0,delta*3)
	for i in range(5):
		if game.active: amounts[i] = move_toward(amounts[i],1.0 if game.events.open_doors[i] else 0.0,delta*2.4)
		var slide: float = smoothstep(0.0,1.0,amounts[i])*49.0
		door_sprites[i*2+1].position.x = 46+i*112+52-slide
	queue_redraw()

func _draw() -> void:
	if game == null: return
	# Glass slides over the original painted stock: never replace products with blank panels.
	for i in range(5):
		var x := 46.0+i*112.0
		if game.events.spoiled[i]:
			draw_rect(Rect2(x,56,101,27),Color(0.03,0.09,0.12,0.94))
	if game.progression.owned.has("storage"):
		draw_rect(Rect2(550,99,50,16),Color("594631"))
		draw_string(ThemeDB.fallback_font,Vector2(553,110),"ALMACÉN",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f1d4a0"))
		for y in [86,94]:
			for x in [555,570,585]:
				draw_rect(Rect2(x,y,13,7),Color("826044"))
				draw_line(Vector2(x,y),Vector2(x+12,y),Color("cca175"))
				draw_rect(Rect2(x+5,y,3,6),Color("bda477"))
	if game.progression.owned.has("register"):
		draw_rect(Rect2(101,198,23,15),Color("254250"))
		draw_rect(Rect2(103,200,19,11),Color("8fe0c8"))
		draw_string(ThemeDB.fallback_font,Vector2(105,209),"POS",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("173c40"))
		draw_rect(Rect2(143,213,9,12),Color("232c40"))
		draw_rect(Rect2(145,215,5,5),Color("71d5bf"))
		draw_line(Vector2(145,222),Vector2(149,222),Color("e9c998"))
	if game.progression.owned.has("security"):
		for x in [35,596]:
			draw_arc(Vector2(x+8,51),13,0.3,2.6,12,Color(0.3,0.9,0.7,0.6),1)
			draw_line(Vector2(x,43),Vector2(x+5,49),Color("596679"),2)
			draw_rect(Rect2(x+3,47,9,5),Color("c0c6cf"))
			draw_rect(Rect2(x+10,48,2,3),Color("233147"))
			draw_rect(Rect2(x+4,49,1,1),Color("75c5a1"))
