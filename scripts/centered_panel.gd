extends PanelContainer

var center_viewport: Viewport
func _ready() -> void:
	center_viewport = get_viewport()
	resized.connect(center_in_viewport)
	center_viewport.size_changed.connect(center_in_viewport)
	center_in_viewport.call_deferred()

func center_in_viewport() -> void:
	if is_instance_valid(center_viewport): position = ((center_viewport.get_visible_rect().size-size)*0.5).round()

func _exit_tree() -> void:
	if is_instance_valid(center_viewport) and center_viewport.size_changed.is_connected(center_in_viewport):
		center_viewport.size_changed.disconnect(center_in_viewport)
