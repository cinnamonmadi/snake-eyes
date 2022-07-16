extends KinematicBody2D

onready var bullet_scene = preload("res://player/bullet.tscn")
onready var gun_flash_scene = preload("res://player/gun_flash_effect.tscn")
onready var bullet_shell_scene = preload("res://bits/bullet_shell.tscn")

onready var sprite = $sprite
onready var gun_sprite = $sprite_gun
onready var camera = $camera
onready var fan_timer = $fan_timer
onready var reload_timer = $reload_timer

onready var SCREEN_CENTER = get_viewport_rect().size / 2
const CAMERA_OFFSET_MULTIPLIER = 0.5

const MOVE_SPEED = 60
const ROLL_SPEED = 220

const ROLL_DURATION = 0.6

const BULLET_SPAWN_RADIUS = 16
const FAN_DELAY = 0.1
const FAN_MAX_BULLETS = 3
const RELOAD_DURATION = 1.0

enum State {
    MOVE,
    ROLL,
    FAN
}

var state = State.MOVE

var predicted_position = position
var predicted_aim_position = position

var input_direction = Vector2.ZERO
var move_direction = Vector2.ZERO
var aim_direction = Vector2.ZERO

var bullet_ready = true
var bullet_fan_ready = false
var bullet_fanning = false
var bullet_count = 6
var bullet_max = 6
var fan_bullet_count = 0

var health = 4

func _ready():
    fan_timer.connect("timeout", self, "_on_fan_timer_finish")
    reload_timer.connect("timeout", self, "_on_reload_timer_finish")
    sprite.connect("animation_finished", self, "_on_animation_finished")
    gun_sprite.connect("animation_finished", self, "_on_gun_animation_finished")
    gun_sprite.play("idle")

func _input(event):
    if event is InputEventMouseMotion:
        var mouse_offset = event.position - SCREEN_CENTER
        aim_direction = mouse_offset.normalized()
        camera.offset = mouse_offset * CAMERA_OFFSET_MULTIPLIER

func handle_directional_input():
    if Input.is_action_just_pressed("up"):
        input_direction.y = -1
    if Input.is_action_just_pressed("right"):
        input_direction.x = 1
    if Input.is_action_just_pressed("down"):
        input_direction.y = 1
    if Input.is_action_just_pressed("left"):
        input_direction.x = -1

    if Input.is_action_just_released("up"):
        if Input.is_action_pressed("down"):
            input_direction.y = 1
        else:
            input_direction.y = 0
    if Input.is_action_just_released("right"):
        if Input.is_action_pressed("left"):
            input_direction.x = -1
        else:
            input_direction.x = 0
    if Input.is_action_just_released("down"):
        if Input.is_action_pressed("up"):
            input_direction.y = -1
        else:
            input_direction.y = 0
    if Input.is_action_just_released("left"):
        if Input.is_action_pressed("right"):
            input_direction.x = 1
        else:
            input_direction.x = 0

func handle_input():
    handle_directional_input()
    if state != State.ROLL:
        move_direction = input_direction
    if state == State.FAN and move_direction != Vector2.ZERO:
        state = State.MOVE

    # Roll start
    if Input.is_action_just_pressed("roll"):
        roll()
    if Input.is_action_just_pressed("reload"):
        reload()
    if Input.is_action_just_pressed("shoot"):
        shoot()


func _process(_delta):
    handle_input()

    var speed: int
    if state == State.MOVE:
        speed = MOVE_SPEED
    elif state == State.ROLL:
        speed = ROLL_SPEED
    elif state == State.FAN:
        speed = 0

    var velocity = speed * move_direction
    var actual_velocity = move_and_slide(velocity)

    predicted_position = position + (actual_velocity * 5)
    predicted_aim_position = position + (actual_velocity * 0.5)
    $ColorRect.rect_position = predicted_position - position

    update_animation(actual_velocity)

func update_animation(velocity: Vector2):
    if state == State.ROLL:
        sprite.play("roll")
    elif velocity == Vector2.ZERO:
        sprite.play("idle")
    else:
        sprite.play("run")

    if state == State.ROLL:
        if (move_direction.x < 0 and not sprite.flip_h) or (move_direction.x > 0 and sprite.flip_h):
            sprite.flip_h = not sprite.flip_h
    else: 
        if (aim_direction.x < 0 and not sprite.flip_h) or (aim_direction.x > 0 and sprite.flip_h):
            sprite.flip_h = not sprite.flip_h

    if bullet_ready:
        gun_sprite.play("idle")

    gun_sprite.rotation = aim_direction.angle()
    gun_sprite.flip_v = abs(gun_sprite.rotation_degrees) > 90
    gun_sprite.visible = state != State.ROLL

func _on_animation_finished():
    if sprite.animation == "roll":
        end_roll()

func _on_gun_animation_finished():
    if gun_sprite.animation == "shoot":
        gun_sprite.play("idle")
        bullet_ready = true

func roll():
    if state == State.MOVE and move_direction != Vector2.ZERO:
        state = State.ROLL
        set_collision_mask_bit(1, false)

func end_roll():
    set_collision_mask_bit(1, true)
    state = State.MOVE

func shoot():
    if bullet_count == 0:
        return
    if is_reloading():
        return
    if state != State.FAN and not bullet_ready:
        return
    if state == State.FAN and fan_bullet_count == FAN_MAX_BULLETS:
        return

    if state == State.ROLL:
        state = State.FAN
        fan_bullet_count = 0

    spawn_bullet()
    bullet_ready = false
    if state == State.FAN:
        fan_bullet_count += 1
        if bullet_count == 0 or fan_bullet_count == FAN_MAX_BULLETS:
            state = State.MOVE
        else:
            fan_timer.start(FAN_DELAY)
    gun_sprite.play("shoot")
    gun_sprite.frame = 0

    bullet_count -= 1
    if bullet_count == 0:
        reload()

func spawn_bullet():
    var new_bullet = bullet_scene.instance()
    get_parent().add_child(new_bullet)
    new_bullet.position = position + (aim_direction * BULLET_SPAWN_RADIUS)
    new_bullet.start(aim_direction)

    var new_flash = gun_flash_scene.instance()
    add_child(new_flash)
    new_flash.rotation = gun_sprite.rotation
    new_flash.play("default")

    var new_shell = bullet_shell_scene.instance()
    get_parent().add_child(new_shell)
    new_shell.set_position_3d(position + (aim_direction * BULLET_SPAWN_RADIUS), 20)
    new_shell.set_velocity_3d(aim_direction.rotated(deg2rad(180)) * 70, 120)

func _on_bullet_timer_finish():
    bullet_ready = true

func _on_fan_timer_finish():
    shoot()

func reload():
    reload_timer.start(RELOAD_DURATION)

func is_reloading():
    return not reload_timer.is_stopped()

func _on_reload_timer_finish():
    bullet_count = bullet_max

func handle_enemy_bullet():
    health -= 1
    if health <= 0:
        queue_free()
