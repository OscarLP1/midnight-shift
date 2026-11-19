extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start(false)
 game.events.muted = true
 for asset in ["employee-modern","police-officer","burglar"]:
  var sprite = game.make_actor(asset)
  for pair in [[Vector2.DOWN,"0"],[Vector2.UP,"1"],[Vector2.LEFT,"2"],[Vector2.RIGHT,"3"]]:
   game.Motion.animate(sprite,pair[0],70)
   assert(sprite.animation==pair[1])
   game.Motion.animate(sprite,pair[0],145)
   assert(sprite.animation=="run_"+pair[1] and sprite.sprite_frames.get_frame_count(sprite.animation)==8)
  var phase: float = sprite.get_meta("gait_phase")
  game.Motion.animate(sprite,Vector2.ZERO,145)
  assert(not sprite.is_playing() and sprite.get_meta("gait_phase")==phase)
  sprite.free()
 var a = game.make_actor("employee-modern")
 var b = game.make_actor("employee-modern")
 for i in range(60): game.Motion.animate(a,Vector2(72.0/60,0),72)
 for i in range(30): game.Motion.animate(b,Vector2(72.0/30,0),72)
 assert(is_equal_approx(a.get_meta("gait_phase"),b.get_meta("gait_phase")))
 assert(a.frame==b.frame)
 var current: int = a.frame
 await create_timer(0.15).timeout
 assert(a.frame==current)
 game.Motion.face(a,3)
 for move in [Vector2(1,1.02),Vector2(1.02,1),Vector2(1,0.99)]:
  game.Motion.animate(a,move,70)
  assert(game.Motion.facing(a)==3)
 game.Motion.animate(a,Vector2(0,1),70)
 assert(game.Motion.facing(a)==0)
 game.wardrobe.apply(game.actor,[0,0,0,0])
 assert(game.actor.sprite_frames.get_frame_count("0")==8)
 game.Motion.animate(game.actor,Vector2.RIGHT,145)
 assert(game.actor.material.get_shader_parameter("columns")==8.0)
 game.wardrobe.apply(game.actor,[1,1,0,0])
 assert(game.actor.sprite_frames.get_frame_count("0")==4 and not game.actor.sprite_frames.has_animation("run_0"))
 assert(game.actor.get_meta("walk_columns")==4)
 a.free()
 b.free()
 print("PASS: 8-frame runs in four directions, gait follows distance, frame-rate independence, no foot movement while blocked, diagonal stability, wardrobe 4/8-frame compatibility")
 game.free()
 await process_frame
 quit()
