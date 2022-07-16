extends CanvasLayer

onready var player = get_parent().get_node("player")
onready var ammo_label = $ammo_label
onready var dice_roll_screen = $dice_roll

var is_reloading = false
var bullet_count = 6
var bullet_max = 6

func _ready():
    dice_roll_screen.connect("animation_finished", self, "_on_dice_roll_animation_finished")

func _process(_delta):
    if player == null:
        return

    dice_roll_screen.visible = player.state == player.State.DICE
    if dice_roll_screen.visible:
        if Input.is_action_just_pressed("shoot"):
            if not player.has_rolled_dice:
                player.has_rolled_dice = true
                dice_roll_screen.play()
            elif not dice_roll_screen.is_playing():
                dice_roll_screen.visible = false
                player.state = player.State.MOVE
                get_parent().load_next_room("res://world.tscn")

    if player.bullet_count != bullet_count or player.bullet_max != bullet_max or is_reloading != player.is_reloading():
        bullet_count = player.bullet_count
        bullet_max = player.bullet_max
        is_reloading = player.is_reloading()
        if is_reloading:
            ammo_label.text = "Reloading..."
        else:
            ammo_label.text = String(bullet_count) + " / " + String(bullet_max)

func _on_dice_roll_animation_finished():
    dice_roll_screen.stop()
    dice_roll_screen.frame = 25
