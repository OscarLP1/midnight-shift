extends Node
var game
var ambience: Array[AudioStreamPlayer] = []
var effects: Array[AudioStreamPlayer] = []
var siren: AudioStreamPlayer
var siren_requested := false
func setup(owner_game) -> void:
	game = owner_game
	siren = AudioStreamPlayer.new()
	var alarm: AudioStreamWAV = load("res://assets/audio/patrol-siren.wav")
	alarm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	alarm.loop_end = alarm.data.size()/4
	siren.stream = alarm
	add_child(siren)
	for name in ["rain-soft","winter-wind"]:
		var p := AudioStreamPlayer.new()
		var stream: AudioStreamWAV = load("res://assets/audio/"+name+".wav")
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()/4
		p.stream = stream
		p.volume_db = -60
		add_child(p)
		ambience.append(p)
		if DisplayServer.get_name()!="headless": p.play()
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		effects.append(p)
func play(name: String) -> void:
	if game.events.muted or DisplayServer.get_name()=="headless": return
	for p in effects:
		if not p.playing:
			p.stream = load("res://assets/audio/"+name+".wav")
			p.volume_db = -9+linear_to_db(maxf(.0001,game.events.effects_volume))
			p.play()
			return
func _process(delta: float) -> void:
	if game==null: return
	siren_requested = is_instance_valid(game.security) and game.security.police_state=="arriving" and game.security.patrol_x> -88 and game.location=="store"
	if siren_requested:
		if not siren.playing and DisplayServer.get_name()!="headless": siren.play()
	else: siren.stop()
	siren.stream_paused = not game.active or game.events.muted
	siren.volume_db = -12+linear_to_db(maxf(.0001,game.events.effects_volume))
	for i in range(2):
		ambience[i].stream_paused = not game.active or game.events.muted
		var strength: float = game.events.rain_amount if i==0 else game.events.snow_amount
		var target: float = -17.0+linear_to_db(maxf(0.0001,strength))
		if game.location!="city": target -= 12 if game.security.closed else 7
		ambience[i].volume_db = move_toward(ambience[i].volume_db,target+linear_to_db(maxf(.0001,game.events.effects_volume)),delta*12)
	for p in effects: p.stream_paused = game.paused or game.events.muted
func _exit_tree() -> void:
	if is_instance_valid(siren): siren.stop()
	for p in ambience+effects: p.stop()
