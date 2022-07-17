extends StaticBody2D

onready var sprite = $sprite
onready var collider = $collider
onready var player_scan_area = $player_scan_area

export var next_room_path = "res://exit_room.tscn"

var is_open = false

func _ready():
    sprite.connect("animation_finished", self, "_on_animation_finished")
    player_scan_area.connect("body_entered", self, "_on_body_entered")

func open():
    if sprite.animation == "closed":
        sprite.play("open")

func close():
    if sprite.animation == "opened":
        sprite.play("close")

func _process(_delta):
    if sprite.animation == "open" and sprite.frame == 2:
        is_open = true
    if sprite.animation == "closed" and sprite.frame == 2:
        is_open = false

func _on_animation_finished():
    if sprite.animation == "open":
        sprite.play("opened")
    elif sprite.animation == "close":
        sprite.play("closed")

func _on_body_entered(body):
    if not is_open or body.name != "player":
        return
    get_parent().load_next_room(next_room_path)