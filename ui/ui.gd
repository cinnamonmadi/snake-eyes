extends CanvasLayer

onready var player = get_parent().get_node("player")
onready var ammo_label = $ammo_label

var is_reloading = false
var bullet_count = 6
var bullet_max = 6

func _ready():
    pass 

func _process(_delta):
    if player == null:
        return

    if player.bullet_count != bullet_count or player.bullet_max != bullet_max or is_reloading != player.is_reloading():
        bullet_count = player.bullet_count
        bullet_max = player.bullet_max
        is_reloading = player.is_reloading()
        if is_reloading:
            ammo_label.text = "Reloading..."
        else:
            ammo_label.text = String(bullet_count) + " / " + String(bullet_max)
