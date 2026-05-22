extends StaticBody3D
class_name InteractionBase

func interact(_parameters=null):
	pass

func is_player_in_front(player, object) -> bool:
	var player_to_object: Vector3 = (object.position - player.position).normalized()
	var forward: Vector3 = player.global_transform.basis.x
	return player_to_object.dot(forward) > 0
