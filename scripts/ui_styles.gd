extends RefCounted

static var selected := 0
const BODY = preload("res://assets/fonts/Atkinson-Regular.ttf")
const BOLD = preload("res://assets/fonts/Atkinson-Bold.ttf")
const TITLE = preload("res://assets/fonts/PixelifySans.ttf")
const NAMES = ["Nocturno"]
const FONT_CAPTION := 10
const FONT_BODY := 12
const FONT_CONTROL := 13
const FONT_SECTION := 16
const FONT_TITLE := 22
const SPACE_XS := 4
const SPACE_SM := 8
const SPACE_MD := 16
const SPACE_LG := 24

static func font_for_size(value: int) -> int:
	if value >= 20: return FONT_TITLE
	if value >= 15: return FONT_SECTION
	if value >= 12: return FONT_BODY
	return FONT_CAPTION

static func apply_label(label: Label, requested_size := FONT_BODY) -> void:
	var size := font_for_size(requested_size)
	label.add_theme_font_override("font",TITLE if size==FONT_TITLE else (BOLD if size>=FONT_SECTION else BODY))
	label.add_theme_font_size_override("font_size",size)

static func apply(button: Button, primary := false, preset := -1) -> void:
	var index := 0
	var fills := [Color("20383f"),Color("282033"),Color("eee1c8")]
	var accents := [Color("8ed7be"),Color("efc16d"),Color("76583c")]
	var texts := [Color("e4f2ed"),Color("ffe2a3"),Color("3f342a")]
	for state in ["normal","hover","pressed","disabled","focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = accents[index] if primary else fills[index]
		box.border_color = accents[index]
		box.set_border_width_all(2 if index==1 else 1)
		if button.get_meta("compact_hud",false):
			box.content_margin_left = 5
			box.content_margin_right = 5
			box.content_margin_top = 2
			box.content_margin_bottom = 2
		box.set_corner_radius_all(0 if index==1 else 4)
		if state=="hover": box.bg_color = box.bg_color.lightened(0.15)
		if state=="pressed": box.bg_color = box.bg_color.darkened(0.15)
		if state=="disabled": box.bg_color = fills[index].darkened(0.15)
		if state=="focus": box.bg_color = Color.TRANSPARENT
		button.add_theme_stylebox_override(state,box)
	button.add_theme_font_override("font",BOLD)
	button.add_theme_color_override("font_color",fills[index] if primary else texts[index])
	button.add_theme_color_override("font_hover_color",fills[index] if primary else texts[index])
	button.add_theme_color_override("font_pressed_color",texts[index])
	button.add_theme_color_override("font_disabled_color",texts[index].darkened(0.35))
	button.add_theme_font_size_override("font_size",FONT_BODY if button.get_meta("compact_hud",false) else FONT_CONTROL)

static func icon(kind: String, preset := -1) -> Texture2D:
	var index := 0
	return load("res://assets/ui/%s-%d.svg" % [kind,index])
