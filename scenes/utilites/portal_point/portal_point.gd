@tool
extends Area2D

var _arrow_size: float = 32.0
var _arrow_color: Color = Color(1, 0, 1, 0.5)
var _portal_id: String = ""

@export var arrow_size: float:
	get:
		return _arrow_size
	set(value):
		if _arrow_size == value:
			return
		_arrow_size = value
		_update_shape()
		queue_redraw()

@export var arrow_color: Color:
	get:
		return _arrow_color
	set(value):
		if _arrow_color == value:
			return
		_arrow_color = value
		queue_redraw()

var portal_id: String:
	get:
		return _portal_id

func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
	
	if portal_id.is_empty():
		portal_id = str(get_instance_id())
	
	body_entered.connect(on_body_entered)
	
	_update_shape()

func  _update_shape() -> void:
	if has_node("CollisionShape2D"):
		var shape := get_node("CollisionShape2D") as CollisionShape2D
		if shape:
			var rect := shape.shape as RectangleShape2D
			if rect:
				rect.size = Vector2(_arrow_size, _arrow_size * 2)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	
	var points = PackedVector2Array([
		Vector2(-arrow_size/2, -arrow_size/2),
		Vector2(arrow_size/2, 0),
		Vector2(-arrow_size/2, arrow_size/2),
		Vector2(-arrow_size/2, -arrow_size/2)
	])
	
	draw_colored_polygon(points, arrow_color)

func on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	print("Player entered portal: ", portal_id)

# TODO: Add portal transition logic
