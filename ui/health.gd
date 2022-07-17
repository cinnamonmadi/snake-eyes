extends HBoxContainer

onready var player = get_node("../../player")
onready var health_head_scene = preload("res://ui/health_head.tscn")

var player_health: int

func _ready():
    player_health = 0

func _process(_delta):
    while player.health > player_health:
        var new_head = health_head_scene.instance()
        add_child(new_head)
        player_health += 1
    
    if player.health < player_health:
        var dead_lads = player_health - max(player.health, 0)
        for i in range(0, dead_lads):
            var lad_index = get_child_count() - 1 - i
            get_child(lad_index).cya()
            player_health -= 1

    for i in range(0, get_child_count()):
        if i == get_child_count() - 1:
            get_child(i).elder_dying = false
        else:
            get_child(i).elder_dying = get_child(i + 1).sprite.animation == "cya"
