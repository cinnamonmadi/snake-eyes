extends Node2D

onready var global = get_node("/root/Global")
onready var title = preload("res://title/title.tscn")
onready var earned = $earned
onready var total = $total
onready var timer = $timer

var displayed_earned
var displayed_total

func _ready():
    timer.connect("timeout", self, "_on_timeout")
    $money.connect("animation_finished", self, "_animation_finished")

    displayed_earned = global.score
    displayed_total = global.total - global.score
    update_labels()
    timer.start(0.07)
    $money.play()

func _on_timeout():
    displayed_earned -= 1
    displayed_total += 1
    update_labels()
    if displayed_earned == 0:
        end_tally()

func _animation_finished():
    $money.stop()
    $money.frame = 11

func end_tally():
    timer.stop()
    displayed_earned = 0
    displayed_total = global.total
    update_labels()

func update_labels():
    earned.text = "EARNED: " + String(displayed_earned)
    total.text = "TOTAL: " + String(displayed_total)

func _process(_delta):
    if Input.is_action_just_pressed("shoot"):
        if not timer.is_stopped():
            end_tally()
        else:
            get_parent().add_child(title.instance())
            queue_free()
