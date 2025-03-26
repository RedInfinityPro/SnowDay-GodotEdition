extends Camera3D
var zoom_speed := 2.5
var zoom_margin := 1.5
var zoom_min := 1.0
var zoom_max := 7.5
var zoom_factor := 5.0

func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().size
	var viewport_size_new = Vector2(viewport_size.x, viewport_size.y)
	var normalized_mouse_pos = (mouse_pos / viewport_size_new) * 2.0 - Vector2(1.0, 1.0) # Normalize to [-1,1]
	# Move camera towards mouse position
	var move_offset = Vector3(normalized_mouse_pos.x, 0, normalized_mouse_pos.y) * zoom_margin * zoom_factor
	global_transform.origin = global_transform.origin.lerp(global_transform.origin + move_offset, zoom_speed * delta)
	# Apply zoom
	var zoom_amount = lerp(1.0, zoom_factor, zoom_speed * delta)
	zoom_amount = clamp(zoom_amount, zoom_min, zoom_max)
	
	var basis = global_transform.basis
	basis = basis.scaled(Vector3(zoom_amount, zoom_amount, zoom_amount))
	global_transform.basis = basis

func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_factor -= 1.0
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_factor += 1.0
			zoom_factor = clamp(zoom_factor, zoom_min, zoom_max)
