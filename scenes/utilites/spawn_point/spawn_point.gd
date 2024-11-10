@tool
extends Node2D

var _marker_size: float = 32.0
var _marker_color: Color = Color(0, 1, 0, 0.5)
var _spawn_id: String
var _direction: float = 0.0

@export var marker_size: float:
	get:
		return _marker_size
	set(value):
		if _marker_size == value:
			return
		_marker_size = value
		queue_redraw()

@export var marker_color: Color:
	get:
		return _marker_color
	set(value):
		if _marker_color == value:
			return
		_marker_color = value
		queue_redraw()

@export_range(-180, 180) var direction_degrees: float:
	get:
		return rad_to_deg(_direction)
	set(value):
		var new_direction = deg_to_rad(value)
		if _direction == new_direction:
			return
		_direction = new_direction
		queue_redraw()

var spawn_id: String:
	get:
		return _spawn_id

func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
	
	if _spawn_id.is_empty():
		_spawn_id = str(get_instance_id())

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	
	_draw_circle()
	_draw_direction_arrow()

func _draw_circle() -> void:
	var circle_points = PackedVector2Array()
	const SEGMENTS = 32
	
	for i in range(SEGMENTS + 1):
		var angle = i * TAU / SEGMENTS
		var point = Vector2(cos(angle), sin(angle)) * _marker_size * 0.5
		circle_points.push_back(point)
	
	draw_polyline(circle_points, _marker_color, 2.0)

func _draw_direction_arrow() -> void:
	var base_points := [
		Vector2(_marker_size * 0.8, 0),
		Vector2(_marker_size * 0.6, -_marker_size * 0.2),
		Vector2(_marker_size * 0.8, 0),
		Vector2(_marker_size * 0.6, _marker_size * 0.2)
	]
	
	var rotated_arrow := PackedVector2Array()
	
	for point in base_points:
		rotated_arrow.append(_rotate_point(point, _direction))
	
	draw_polyline(rotated_arrow, _marker_color, 2.0)

func _rotate_point(point: Vector2, angle: float) -> Vector2:
	return Vector2(
		point.x * cos(angle) - point.y * sin(angle),
		point.x * sin(angle) + point.y * cos(angle)
	)

func get_spawn_transform() -> Transform2D:
	return Transform2D(_direction, position)
