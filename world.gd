extends Node2D

onready var global = get_node("/root/Global")
onready var coin_scene = preload("res://bits/money/coin.tscn")

func spawn_treasure_bomb(bomb_position: Vector2, _value: int):
    for _i in range(0, 3):
        var new_coin = coin_scene.instance()
        var direction = Vector2.DOWN.rotated(deg2rad(global.rng.randi_range(-45, 45)))
        new_coin.set_position_3d(bomb_position + (direction * 10), 0)
        new_coin.set_velocity_3d(direction * 20, 120)
        add_child(new_coin)