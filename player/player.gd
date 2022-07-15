extends KinematicBody2D

onready var bullet_scene = preload("res://player/bullet.tscn")
onready var camera = $camera
onready var bullet_timer = $bullet_timer
onready var fan_timer = $fan_timer
onready var reload_timer = $reload_timer

onready var SCREEN_CENTER = get_viewport_rect().size / 2
const CAMERA_OFFSET_MULTIPLIER = 0.1

const MOVE_SPEED = 60
const ROLL_SPEED = 150

const ROLL_DURATION = 0.4

const BULLET_SPAWN_RADIUS = 7
const BULLET_FIRE_DELAY = 0.3
const BULLET_FIRE_FAN_HAMMER_DELAY = 0.1
const FAN_TIMEOUT = 0.3
const RELOAD_DURATION = 1.0

enum State {
    MOVE,
    ROLL,
    FAN
}

var state = State.MOVE

var input_direction = Vector2.ZERO
var move_direction = Vector2.ZERO
var aim_direction = Vector2.ZERO

var bullet_ready = true
var bullet_fan_ready = false
var bullet_fanning = false
var bullet_count = 6
var bullet_max = 6

var anim_timer: float = 0.0

func _ready():
    bullet_timer.connect("timeout", self, "_on_bullet_timer_finish")
    fan_timer.connect("timeout", self, "_on_fan_timer_finish")
    reload_timer.connect("timeout", self, "_on_reload_timer_finish")

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
    move_direction = input_direction

    # Roll start
    if Input.is_action_just_pressed("roll"):
        roll()

    if Input.is_action_just_pressed("shoot"):
        shoot()

func _process(delta):
    handle_input()

    var speed: int
    if state == State.MOVE:
        speed = MOVE_SPEED
        $ColorRect.color = Color(1, 1, 1, 1)
    elif state == State.ROLL:
        anim_timer -= delta
        if anim_timer <= 0:
            state = State.FAN
            fan_timer.start(FAN_TIMEOUT)
            set_collision_mask_bit(1, true)
        speed = ROLL_SPEED
    elif state == State.FAN:
        $ColorRect.color = Color(1, 0, 0, 1)

    var velocity = speed * move_direction
    var _actual_velocity = move_and_slide(velocity)

func roll():
    if state == State.MOVE:
        anim_timer = ROLL_DURATION
        state = State.ROLL
        set_collision_mask_bit(1, false)

func shoot():
    if state == State.ROLL:
        return
    if not bullet_ready:
        return 
    if bullet_count == 0:
        return
    if is_reloading():
        return

    spawn_bullet()
    bullet_ready = false
    var delay = BULLET_FIRE_DELAY
    if state == State.FAN:
        delay = BULLET_FIRE_FAN_HAMMER_DELAY
        fan_timer.start(FAN_TIMEOUT)
    bullet_timer.start(delay)

    bullet_count -= 1
    if bullet_count == 0:
        reload()

func spawn_bullet():
    var new_bullet = bullet_scene.instance()
    get_parent().add_child(new_bullet)
    new_bullet.position = position + (aim_direction * BULLET_SPAWN_RADIUS)
    new_bullet.start(aim_direction)

func _on_bullet_timer_finish():
    bullet_ready = true

func _on_fan_timer_finish():
    state = State.MOVE

func reload():
    reload_timer.start(RELOAD_DURATION)

func is_reloading():
    return not reload_timer.is_stopped()

func _on_reload_timer_finish():
    bullet_count = bullet_max
