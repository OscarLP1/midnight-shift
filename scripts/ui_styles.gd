extends RefCounted

static var selected := 0
const BODY = preload("res://assets/fonts/Atkinson-Regular.ttf")
const BOLD = preload("res://assets/fonts/Atkinson-Bold.ttf")
const TITLE = preload("res://assets/fonts/PixelifySans.ttf")
const NAMES = ["Nocturno", "Pixel ámbar", "Papel"]

static func apply(button: Button, primary := false, preset := -1) -> void:
	var index := selected if preset<0 else preset
	var fills := [Color("20383f"),Color("282033"),Color("eee1c8")]
	var accents := [Color("8ed7be"),Color("efc16d"),Color("76583c")]
	var texts := [Color("e4f2ed"),Color("ffe2a3"),Color("3f342a")]
	for state in ["normal","hover","pressed","disabled","focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = accents[index] if primary else fills[index]
		box.border_color = accents[index]
		box.set_border_width_all(2 if index==1 else 1)
		box.set_corner_radius_all(0 if index==1 else 4)
		if state=="hover": box.bg_color = box.bg_color.lightened(0.15)
		if state=="pressed": box.bg_color = box.bg_color.darkened(0.15)
		if state=="disabled": box.bg_color = fills[index].darkened(0.15)
		if state=="focus": box.bg_color = Color.TRANSPARENT
		button.add_theme_stylebox_override(state,box)
	button.add_theme_font_override("font",TITLE if index==1 else BOLD)
	button.add_theme_color_override("font_color",fills[index] if primary else texts[index])
	button.add_theme_color_override("font_hover_color",fills[index] if primary else texts[index])
	button.add_theme_color_override("font_pressed_color",texts[index])
	button.add_theme_color_override("font_disabled_color",texts[index].darkened(0.35))
	button.add_theme_font_size_override("font_size",13)

static func icon(kind: String, preset := -1) -> Texture2D:
	var index := selected if preset<0 else preset
	return load("res://assets/ui/%s-%d.svg" % [kind,index])
