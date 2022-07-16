extends StaticBody2D

onready var global = get_node("/root/Global")
onready var sprite = $sprite

var health = 3
var piece_scene
export var piece_scene_path = ""
export var piece_variants = 7
export var piece_count = 7

func _ready():
    piece_scene = load(piece_scene_path)
    sprite.connect("animation_finished", self, "_on_animation_finished")
    sprite.play("idle")

func handle_player_bullet():
    health -= 1
    sprite.play("hurt")

func _on_animation_finished():
    if sprite.animation == "hurt":
        if health == 0:
            die()
        else:
            sprite.play("idle")

func die():
    for _i in range(0, piece_count):
        var new_piece = piece_scene.instance()
        new_piece.get_node("sprite").frame = global.rng.randi_range(0, piece_variants - 1)
        var piece_direction = Vector2.RIGHT.rotated(deg2rad(global.rng.randi_range(0, 360)))
        new_piece.set_position_3d(position + (piece_direction * 10), 10)
        new_piece.set_velocity_3d(piece_direction * 40, 40)
        new_piece.rotation_speed = 20
        get_parent().add_child(new_piece)

    queue_free()
