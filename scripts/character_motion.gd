extends RefCounted

static func animate(sprite: AnimatedSprite2D, displacement: Vector2, speed: float = 90.0) -> void:
	if displacement.length_squared()<0.0001:
		sprite.pause()
		sprite.frame = int(sprite.get_meta("rest_frame",0))
		return
	var direction := 0
	if absf(displacement.x)>absf(displacement.y):
		direction = 3 if displacement.x>0 else 2
	else:
		direction = 0 if displacement.y>0 else 1
	sprite.speed_scale = clampf(speed/70.0,0.5,float(sprite.get_meta("max_cadence",1.3)))
	sprite.play(str(direction))

static func face(sprite: AnimatedSprite2D, direction: int) -> void:
	sprite.animation = str(direction)
	sprite.pause()
	sprite.frame = int(sprite.get_meta("rest_frame",0))
