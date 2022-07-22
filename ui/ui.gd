extends CanvasLayer

onready var global = get_node("/root/Global")
onready var player = get_parent().get_node("player")
onready var dice_roll_screen = $dice_roll
onready var dice_right_face = $dice_roll/rightface
onready var dice_left_face = $dice_roll/leftface
onready var buttons = $buttons
onready var continue_timer = $continue_timer

var button_exit_tl
var button_exit_br
var button_roll_tl
var button_roll_br
var button_continue_tl
var button_continue_br

var display_gg = false
var continue_countdown = -1

var coins = 0
var coin_icon_ranges = [9, 99, 999, 9999, 99999]

enum DiceFace {
    ARMADILLO_1,
    ARMADILLO_2,
    ARMADILLO_3,
    MONEY_1,
    MONEY_2,
    MONEY_3,
    MONEY_4,
    HEART,
    SNAKE_1,
    SNAKE_2,
    SNAKE_3,
    ARMADILLO_SNAKE,
}

var dice_frame = 0
var dice_right_value
var dice_left_value

func _ready():
    continue_timer.connect("timeout", self, "_on_continue_timeout")
    dice_roll_screen.connect("animation_finished", self, "_on_dice_roll_animation_finished")

    button_exit_tl = $buttons.position + $buttons/exit_button.position + $buttons/exit_button/collider.position - $buttons/exit_button/collider.shape.extents
    button_exit_br = $buttons.position + $buttons/exit_button.position + $buttons/exit_button/collider.position + $buttons/exit_button/collider.shape.extents
    button_roll_tl = $buttons.position + $buttons/roll_button.position + $buttons/roll_button/collider.position - $buttons/roll_button/collider.shape.extents
    button_roll_br = $buttons.position + $buttons/roll_button.position + $buttons/roll_button/collider.position + $buttons/roll_button/collider.shape.extents

    var continue_button_extends = Vector2(96, 20) / 2
    button_continue_tl = $gg.position + $gg/continue.position - continue_button_extends
    button_continue_br = $gg.position + $gg/continue.position + continue_button_extends

func mouse_in_rect(top_left: Vector2, bot_right: Vector2):
    var mouse_pos = get_viewport().get_mouse_position()
    return mouse_pos.x >= top_left.x and mouse_pos.x <= bot_right.x and mouse_pos.y >= top_left.y and mouse_pos.y <= bot_right.y

func _process(delta):
    if player == null:
        return

    if display_gg and $gg.modulate.a < 1.0:
        $gg.modulate.a = min(1.0, $gg.modulate.a + (1.0 * delta))
        if $gg.modulate.a >= 1.0 and continue_countdown == -1:
            continue_countdown = 10
            continue_timer.start(1.0)
            player.reset_values()

    if continue_countdown != -1:
        $gg/continue.visible = true
        $gg/continue/countdown.text = String(continue_countdown)
        if continue_countdown != 0 and Input.is_action_just_pressed("shoot"):
            if mouse_in_rect(button_continue_tl, button_continue_br):
                get_parent().load_next_room("res://levels/level_first.tscn", Safe.LootType.COIN_1)
                continue_countdown = -1
                continue_timer.stop()
        elif continue_countdown == 0:
            var title_scene = load("res://title/title.tscn")
            get_parent().get_parent().add_child(title_scene.instance())
            get_parent().queue_free()

    dice_roll_screen.visible = player.state == player.State.DICE
    buttons.visible = false
    if dice_roll_screen.visible:
        if dice_roll_screen.animation == "default":
            $dice_roll/dialog/Label.percent_visible += 0.3 * delta
            buttons.visible = true
            if Input.is_action_just_pressed("shoot"):
                if mouse_in_rect(button_exit_tl, button_exit_br):
                    player.state = player.State.MOVE
                    dice_roll_screen.visible = false
                    get_parent().open_exit_room()
                elif mouse_in_rect(button_roll_tl, button_roll_br):
                    $dice_roll/dialog.visible = false
                    set_dice_values()
                    dice_roll_screen.play("roll")
                    $dice_roll_sound.play()
        elif dice_roll_screen.animation == "results":
            dice_frame = 3
            if Input.is_action_just_pressed("shoot"):
                player.state = player.State.MOVE
                dice_roll_screen.visible = false
                get_parent().open_next_room(get_next_room(), get_next_loot_type())
        elif dice_roll_screen.animation == "roll":
            if dice_roll_screen.frame == 15:
                dice_frame = 1
            elif dice_roll_screen.frame == 16:
                dice_frame = 2
            elif dice_roll_screen.frame >= 17:
                dice_frame = 3

    dice_right_face.visible = dice_frame != 0
    dice_left_face.visible = dice_right_face.visible
    if dice_right_face.visible:
        dice_right_face.frame_coords = Vector2(dice_frame, dice_left_value)
        dice_left_face.frame_coords = Vector2(dice_frame, dice_right_value)

    if player.coins != coins:
        coins = player.coins
        $coin_purse/label.text = String(coins)
        for i in range(0, coin_icon_ranges.size()):
            if coins <= coin_icon_ranges[i]:
                $coin_purse.frame = i
                break
    var hud_visible = player.state != player.State.DEAD and not dice_roll_screen.visible
    $health.visible = hud_visible
    $reload.visible = hud_visible
    $coin_purse.visible = hud_visible

func _on_dice_roll_animation_finished():
    if dice_roll_screen.animation == "roll":
        dice_roll_screen.play("results")

func flash_gg():
    display_gg = true

func set_dice_values():
    dice_right_value = global.rng.randi_range(0, 6)
    if dice_right_value >= 3:
        dice_right_value = DiceFace.SNAKE_1 + (dice_right_value - 3)
    dice_left_value = global.rng.randi_range(DiceFace.MONEY_1, DiceFace.HEART)

func _on_continue_timeout():
    continue_countdown -= 1
    if continue_countdown != 0:
        continue_timer.start(1.0)

func get_next_loot_type():
    if dice_left_value == DiceFace.MONEY_1:
        return Safe.LootType.COIN_1
    elif dice_left_value == DiceFace.MONEY_2:
        return Safe.LootType.COIN_2
    elif dice_left_value == DiceFace.MONEY_3:
        return Safe.LootType.COIN_3
    elif dice_left_value == DiceFace.MONEY_4:
        return Safe.LootType.COIN_4
    elif dice_left_value == DiceFace.HEART:
        return Safe.LootType.HEART

func get_next_room():
    if [DiceFace.ARMADILLO_1, DiceFace.ARMADILLO_2, DiceFace.ARMADILLO_3].has(dice_right_value):
        return "res://levels/level_3.tscn"
    elif [DiceFace.SNAKE_1, DiceFace.SNAKE_2, DiceFace.SNAKE_3].has(dice_right_value):
        return "res://levels/level_2.tscn"
    else:
        return "res://levels/level_1.tscn"
