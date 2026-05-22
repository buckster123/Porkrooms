extends Area3D

@export var recharge_amount: float = 50.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		# Find flashlight in scene
		var flashlights = get_tree().get_nodes_in_group("flashlight")
		for fl in flashlights:
			if fl.has_method("recharge"):
				fl.recharge(recharge_amount)
				queue_free()
				return
