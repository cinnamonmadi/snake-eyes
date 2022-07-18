extends KinematicBody2D

onready var bullet_scene = preload("res://player/bullet.tscn")
onready var gun_flash_scene = preload("res://player/gun_flash_effect.tscn")
onready var bullet_shell_scene = preload("res://bits/bullet_shell.tscn")

onready var reticle_fine = preload("res://reticle_fine.png")
onready var reticle = preload("res://reticle.png")

onready var entrypoint = get_parent().get_node("player_entrypoint")

onready var sprite = $sprite
onready var gun_sprite = $sprite_gun
onready var camera = $camera
onready var fan_timer = $fan_timer
onready var reload_timer = $reload_timer
onready var iframe_timer = $iframe_timer
onready var iframe_flash_timer = $iframe_flash_timer
onready var shadow = $shadow
onready var spotlight = $spotlight

onready var gun_sound = $gun_sound
onready var reload_sound = $reload_sound

onready var SCREEN_CENTER = get_viewport_rect().size / 2
const CAMERA_OFFSET_MULTIPLIER = 0.5

const MOVE_SPEED = 80
const ROLL_SPEED = 100

const ROLL_DURATION = 0.6

const BULLET_SPAWN_RADIUS = 16
const FAN_DELAY = 0.1
const FAN_MAX_BULLETS = 3
const RELOAD_DURATION = 1.0

const IFRAME_DURATION = 1.0
const IFRAME_FLASH_DURATION = 0.1

enum State {
	ENTER,
	MOVE,
	ROLL,
	FAN,
	DEAD,
	DICE
}

var state = State.ENTER

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
var coins = 0

var sprites_visible = true
var is_hovering_table = false
var is_reloading = false

func _ready():
	Input.set_custom_mouse_cursor(reticle)

	fan_timer.connect("timeout", self, "_on_fan_timer_finish")
	reload_timer.connect("timeout", self, "_on_reload_timer_finish")
	iframe_timer.connect("timeout", self, "_on_iframe_timer_finish")
	iframe_flash_timer.connect("timeout", self, "_on_iframe_flash_timer_finish")
	sprite.connect("animation_finished", self, "_on_animation_finished")
	gun_sprite.connect("animation_finished", self, "_on_gun_animation_finished")
	gun_sprite.play("idle")

func reset_values():
	health = 4
	coins = 0

func _input(event):
	if state == State.DEAD or state == State.DICE:
		return

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

	if state == State.ENTER:
		move_direction = position.direction_to(entrypoint.position)
		aim_direction = move_direction
		return

	if state == State.DICE:
		move_direction = Vector2.ZERO
		return

	if state != State.ROLL:
		move_direction = input_direction
	if state == State.FAN:
		move_direction = Vector2.ZERO

	# Roll start
	if Input.is_action_just_pressed("roll"):
		roll()
	if Input.is_action_just_pressed("reload"):
		reload()
	if Input.is_action_just_pressed("shoot"):
		if is_hovering_table:
			open_dice_prompt()
		else:
			shoot()

func _process(_delta):
	if state == State.DEAD:
		return

	handle_input()

	var speed: int
	if state == State.MOVE:
		speed = MOVE_SPEED
	elif state == State.ROLL:
		speed = ROLL_SPEED
	elif state == State.FAN:
		speed = 0
	elif state == State.ENTER:
		speed = MOVE_SPEED
		if position.distance_to(entrypoint.position) <= 5:
			state = State.MOVE

	var velocity = speed * move_direction
	var actual_velocity = move_and_slide(velocity)

	predicted_position = position + (actual_velocity * 5)
	predicted_aim_position = position + (actual_velocity * 0.5)

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

	sprite.visible = sprites_visible

	if is_reloading and gun_sprite.frame == 4:
		finish_reloading()
	if bullet_ready and not gun_sprite.animation == "reload":
		gun_sprite.play("idle")

	gun_sprite.rotation = aim_direction.angle()
	gun_sprite.flip_v = abs(gun_sprite.rotation_degrees) > 90
	gun_sprite.visible = sprites_visible and state != State.ROLL

func _on_animation_finished():
	if sprite.animation == "roll":
		end_roll()
	elif sprite.animation == "die":
		sprite.play("dead")
		post_death()

func _on_gun_animation_finished():
	if gun_sprite.animation == "shoot":
		gun_sprite.play("idle")
		bullet_ready = true
	elif gun_sprite.animation == "reload":
		gun_sprite.play("idle")

func roll():
	if state == State.MOVE and move_direction != Vector2.ZERO:
		state = State.ROLL
		set_collision_mask_bit(1, false)

func end_roll():
	set_collision_mask_bit(1, true)
	state = State.MOVE

func shoot():
    if bullet_count == 0:
        if state == State.FAN:
            state = State.MOVE
        return
    if is_reloading:
        return
    if state != State.FAN and not bullet_ready:
        return
    if state == State.FAN and fan_bullet_count == FAN_MAX_BULLETS:
        state = State.MOVE
        return

    if state == State.ROLL:
        end_roll()
        state = State.FAN
        fan_bullet_count = 0

    spawn_bullet()
    gun_sound.play()
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
    gun_sprite.play("reload")
    reload_sound.play()
    is_reloading = true

func finish_reloading():
	bullet_ready = true
	bullet_count = bullet_max
	is_reloading = false

func handle_enemy_bullet():
	if has_iframes():
		return
	if state == State.DEAD:
		return
	health -= 1
	iframe_start()
	if health <= 0:
		die()

func die():
	state = State.DEAD
	sprite.play("die")
	gun_sprite.visible = false
	shadow.visible = false
	get_parent().get_node("tilemap").visible = false
	for node in get_tree().get_nodes_in_group("clear_on_death"):
		node.queue_free()
	spotlight.visible = true

func post_death():
	get_parent().get_node("ui").flash_gg()

func iframe_start():
	iframe_timer.start(IFRAME_DURATION)
	iframe_flash_timer.start(IFRAME_FLASH_DURATION)
	sprites_visible = false

func has_iframes():
	return not iframe_timer.is_stopped()

func _on_iframe_timer_finish():
	iframe_flash_timer.stop()
	sprites_visible = true

func _on_iframe_flash_timer_finish():
	sprites_visible = not sprites_visible

func open_dice_prompt():
	state = State.DICE
