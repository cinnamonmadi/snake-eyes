extends StaticBody2D
class_name Safe

onready var global = get_node("/root/Global")
onready var sprite = $sprite
onready var timer = $timer

onready var break_sound = $break_sound

var health = 3
var piece_scene
export var piece_scene_path = ""
export var piece_variants = 7
export var piece_count = 7
var loot_type

enum LootType {
    COIN_1,
    COIN_2,
    COIN_3,
    COIN_4,
    HEART
}

func _ready():
    add_to_group("clear_on_death")

    visible = false
    $collider.disabled = true
    sprite.stop()

    piece_scene = load(piece_scene_path)
    sprite.connect("animation_finished", self, "_on_animation_finished")
    timer.connect("timeout", self, "_on_timer_timeout")

func spawn(with_loop_type: int):
    loot_type = with_loop_type
    visible = true
    $collider.disabled = false
    timer.start(15.0)
    sprite.play("idle")

func _on_timer_timeout():
    sprite.play("sheen")

func handle_player_bullet():
    if health <= 0:
        return
    health -= 1
    if health == 0:
        break_sound.play()
    sprite.play("hurt")

func _on_animation_finished():
    if sprite.animation == "hurt":
        if health == 0:
            die()
        else:
            sprite.play("idle")
    elif sprite.animation == "death":
        queue_free()

func die():
    for _i in range(0, piece_count):
        var new_piece = piece_scene.instance()
        new_piece.get_node("sprite").frame = global.rng.randi_range(0, piece_variants - 1)
        var piece_direction = Vector2.RIGHT.rotated(deg2rad(global.rng.randi_range(0, 360)))
        new_piece.set_position_3d(position + (piece_direction * 10), 10)
        new_piece.set_velocity_3d(piece_direction * 40, 40)
        new_piece.rotation_speed = 20
        get_parent().add_child(new_piece)

    var value
    if loot_type == LootType.COIN_1:
        value = 10
    elif loot_type == LootType.COIN_2:
        value = 100
    elif loot_type == LootType.COIN_3:
        value = 1000
    elif loot_type == LootType.COIN_4:
        value = 5000
    else:
        value = -1
    get_parent().spawn_treasure_bomb(position, value)
    sprite.play("death")
