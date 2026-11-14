extends Node2D

var game: Node2D
var door_amount := 0.0
var door_index := 0
var amounts := [0.0,0.0,0.0,0.0,0.0]

func _process(delta: float) -> void:
	if game == null: return
	z_index = 1
	visible = game.location == "store"
	if not visible: return
	if game.events.door >= 0: door_index = game.events.door
	if game.events.haunt_door >= 0: door_index = game.events.haunt_door
	if game.active:
		door_amount = move_toward(door_amount,1.0 if game.events.door>=0 or game.events.haunt_door>=0 else 0.0,delta*3)
	for i in range(5):
		if game.active: amounts[i] = move_toward(amounts[i],1.0 if game.events.open_doors[i] else 0.0,delta*2.4)
	queue_redraw()

func _draw() -> void:
	if game == null: return
	# Glass slides over the original painted stock: never replace products with blank panels.
	for i in range(5):
		var x := 46.0+i*112.0
		if game.events.spoiled[i]:
			draw_rect(Rect2(x,56,101,27),Color(0.03,0.09,0.12,0.94))
		var status: String = "DAÑADA" if game.events.spoiled[i] else ("ABIERTA" if game.events.open_doors[i] else "CERRADA")
		draw_string(ThemeDB.fallback_font,Vector2(x,94),status+" · "+str(game.zone_stock[i+3]),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("efb56d") if game.events.open_doors[i] else Color("b4ddce"))
		if amounts[i]>0:
			var edge: float = x+38+amounts[i]*35
			draw_rect(Rect2(edge,55,30,29),Color(0.35,0.65,0.72,0.16))
			draw_rect(Rect2(edge,55,30,29),Color("a7d8dc"),false,1)
			draw_line(Vector2(edge+24,65),Vector2(edge+24,75),Color("daeff0"),2)
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
