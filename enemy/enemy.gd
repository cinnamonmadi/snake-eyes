extends KinematicBody2D

onready var global = get_node("/root/Global")
onready var player = get_parent().get_node("player")
onready var bullet_scene = preload("res://enemy/enemy_bullet.tscn")
var gun_flash_scene = null

onready var sprite = $sprite
onready var gun_sprite = $gun_sprite
onready var shoot_timer = $shoot_timer

const BULLET_SPAWN_RADIUS = 20

export var GUN_FLASH_EFFECT_PATH = ""
export var MOVE_SPEED = 20
export var BULLET_SPEED = 80
export var STRAFE_RADIUS = 100
export var FIRE_RADIUS = 150
export var treasure_bomb_frame = -1

var has_treasure_bombed = false

enum State {
    MOVE,
    HURT,
    DEATH
}

var state = State.MOVE

var bullet_ready = true
var aim_direction = Vector2.ZERO

var health = 3

func _ready():
    add_to_group("enemies")
    add_to_group("clear_on_death")

    sprite.connect("animation_finished", self, "_on_animation_finished")
    gun_sprite.connect("animation_finished", self, "_on_gun_animation_finished")
    gun_sprite.play("idle")

    if GUN_FLASH_EFFECT_PATH != "":
        gun_flash_scene = load(GUN_FLASH_EFFECT_PATH)

func _process(_delta):
    var velocity = Vector2.ZERO

    if state == State.MOVE: 
        aim_direction = position.direction_to(player.predicted_aim_position)
        if player.predicted_position.distance_to(position) > STRAFE_RADIUS:
            velocity = position.direction_to(player.predicted_position) * MOVE_SPEED
        if shoot_timer.is_stopped() and player.position.distance_to(position) <= FIRE_RADIUS:
            shoot()

    if state == State.DEATH and sprite.frame == treasure_bomb_frame and not has_treasure_bombed:
        treasure_bomb()

    var actual_velocity = move_and_slide(velocity)

    update_animation(actual_velocity)

func update_animation(velocity: Vector2):
    if state == State.HURT:
        sprite.play("hurt")
    elif state == State.DEATH:
        sprite.play("death")
    elif velocity == Vector2.ZERO:
        sprite.play("idle")
    else:
        sprite.play("run")

    if (aim_direction.x < 0 and not sprite.flip_h) or (aim_direction.x > 0 and sprite.flip_h):
        sprite.flip_h = not sprite.flip_h

    gun_sprite.rotation = aim_direction.angle()
    gun_sprite.flip_v = abs(gun_sprite.rotation_degrees) > 90
    gun_sprite.visible = state == State.MOVE

func _on_animation_finished():
    if sprite.animation == "hurt":
        state = State.MOVE
        if health <= 0:
            start_death()
    elif sprite.animation == "death":
        die()

func handle_player_bullet():
    if state == State.DEATH:
        return

    health -= 1
    sprite.play("hurt")
    state = State.HURT

func shoot():
    var new_bullet = bullet_scene.instance()
    get_parent().add_child(new_bullet)
    var bullet_direction = aim_direction.rotated(deg2rad(global.rng.randf_range(-10, 10)))
    new_bullet.position = position + (aim_direction * BULLET_SPAWN_RADIUS)
    new_bullet.start(bullet_direction)
    new_bullet.SPEED = BULLET_SPEED

    if gun_flash_scene != null:
        var new_flash = gun_flash_scene.instance()
        add_child(new_flash)
        new_flash.rotation = gun_sprite.rotation
        new_flash.play("default")

    shoot_timer.start(global.rng.randf_range(0.5, 3.0))

func start_death():
    state = State.DEATH
    sprite.play("death")

func die():
    if treasure_bomb_frame == -1:
        treasure_bomb()
    queue_free()

func treasure_bomb():
    if has_treasure_bombed:
        return
    get_parent().spawn_treasure_bomb(position, 3)
    has_treasure_bombed = true
