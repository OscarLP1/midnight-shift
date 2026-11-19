extends RefCounted

# Distance advances the gait, so animation cannot outrun actual movement.
const PROFILES = {
 "employee-modern": {"walk":"employee-walk-8","run":"employee-run-8","walk_stride":44.0,"run_stride":64.0,"run_threshold":115.0},
 "police-officer": {"run":"police-officer","walk_stride":42.0,"run_stride":62.0,"run_threshold":105.0},
 "burglar": {"run":"burglar","walk_stride":42.0,"run_stride":58.0,"run_threshold":88.0}
}
const PROFILE_KEYS = ["asset","walk_columns","run_columns","rest_frame","walk_stride","run_stride","run_threshold","max_cadence"]

static func copy_profile(target: AnimatedSprite2D, source: AnimatedSprite2D) -> void:
 for key in PROFILE_KEYS:
  if source.has_meta(key): target.set_meta(key,source.get_meta(key))
  elif target.has_meta(key): target.remove_meta(key)
 target.set_meta("gait_phase",0.0)

static func facing(sprite: AnimatedSprite2D) -> int:
 return int(sprite.get_meta("facing",int(String(sprite.animation).trim_prefix("run_"))))

static func direction_for(sprite: AnimatedSprite2D, displacement: Vector2) -> int:
 var previous := facing(sprite)
 var x := absf(displacement.x)
 var y := absf(displacement.y)
 # Keep the previous axis near a diagonal instead of flickering between profiles.
 var horizontal := x>y*1.15 or (previous in [2,3] and x>=y*0.87)
 if horizontal and x>0.0001: return 3 if displacement.x>0 else 2
 return 0 if displacement.y>0 else 1

static func update_head_columns(sprite: AnimatedSprite2D, columns: int) -> void:
 if sprite.get_meta("uses_head_atlas",false) and sprite.material is ShaderMaterial:
  sprite.material.set_shader_parameter("columns",float(columns))

static func animate(sprite: AnimatedSprite2D, displacement: Vector2, speed: float = 90.0, mode := "") -> void:
 if displacement.length_squared()<0.0001:
  face(sprite,facing(sprite))
  return
 var direction := direction_for(sprite,displacement)
 var running: bool = (mode=="run" or speed>=float(sprite.get_meta("run_threshold",INF))) and sprite.sprite_frames.has_animation("run_"+str(direction))
 var key := ("run_" if running else "")+str(direction)
 var stride: float = sprite.get_meta("run_stride",58.0) if running else sprite.get_meta("walk_stride",40.0)
 var scale := maxf(0.1,absf(sprite.scale.y))
 var phase := fposmod(float(sprite.get_meta("gait_phase",0.0))+displacement.length()/(stride*scale),1.0)
 sprite.set_meta("gait_phase",phase)
 sprite.set_meta("facing",direction)
 var count := sprite.sprite_frames.get_frame_count(key)
 sprite.play(key)
 sprite.speed_scale = 0.0
 var frame := mini(count-1,int(phase*count))
 sprite.set_frame_and_progress(frame,phase*count-frame)
 update_head_columns(sprite,count)

static func face(sprite: AnimatedSprite2D, direction: int) -> void:
 sprite.set_meta("facing",direction)
 sprite.animation = str(direction)
 sprite.pause()
 sprite.frame = clampi(int(sprite.get_meta("rest_frame",0)),0,sprite.sprite_frames.get_frame_count(str(direction))-1)
 update_head_columns(sprite,sprite.sprite_frames.get_frame_count(str(direction)))
