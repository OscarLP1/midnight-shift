extends Node2D
var game
var closure := 0.0
func _process(delta: float) -> void:
	if game==null: return
	visible = game.location=="store"
	if game.active: closure = move_toward(closure,1.0 if game.security.closed else 0.0,delta*1.6)
	queue_redraw()
func _draw() -> void:
	if game==null: return
	if game.security.hide_amount>0:
		draw_rect(Rect2(97,234,32,22),Color("302a27"))
		draw_rect(Rect2(97,234,32,22),Color("79513a"),false,1)
		draw_line(Vector2(98,255),Vector2(128,255),Color("c38b52"),1)
	# Two framed glass leaves slide into the wall pockets along the same track.
	draw_rect(Rect2(276,269,88,3),Color("455764"))
	draw_rect(Rect2(277,304,86,3),Color("455764"))
	for i in range(2):
		var x: float = (279.0-34*(1-closure)) if i==0 else (319.0+34*(1-closure))
		draw_rect(Rect2(x,272,40,32),Color(0.2,0.42,0.5,0.26))
		draw_rect(Rect2(x,272,40,32),Color("71929e"),false,1)
		draw_line(Vector2(x+5,277),Vector2(x+17,289),Color(0.75,0.91,0.95,0.4),1)
		draw_line(Vector2(x+10,276),Vector2(x+27,293),Color(0.75,0.91,0.95,0.22),2)
		var handle: float = x+34 if i==0 else x+6
		draw_line(Vector2(handle,284),Vector2(handle,293),Color("c9d8dc"),2)
	for x in [276,362]:
		draw_rect(Rect2(x,269,2,38),Color("455764"))
		draw_circle(Vector2(x+1,271),0.5,Color("aabcc2"))
