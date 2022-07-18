extends Node2D
class_name DungeonRoom

onready var global = get_node("/root/Global")
onready var player = get_node("player")
onready var fader = $fader
onready var coin_scene = preload("res://bits/money/coin.tscn")
onready var dollar_scene = preload("res://bits/money/dollar.tscn")
onready var heart_scene = preload("res://bits/money/heart.tscn")
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
var loot_type = Safe.LootType.COIN_1

func _ready():
	state = State.FADE_IN
	fader.fade_in()

func spawn_treasure_bomb(bomb_position: Vector2, value: int):
	var new_coins = []
	if value == -1:
		new_coins.append(heart_scene.instance())
	else:
		var value_left = value
		while value_left != 0:
			var spawn_dollar = false
			if value_left >= 20:
				spawn_dollar = global.rng.randi_range(0, 3) != 0
			if spawn_dollar:
				new_coins.append(dollar_scene.instance())
				value_left -= 20
			else:
				new_coins.append(coin_scene.instance())
				value_left -= 1
	for new_coin in new_coins:
		var direction = Vector2.DOWN.rotated(deg2rad(global.rng.randi_range(-45, 45)))
		new_coin.set_position_3d(bomb_position + (direction * 10), 0)
		new_coin.set_velocity_3d(direction * 20, 120)
		add_child(new_coin)

func load_next_room(path, with_loot_type):
	loot_type = with_loot_type
	next_room = load(path).instance()

	var current_player = get_node("player")
	var next_player = next_room.get_node("player")
	next_player.health = current_player.health
	next_player.coins = current_player.coins
	next_room.loot_type = with_loot_type

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
		if player.state == player.State.DEAD:
			return
		if exit_door != null and not exit_door.is_open:
			if get_tree().get_nodes_in_group("enemies").size() == 0:
				exit_door.open()
				var safe = get_node("safe")
				if safe != null:
					safe.spawn(loot_type)
