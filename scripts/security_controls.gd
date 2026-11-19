extends "res://scripts/centered_panel.gd"
var game
var status: Label
var door: Button
var call: Button
var hide: Button

func setup(owner_game) -> void:
	game = owner_game
	custom_minimum_size = Vector2(204,174)
	game.style_control(self)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Seguridad"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Cerrar Seguridad · Esc"
	close.custom_minimum_size = Vector2(24,24)
	close.pressed.connect(game.close_security_menu)
	header.add_child(close)
	status = Label.new()
	status.add_theme_font_size_override("font_size",11)
	column.add_child(status)
	door = action(column,"",game.security.toggle_door)
	call = action(column,"",game.security.call_police)
	hide = action(column,"",game.security.hide_player)
	refresh()

func action(parent: Node, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(174,27)
	button.set_meta("compact_hud",true)
	game.UIStyles.apply(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if game==null: return
	var labels := {"idle":"Disponible","arriving":"Acercándose","parked":"Estacionada","chasing":"En intervención","escorting":"Escoltando","securing_exit":"Cerrando la puerta","departing":"Retirándose"}
	status.text = "Patrulla: %s" % ("en %ds" % int(ceil(game.security.police)) if game.security.police>=0 else labels.get(game.security.police_state,"En servicio"))
	door.text = ("Abrir entrada" if game.security.closed else "Cerrar entrada")+" · B"
	call.text = "Llamar a la policía · P"
	call.disabled = game.security.police>=0 or game.security.police_state!="idle"
	hide.text = ("Salir del escondite" if game.security.hiding else "Esconderse")+" · H"
