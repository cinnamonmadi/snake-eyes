extends Area2D
class_name Bit

onready var despawn_timer = $despawn_timer
onready var sprite = $sprite

export var GRAVITY: float = -200.0
export var despawns: bool = true
export var despawn_duration: float = 0.5
export var spin_on_floor: bool = false
export var rotation_speed: float = 0.0

var position_3d = Vector3.ZERO
var velocity_3d = Vector3.ZERO
var rotation_velocity: float = 0.0
var use_3d_coordinates = true
var has_hit_wall = false

func _ready():
    add_to_group("clear_on_death")

    var _return_value = self.connect("body_entered", self, "_on_body_entered")

    despawn_timer.connect("timeout", self, "_on_despawn_timer_finish")
    if sprite.has_method("play"):
        sprite.play()

func _on_body_entered(_body):
    velocity_3d = Vector3(0, 0, 0)
    has_hit_wall = true

func set_position_3d(position_2d: Vector2, start_height: float):
    position_3d = Vector3(position_2d.x, position_2d.y + start_height, start_height)
    position = Vector2(position_3d.x, position_3d.y - position_3d.z)

func set_velocity_3d(velocity_2d: Vector2, start_vz: float):
    velocity_3d = Vector3(velocity_2d.x, velocity_2d.y / 2, start_vz)

func _process(delta):
    if not has_hit_wall:
        velocity_3d.z += GRAVITY * delta
        position_3d += velocity_3d * delta

    var rotation_mod = 1
    if velocity_3d.x < 0:
        rotation_mod = -1
    sprite.rotation_degrees += rotation_velocity * delta * rotation_mod

    if position_3d.z < 0:
        position_3d.z = 0
        velocity_3d.z *= -1
        velocity_3d *= 0.5

    if velocity_3d.length() <= 10: 
        if despawns and despawn_timer.is_stopped():
            despawn_timer.start(despawn_duration)
        # The has_method check is in case the bit is using a static sprite
        if not spin_on_floor and sprite.has_method("stop"):
            sprite.stop()
        rotation_velocity = 0.0

    if use_3d_coordinates:
        position = Vector2(position_3d.x, position_3d.y - position_3d.z)

func _on_despawn_timer_finish():
    queue_free()
