extends Node
var game
var ambience: Array[AudioStreamPlayer] = []
var effects: Array[AudioStreamPlayer] = []
func setup(owner_game) -> void:
	game = owner_game
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
	for i in range(2):
		ambience[i].stream_paused = not game.active or game.events.muted
		var target := -17.0 if game.events.weather==i+1 else -60.0
		if game.location!="city": target -= 9
		ambience[i].volume_db = move_toward(ambience[i].volume_db,target+linear_to_db(maxf(.0001,game.events.effects_volume)),delta*12)
	for p in effects: p.stream_paused = game.paused or game.events.muted
func _exit_tree() -> void:
	for p in ambience+effects: p.stop()
