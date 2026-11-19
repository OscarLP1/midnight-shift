extends PanelContainer

var center_viewport: Viewport
var last_safe_rect := Rect2()
func _ready() -> void:
	center_viewport = get_viewport()
	resized.connect(center_in_viewport)
	center_viewport.size_changed.connect(center_in_viewport)
	center_in_viewport.call_deferred()

func center_in_viewport() -> void:
	if is_instance_valid(center_viewport):
		var safe := preload("res://scripts/responsive_ui.gd").safe_rect(center_viewport)
		last_safe_rect = safe
		var fit := minf(1.0,minf((safe.size.x-16)/maxf(size.x,1),(safe.size.y-16)/maxf(size.y,1)))
		scale = Vector2.ONE*fit
		position = (safe.position+(safe.size-size*scale)*0.5).round()

func _process(_delta: float) -> void:
	if is_instance_valid(center_viewport) and preload("res://scripts/responsive_ui.gd").safe_rect(center_viewport)!=last_safe_rect:
		center_in_viewport()

func _exit_tree() -> void:
	if is_instance_valid(center_viewport) and center_viewport.size_changed.is_connected(center_in_viewport):
		center_viewport.size_changed.disconnect(center_in_viewport)
