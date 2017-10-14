extends TileMap

func _ready():
	pass


func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			print('MOUSE_POS:',  world_to_map(get_global_mouse_position()) + Vector2(1,-1) )