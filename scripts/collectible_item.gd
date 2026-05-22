extends InteractionBase
class_name CollectibleItem

@export var item: ItemResource

func interact(_parameters=null):
	Inventory.collect.emit(item)
	on_collect()
	queue_free()

func on_collect():
	pass
