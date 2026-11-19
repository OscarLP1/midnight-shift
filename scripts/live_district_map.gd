extends Control
var game
var phase := 0.0
var artwork: Texture2D
func _ready() -> void:
	artwork = load("res://assets/district-map-art.png")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	phase += delta
	queue_redraw()
func _draw() -> void:
	if artwork==null: return
	draw_texture_rect(artwork,Rect2(Vector2.ZERO,size),false)
	var point := Vector2(12+clampf(game.player.position.x/640.0,0,1)*(size.x-24),size.y*(0.45 if game.street==1 else 0.91))
	draw_circle(point,7+sin(phase*3)*1.5,Color(0.56,1,0.82,0.25))
	draw_circle(point,4,Color("8effce"))
	draw_arc(point,4,0,TAU,24,Color("12242b"),1)
	var font = preload("res://assets/fonts/Atkinson-Bold.ttf")
	for entry in [["Lavandería · Próximamente",12,12],["Atelier",260,12],["Muebles · Próximamente",405,12],["Supermercado",30,112],["Ferretería",355,112],["Café",490,112]]:
		var pos := Vector2(entry[1],entry[2])
		draw_rect(Rect2(pos,Vector2(font.get_string_size(entry[0],HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+8,16)),Color(0.03,0.07,0.1,0.88))
		draw_string(font,pos+Vector2(4,12),entry[0],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e7ede7"))
