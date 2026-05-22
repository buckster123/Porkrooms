extends Node

signal collect(item: ItemResource)
signal update_item(item: ItemResource)
signal add_new_item(item: ItemResource)
signal item_removed()

var items: Dictionary = {}
var player: Node

func display_interaction_info(text: String):
	if player and player.has_method("display_interaction_info"):
		player.display_interaction_info(text)

func _ready():
	collect.connect(add_item)

func add_item(item: ItemResource):
	var existing = items.get(item.item_name)
	if existing:
		existing.quantity += item.quantity
		update_item.emit(existing)
		return
	items[item.item_name] = item.duplicate()
	add_new_item.emit(item)

func get_item(item_name: String) -> ItemResource:
	return items.get(item_name)

func remove_item(item_name: String, quantity: int = 0):
	if quantity == 0:
		items.erase(item_name)
	else:
		var item = items.get(item_name)
		if item:
			item.quantity -= quantity
			if item.quantity <= 0:
				items.erase(item_name)
	item_removed.emit()
