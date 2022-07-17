extends Node2D

onready var title = preload("res://title/title.tscn")

func _ready():
    var global = get_node("/root/Global")
    $scoreboard/you.text = String("YOU: " + String(global.your_score))
    var scoreboard_texts = [$scoreboard/first, $scoreboard/second, $scoreboard/third]
    for text in scoreboard_texts:
        text.visible = false
    var scoreboard_vals = ["1ST", "2ND", "3RD"]
    for i in range(0, global.high_scores.size()):
        scoreboard_texts[i].text = scoreboard_vals[i] + ": " + String(global.high_scores[global.high_scores.size() - 1 - i])
        scoreboard_texts[i].visible = true

func _process(_delta):
    if Input.is_action_just_pressed("shoot"):
        get_parent().add_child(title.instance())
        queue_free()