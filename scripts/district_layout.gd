extends RefCounted
# One world unit is one art pixel at the employee's original scale.
const STREET_SIZE = Vector2(640,360)
const WALK_MIN = Vector2(24,240)
const WALK_MAX = Vector2(616,282)
const DOORS = {"store":210.0,"hardware":459.0,"cafe":536.0,"atelier":308.0}
const ROOM_SCALE = {"cafe":1.0,"hardware":1.0,"atelier":1.0}
static func walk_min(street: int) -> Vector2:
	return Vector2(24,253 if street==1 else 245)
static func scale_for(place: String) -> float:
	return ROOM_SCALE.get(place,1.0)
static func origin_for(place: String) -> Vector2:
	return (Vector2(640,360)-Vector2(640,360)*scale_for(place))*0.5
static func room_point(place: String, point: Vector2) -> Vector2:
	return origin_for(place)+point*scale_for(place)
static func local_point(place: String, point: Vector2) -> Vector2:
	return (point-origin_for(place))/scale_for(place)
static func street_texture(street: int) -> String:
	return "res://assets/courtyard-modistas.png" if street==1 else "res://assets/courtyard-avenue.png"
