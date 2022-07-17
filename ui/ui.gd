extends CanvasLayer

onready var player = get_parent().get_node("player")
onready var ammo_label = $ammo_label
onready var dice_roll_screen = $dice_roll
onready var buttons = $buttons

var is_reloading = false
var bullet_count = 6
var bullet_max = 6

var button_exit_tl
var button_exit_br
var button_roll_tl
var button_roll_br

var display_gg = false

func _ready():
    dice_roll_screen.connect("animation_finished", self, "_on_dice_roll_animation_finished")

    button_exit_tl = $buttons.position + $buttons/exit_button.position + $buttons/exit_button/collider.position - $buttons/exit_button/collider.shape.extents
    button_exit_br = $buttons.position + $buttons/exit_button.position + $buttons/exit_button/collider.position + $buttons/exit_button/collider.shape.extents
    button_roll_tl = $buttons.position + $buttons/roll_button.position + $buttons/roll_button/collider.position - $buttons/roll_button/collider.shape.extents
    button_roll_br = $buttons.position + $buttons/roll_button.position + $buttons/roll_button/collider.position + $buttons/roll_button/collider.shape.extents

func mouse_in_rect(top_left: Vector2, bot_right: Vector2):
    var mouse_pos = get_viewport().get_mouse_position()
    return mouse_pos.x >= top_left.x and mouse_pos.x <= bot_right.x and mouse_pos.y >= top_left.y and mouse_pos.y <= bot_right.y

func _process(delta):
    if player == null:
        return

    if display_gg and $gg.modulate.a < 1.0:
        $gg.modulate.a = min(1.0, $gg.modulate.a + (1.0 * delta))

    dice_roll_screen.visible = player.state == player.State.DICE
    buttons.visible = false
    if dice_roll_screen.visible:
        if dice_roll_screen.animation == "default":
            buttons.visible = true
            if Input.is_action_just_pressed("shoot"):
                if mouse_in_rect(button_exit_tl, button_exit_br):
                    player.state = player.State.MOVE
                    dice_roll_screen.visible = false
                    get_parent().open_exit_room()
                elif mouse_in_rect(button_roll_tl, button_roll_br):
                    dice_roll_screen.play("roll")
        elif dice_roll_screen.animation == "results":
            if Input.is_action_just_pressed("shoot"):
                player.state = player.State.MOVE
                dice_roll_screen.visible = false
                get_parent().open_next_room("res://world.tscn")

    if player.bullet_count != bullet_count or player.bullet_max != bullet_max or is_reloading != player.is_reloading():
        bullet_count = player.bullet_count
        bullet_max = player.bullet_max
        is_reloading = player.is_reloading()
        if is_reloading:
            ammo_label.text = "Reloading..."
        else:
            ammo_label.text = String(bullet_count) + " / " + String(bullet_max)
    ammo_label.visible = player.state != player.State.DEAD

func _on_dice_roll_animation_finished():
    if dice_roll_screen.animation == "roll":
        dice_roll_screen.play("results")

func flash_gg():
    display_gg = true
