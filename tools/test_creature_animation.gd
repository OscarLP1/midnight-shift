extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start(false)
 game.events.muted = true
 for asset in ["employee-modern","burglar","police-officer","customer-woman","customer-senior","customer-courier","stray-dog"]:
  var actor = game.make_actor(asset)
  for pair in [[Vector2.DOWN,"0"],[Vector2.UP,"1"],[Vector2.LEFT,"2"],[Vector2.RIGHT,"3"]]:
   game.Motion.animate(actor,pair[0],110)
   assert(actor.animation==pair[1] and actor.is_playing())
   assert(actor.sprite_frames.get_frame_count(pair[1])==4)
  game.Motion.animate(actor,Vector2.ZERO)
  assert(not actor.is_playing())
  actor.free()
 for index in range(3):
  game.night = index+1
  game.events.reset_shift()
  game.elapsed = game.events.horror_start()
  game.events.tick(0.01)
  assert(game.events.monster_index==index)
  var creature = game.events.creatures[index]
  for pair in [[Vector2.DOWN,"0"],[Vector2.UP,"1"],[Vector2.LEFT,"2"],[Vector2.RIGHT,"3"]]:
   game.Motion.animate(creature,pair[0],60)
   assert(creature.animation==pair[1])
  var origin: Vector2 = game.events.monster_position
  for i in range(180): game.events.tick(1.0/60)
  assert(game.events.monster_position.distance_to(origin)>5)
  game.events._process(0)
  assert(creature.visible)
  game.active = false
  game.events._process(0.1)
  assert(not creature.is_playing())
  game.active = true
  for i in range(360): game.events.tick(1.0/60)
  assert(game.events.vocal_count>=2)
  assert(game.events.voice.stream.get_length()>2)
  if index==2: assert(game.events.last_vocal=="drowned-sobs")
  game.events.tick(20)
  assert(game.events.apparition==0 and not creature.visible)
 game.crowd.thief_times.assign([0.0])
 game.crowd.spawn()
 game.active = false
 game._process(0.1)
 assert(not game.crowd.people[0].sprite.is_playing())
 print("PASS: actor four-way gait, monster movement and direction, repeated distinct vocals, sob identity, pause and disappearance")
 game.free()
 await process_frame
 quit()
