extends Area2D

onready var global = get_node("/root/Global")
onready var timer = $timer

export(Array, int) var wave_size = []
export var snake_spawn_rate = 0.0
export var armadillo_spawn_rate = 0.0

const SPAWN_SPACE_SIZE = Vector2(16, 16)

var spawn_rects = []
var spawn_scenes = []
var spawn_rates = []
var total_spawn_area = 0
var started = false
var wave_index = -1

func _ready():
    var _return_val = connect("body_entered", self, "_on_body_entered")

    if snake_spawn_rate != 0.0:
        spawn_scenes.append(load("res://enemy/snake/snake.tscn"))
        spawn_rates.append(snake_spawn_rate)
    if armadillo_spawn_rate != 0.0:
        spawn_scenes.append(load("res://enemy/armadillo/armadillo.tscn"))
        spawn_rates.append(armadillo_spawn_rate)

    for child in get_children():
        if child.get_class() != "CollisionShape2D":
            continue
        
        var collider_extents = child.shape.extents
        var collider_rect = Rect2(position + child.position - collider_extents, collider_extents * 2)
        spawn_rects.append(collider_rect)
        total_spawn_area += collider_rect.get_area()

func _on_body_entered(body):
    if body.name == "player" and not started:
        started = true
        begin_next_wave()

func begin_next_wave():
    wave_index += 1
    if wave_index >= wave_size.size():
        return

    for i in range(0, wave_size[wave_index]):
        spawn_enemy()

func generate_spawn_position() -> Vector2:
    var rand_value = global.rng.randi_range(0, total_spawn_area)
    var area_value = 0
    var spawn_rect = null

    for rect in spawn_rects:
        area_value += rect.get_area()
        if rand_value <= area_value:
            spawn_rect = rect
            break
        
    if spawn_rect == null:
        print("Something went wrong! spawn_rect is null")
        return Vector2(0, 0)

    var half = SPAWN_SPACE_SIZE.x / 2
    var spawn_position = Vector2(global.rng.randi_range(spawn_rect.position.x + half, spawn_rect.end.x - half), global.rng.randi_range(spawn_rect.position.y + half, spawn_rect.end.y - half))

    return spawn_position

func spawn_enemy():
    var spawn_value = global.rng.randf_range(0.0, 1.0)
    var spawn_range = 0.0
    var spawned_enemy = null
    for i in range(0, spawn_scenes.size()):
        spawn_range += spawn_rates[i]
        if spawn_value <= spawn_range:
            spawned_enemy = spawn_scenes[i].instance()
            break

    if spawned_enemy == null:
        print("Something went wrong! spawned_enemy is null")
        return

    get_parent().add_child(spawned_enemy)
    spawned_enemy.spawn(generate_spawn_position())

func _process(_delta):
    if started and wave_index < wave_size.size() and get_tree().get_nodes_in_group("enemies").size() == 0:
        begin_next_wave()
