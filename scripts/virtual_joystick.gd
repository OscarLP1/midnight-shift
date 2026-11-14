extends Control

signal changed(value: Vector2)
var finger := -1
var value := Vector2.ZERO
var radius := 36.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(26,254)
	size = Vector2(88,88)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(44,44),radius,Color(0.08,0.15,0.23,0.75))
	draw_arc(Vector2(44,44),radius,0,TAU,48,Color(0.43,0.76,0.75,0.7),2)
	draw_circle(Vector2(44,44)+value*radius,14,Color(0.6,0.85,0.8,0.8))

func reset() -> void:
	finger = -1
	value = Vector2.ZERO
	changed.emit(value)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and get_global_rect().has_point(event.position):
			finger = event.index
		elif not event.pressed and event.index == finger:
			reset()
	if event is InputEventScreenDrag and event.index == finger:
		value = ((event.position-global_position-Vector2(44,44))/radius).limit_length()
		changed.emit(value)
		queue_redraw()
