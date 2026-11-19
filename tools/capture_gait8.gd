extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start(false)
 game.events.muted = true
 game.wardrobe.apply(game.actor,[0,0,0,0])
 game.player.position = Vector2(245,265)
 var cast: Array[AnimatedSprite2D] = [game.actor]
 for spec in [["police-officer",345],["burglar",445]]:
  var sprite = game.make_actor(spec[0])
  sprite.position = Vector2(spec[1],265)
  sprite.offset.y = -20
  game.add_child(sprite)
  cast.append(sprite)
 for i in range(4):
  for sprite in cast: game.Motion.animate(sprite,Vector2(4,0),145)
 game.update_hint()
 game.hud.text = "REVISIÓN DE MOVIMIENTO · VERSIÓN 2D"
 game.hint.text = "Empleado · Policía · Ladrón — carrera con 8 cuadros"
 game.message.text = "Ciclos distintos para caminar y correr; los pasos siguen el desplazamiento real."
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/gait8-in-game.png")
 game.free()
 await process_frame
 quit()
