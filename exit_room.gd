extends DungeonRoom

onready var table = $table
onready var table_outline = $table/outline
onready var table_collider = $table/collider
onready var door_next = $door_next
onready var door_exit = $door_exit

var table_top_left: Vector2
var table_bot_right: Vector2
var decision_made = false

func _ready():
    table_top_left = position + table.position + table_collider.position - table_collider.shape.extents
    table_bot_right = position + table.position + table_collider.position + table_collider.shape.extents

func _process(_delta):
    table_outline.visible = false

    if not decision_made:
        var mouse_pos = get_global_mouse_position()
        if (position + table.position).distance_to(player.position) <= 100:
            if mouse_pos.x >= table_top_left.x and mouse_pos.x <= table_bot_right.x and mouse_pos.y >= table_top_left.y and mouse_pos.y <= table_bot_right.y:
                table_outline.visible = true

    player.is_hovering_table = table_outline.visible

func open_next_room(next_room_path: String, loot_type: int):
    door_next.open()
    door_next.next_room_path = next_room_path
    door_next.next_room_loot_type = loot_type
    decision_made = true

func open_exit_room():
    door_exit.open()
    decision_made = true
