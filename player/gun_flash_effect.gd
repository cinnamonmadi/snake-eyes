extends AnimatedSprite

func _ready():
    var _return_val = self.connect("animation_finished", self, "_on_animation_finished")

func _on_animation_finished():
    queue_free()