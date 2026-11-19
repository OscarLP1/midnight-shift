extends Node2D
var game
func _process(_delta: float) -> void:
 visible = game.location=="store"
 var amount: float = game.security.hide_amount
 var frame := mini(3,int(amount*4.0))
 if game.foreground_props.size()>3:
  var atlas: AtlasTexture = game.foreground_props[3].texture
  atlas.region = Rect2(frame*96,0,96,61)
 queue_redraw()
func _draw() -> void:
 if game.security.hide_amount<=0: return
 # Redraw the photographed wood frame and open door in front of the crouched actor.
 var frame := mini(3,int(game.security.hide_amount*4.0))
 var sheet: Texture2D = preload("res://assets/counter-opening.png")
 # Side jambs and top rail retain the recessed silhouette.
 for rect in [Rect2(0,33,29,28),Rect2(65,33,31,28),Rect2(29,30,36,5),Rect2(29,58,36,3)]:
  draw_texture_rect_region(sheet,Rect2(Vector2(69,195)+rect.position,rect.size),Rect2(Vector2(frame*96,0)+rect.position,rect.size))
 # Left hinged leaf, narrow when fully open.
 var door_width: float = [30.0,25.0,15.0,12.0][frame]
 var door_x: float = 29.0 if frame<3 else 18.0
 var door := Rect2(door_x,35,door_width,26)
 draw_texture_rect_region(sheet,Rect2(Vector2(69,195)+door.position,door.size),Rect2(Vector2(frame*96,0)+door.position,door.size))
