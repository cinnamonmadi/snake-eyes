extends Node2D
class_name DungeonRoom

onready var global = get_node("/root/Global")
onready var fader = $fader
onready var coin_scene = preload("res://bits/money/coin.tscn")
onready var exit_door = $exit_door

enum State {
	FADE_IN,
	GAMING,
	FADE_OUT,
}

var state

var fade
var next_room
var has_rolled_dice = false

func _ready():
	state = State.FADE_IN
	fader.fade_in()

func spawn_treasure_bomb(bomb_position: Vector2, value: int):
	for _i in range(0, value):
		var new_coin = coin_scene.instance()
		var direction = Vector2.DOWN.rotated(deg2rad(global.rng.randi_range(-45, 45)))
		new_coin.set_position_3d(bomb_position + (direction * 10), 0)
		new_coin.set_velocity_3d(direction * 20, 120)
		add_child(new_coin)

func load_next_room(path):
	next_room = load(path).instance()

	var current_player = get_node("player")
	var next_player = next_room.get_node("player")
	next_player.health = current_player.health
	next_player.coins = current_player.coins

	state = State.FADE_OUT
	fader.fade_out()

func _process(_delta):
	if state == State.FADE_IN:
		if fader.is_finished():
			state = State.GAMING
	elif state == State.FADE_OUT:
		if fader.is_finished():
			get_parent().add_child(next_room)
			queue_free()
	elif state == State.GAMING:
		if exit_door != null and not exit_door.is_open:
			if get_tree().get_nodes_in_group("enemies").size() == 0:
				exit_door.open()
