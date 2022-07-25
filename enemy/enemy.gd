extends KinematicBody2D
class_name Enemy

onready var global = get_node("/root/Global")
onready var nav = get_parent().get_node("nav")
onready var player = get_parent().get_node("player")
onready var bullet_scene = preload("res://enemy/enemy_bullet.tscn")
var gun_flash_scene = null

onready var sprite = $sprite
onready var collider = $collider
onready var gun_sprite = $gun_sprite
onready var shoot_timer = $shoot_timer
onready var death_sound = $death_sound
onready var fire_sound = $fire_sound

const BULLET_SPAWN_RADIUS = 20

var GUN_FLASH_EFFECT_PATH = ""
var MOVE_SPEED = 20
var MAX_HEALTH = 3

var USE_STRAFE_RADIUS = true
var USE_PREDICTED_POSITION = true
var STRAFE_RADIUS = 100
var USE_PURSUIT_RADIUS = true
var PURSUIT_RADIUS = 200
var ATTACK_RADIUS = 30

var FIRE_RADIUS = 150
var BULLET_SPEED = 80

var TREASURE_BOMB_FRAME = -1
var ATTACK_HURT_FRAME = 3

enum SpriteOrientation {
    RIGHT,
    LEFT
}
export(SpriteOrientation) var SPRITE_ORIENTATION = SpriteOrientation.RIGHT

enum State {
    MOVE,
    ATTACK,
    HURT,
    DEATH
}

var state = State.MOVE

var has_treasure_bombed = false
var has_gun = false
var has_found_player = false
var attack_primed = false

var bullet_ready = true
var aim_direction = Vector2.ZERO

var health = 3

var path = []

func _ready():
    add_to_group("enemies")
    add_to_group("clear_on_death")

    if gun_sprite != null:
        has_gun = true

    sprite.connect("animation_finished", self, "_on_animation_finished")
    if has_gun:
        gun_sprite.connect("animation_finished", self, "_on_gun_animation_finished")
        gun_sprite.play("idle")

    if has_gun and GUN_FLASH_EFFECT_PATH != "":
        gun_flash_scene = load(GUN_FLASH_EFFECT_PATH)

    if not USE_PURSUIT_RADIUS:
        has_found_player = true

    health = MAX_HEALTH

func _process(delta):
    if player == null:
        player = get_parent().get_node("player")
        return

    var velocity = Vector2.ZERO
    $Line2D.global_position = Vector2.ZERO

    if state == State.MOVE: 
        aim_direction = position.direction_to(player.predicted_aim_position)

        # Search for the player if they haven't found them already
        # Could possibly use a raycast search for enemies positioned in adjacent rooms
        # Or do a room-by-room player detection
        if not has_found_player:
            if position.distance_to(player.position) <= PURSUIT_RADIUS:
                has_found_player = true

        if has_found_player:
            # Move toward the player
            if not USE_STRAFE_RADIUS or player.predicted_position.distance_to(position) > STRAFE_RADIUS:
                var target_position = player.position
                if USE_PREDICTED_POSITION:
                    target_position = player.predicted_position

                var immediate_target = target_position

                # Try pathfinding, otherwise just go to target_position
                path = nav.get_simple_path(position, target_position, false)
                $Line2D.points = path
                while path.size() != 0 and position.distance_to(path[0]) <= 16:
                    path.remove(0)
                if path.size() != 0:
                    immediate_target = path[0]
                    immediate_target = Vector2((int(immediate_target.x / 16.0) * 16) + 8, (int(immediate_target.y / 16.0) * 16) + 8)

                velocity = position.direction_to(immediate_target) * MOVE_SPEED
                # For melee enemies, attack if in range
                if not has_gun and player.position.distance_to(position) <= ATTACK_RADIUS:
                    attack()
        # For ranged enemies, attack if range and gun ready
        if has_gun and shoot_timer.is_stopped() and gun_sprite.animation == "idle" and player.position.distance_to(position) <= FIRE_RADIUS:
            shoot()

    # If dying, spawn treasure bomb on the correct frame
    if state == State.DEATH and sprite.frame == TREASURE_BOMB_FRAME and not has_treasure_bombed:
        treasure_bomb()

    # If attacking, damage player on the correct frame if they're close enough
    if state == State.ATTACK:
        if sprite.animation == "attack" and sprite.frame == ATTACK_HURT_FRAME and position.distance_to(player.position) <= 30:
            player.handle_enemy_bullet()

    # Move according to velocity
    var actual_velocity = move_and_slide(velocity)

    update_animation(actual_velocity)

func update_animation(velocity: Vector2):
    # Set which animation to play
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

    # Flip sprite based on aim direction
    if SPRITE_ORIENTATION == SpriteOrientation.RIGHT:
        if (aim_direction.x < 0 and not sprite.flip_h) or (aim_direction.x > 0 and sprite.flip_h):
            sprite.flip_h = not sprite.flip_h
    elif SPRITE_ORIENTATION == SpriteOrientation.LEFT:
        if (aim_direction.x > 0 and not sprite.flip_h) or (aim_direction.x < 0 and sprite.flip_h):
            sprite.flip_h = not sprite.flip_h

    # Update gun sprite
    if has_gun:
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
    elif sprite.animation == "attack":
        state = State.MOVE
        sprite.play("idle")

func _on_gun_animation_finished():
    if gun_sprite.animation == "shoot":
        gun_sprite.play("idle")
        shoot_timer.start(global.rng.randf_range(0.5, 3.0))

func handle_player_bullet():
    if state == State.DEATH:
        return

    health -= 1
    if health == 0:
        death_sound.play()
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

    gun_sprite.play("shoot")
    fire_sound.play()

func start_death():
    state = State.DEATH
    sprite.play("death")
    collider.disabled = true

func die():
    if TREASURE_BOMB_FRAME == -1:
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
