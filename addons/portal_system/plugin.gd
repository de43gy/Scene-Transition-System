@tool
extends EditorPlugin

const PortalPoint := preload("res://addons/portal_system/scenes/portal_point/portal_point.gd")
var portal_icon: CompressedTexture2D = load("res://addons/portal_system/icons/portal_icon.svg") as CompressedTexture2D

const SpawnPoint := preload("res://addons/portal_system/scenes/spawn_point/spawn_point.gd")
var spawn_icon: CompressedTexture2D = load("res://addons/portal_system/icons/spawn_icon.svg") as CompressedTexture2D

const PortalEditor := preload("res://addons/portal_system/scenes/portal_editor.tscn")

@onready var portal_dock: Control

func _enter_tree() -> void:
	portal_dock = PortalEditor.instantiate()
	
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, portal_dock)
	
	add_custom_type(
		"PortalPoint",
		"Area2D",
		PortalPoint,
		portal_icon
	)
	add_custom_type(
		"SpawnPoint",
		"Node2D",
		SpawnPoint,
		spawn_icon
	)

func _exit_tree() -> void:
	if portal_dock:
		remove_control_from_docks(portal_dock)
		if is_instance_valid(portal_dock):
			portal_dock.queue_free()
	
	remove_custom_type("PortalPoint")
	remove_custom_type("SpawnPoint")
