extends KinematicBody2D

onready var global = get_node("/root/Global")
onready var player = get_parent().get_node("player")
onready var nav = get_parent().get_node("nav")

onready var sprite = $sprite
onready var collider = $collider
onready var shoot_timer = $shoot_timer

export var MOVE_SPEED = 40
export var STRAFE_RADIUS = 100
export var ATTACK_RADIUS = 150
export var treasure_bomb_frame = -1

var has_treasure_bombed = false

enum State {
    MOVE,
    ATTACK,
    HURT,
    DEATH
}

var state = State.MOVE

var bullet_ready = true
var aim_direction = Vector2.ZERO

var health = 1
var attack_primed = false

func _ready():
    add_to_group("enemies")
    add_to_group("clear_on_death")

    sprite.connect("animation_finished", self, "_on_animation_finished")

func _process(_delta):
    var velocity = Vector2.ZERO

    if state == State.MOVE: 
        aim_direction = position.direction_to(player.predicted_aim_position)

        velocity = position.direction_to(player.position) * MOVE_SPEED

        if player.position.distance_to(position) <= ATTACK_RADIUS:
            attack()

    if state == State.DEATH and sprite.frame == treasure_bomb_frame and not has_treasure_bombed:
        treasure_bomb()

    if state == State.ATTACK:
        if sprite.animation == "attack" and sprite.frame == 3 and position.distance_to(player.position) <= 30:
            player.handle_enemy_bullet()

    var actual_velocity = move_and_slide(velocity)

    update_animation(actual_velocity)

func update_animation(velocity: Vector2):
    if state == State.HURT:
        sprite.play("hurt")
    elif state == State.DEATH:
        sprite.play("death")
    elif state == State.ATTACK:
        sprite.play("attack")
    elif velocity == Vector2.ZERO:
        sprite.play("idle")
    else:
        sprite.play("run")

    if (aim_direction.x > 0 and not sprite.flip_h) or (aim_direction.x < 0 and sprite.flip_h):
        sprite.flip_h = not sprite.flip_h

func _on_animation_finished():
    if sprite.animation == "hurt":
        state = State.MOVE
        if health <= 0:
            start_death()
    elif sprite.animation == "death":
        die()
    elif sprite.animation == "attack":
        state = State.MOVE
        sprite.play("idle")

func handle_player_bullet():
    if state == State.DEATH:
        return

    health -= 1
    sprite.play("hurt")
    state = State.HURT

func start_death():
    state = State.DEATH
    sprite.play("death")
    collider.disabled = true

func die():
    if treasure_bomb_frame == -1:
        treasure_bomb()
    queue_free()

func treasure_bomb():
    if has_treasure_bombed:
        return
    get_parent().spawn_treasure_bomb(position, 3)
    has_treasure_bombed = true

func attack():
    state = State.ATTACK
    attack_primed = true
