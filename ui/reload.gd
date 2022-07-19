extends Control

onready var player = get_node("../../player")

onready var barrel = $barrel
onready var fire = $fire
onready var bullets = [$bullet_1, $bullet_2, $bullet_3, $bullet_4, $bullet_5, $bullet_6]

var player_bullets = 6

func _ready():
    barrel.connect("animation_finished", self, "_on_barrel_animation_finished")
    player.connect("shoot", self, "_on_player_shoot")
    player.connect("reload", self, "_on_player_reload")
    play_idle()

func _process(_delta):
    if barrel.animation == "fire" and barrel.frame == 0:
        for bullet in bullets:
            bullet.position.y = -2
    elif bullets[0].position.y != 0:
        for bullet in bullets:
            bullet.position.y = 0

func update_displayed_bullets():
    if player_bullets != player.bullet_count:
        player_bullets = player.bullet_count
        for i in range(0, bullets.size()):
            bullets[i].visible = (i + 1) <= player_bullets

func _on_player_shoot():
    play_fire()

func _on_player_reload():
    play_reload()

func play_idle():
    barrel.play("idle")
    fire.play("idle")
    for bullet in bullets:
        bullet.play("idle")

func play_fire():
    if player.state == player.State.FAN and player.fan_bullet_count >= 1:
        update_displayed_bullets()
    barrel.play("fire")
    fire.play("fire")
    bullets[0].play("hidden")
    for bullet_index in range(1, bullets.size()):
        bullets[bullet_index].play("idle")

func play_reload():
    barrel.play("reload")
    fire.play("idle")
    for bullet in bullets:
        bullet.play("hidden")

func play_shaky():
    update_displayed_bullets()
    barrel.play("shaky")
    fire.play("idle")
    for bullet in bullets:
        bullet.play("shaky")

func play_spin():
    barrel.play("spin")
    fire.play("idle")
    for bullet in bullets:
        bullet.play("hidden")

func _on_barrel_animation_finished():
    if barrel.animation == "spin":
        play_shaky()
    elif barrel.animation == "fire" or barrel.animation == "reload":
        play_spin()
    elif barrel.animation == "shaky":
        play_idle()
