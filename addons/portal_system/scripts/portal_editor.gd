@tool
extends Control

@onready var portal_list := $MainContainer/VBoxContainer/PortalSection/PanelContainer/PortalList as ItemList
@onready var scene_path_edit := $MainContainer/VBoxContainer/ConnectionSection/HBoxContainer/ScenePathEdit as LineEdit
@onready var scene_select_button := $MainContainer/VBoxContainer/ConnectionSection/HBoxContainer/SelectSceneButton as Button
@onready var spawn_list := $MainContainer/VBoxContainer/SpawnSection/PanelContainer/SpawnList as ItemList
@onready var connect_button := $MainContainer/VBoxContainer/ButtonSection/ConnectButton as Button
@onready var disconnect_button := $MainContainer/VBoxContainer/ButtonSection/DisconnectButton as Button
@onready var status_label := $MainContainer/VBoxContainer/StatusSection/StatusLabel as Label

const SAVE_PATH := "res://.portal_connections"
const SAVE_DIR := "res://"

const DEFAULT_THEME = preload("res://addons/portal_system/resources/editor_default_theme.tres")

const STATUS_DISPLAY_TIME := 3.0
const DIALOG_SIZE_RATIO := 0.5
const EMPTY_TEXT := ""

const DIALOG_TITLE_DISCONNECT := "Confirm Disconnect"
const DIALOG_TEXT_DISCONNECT := "Are you sure you want to disconnect this portal?"
const SCENE_FILTER := "*.tscn ; Scene Files"

var portal_manager: Node
var selected_portal: Node

func _ready() -> void:
	
	theme = DEFAULT_THEME
	
	_setup_portal_manager()
	_connect_signals()
	_load_editor_state()
	update_portal_list()
	update_ui_state()

func _setup_portal_manager() -> void:
	if is_instance_valid(portal_manager):
		portal_manager.queue_free()
	
	portal_manager = Node.new()
	var script = load("res://addons/portal_system/scripts/portal_manager.gd")
	if not script:
		push_error("Failed to load portal manager script")
		show_status("Failed to initialize portal manager")
		return
		
	portal_manager.set_script(script)
	add_child(portal_manager)

func _connect_signals() -> void:
	portal_manager.connections_updated.connect(_on_connections_updated)
	portal_manager.connection_added.connect(_on_connection_added)
	portal_manager.connection_removed.connect(_on_connection_removed)
	portal_manager.connection_error.connect(_on_connection_error)
	
	scene_select_button.pressed.connect(_on_select_scene_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	portal_list.item_selected.connect(_on_portal_selected)
	spawn_list.item_selected.connect(_on_spawn_selected)

func update_portal_list() -> void:
	portal_list.clear()
	var portals = portal_manager.get_scene_portals()
	
	if portals.is_empty():
		show_status("No portals found in current scene")
		return
		
	for portal in portals:
		portal_list.add_item(portal.portal_id)
	
	update_ui_state()

func update_spawn_list() -> void:
	spawn_list.clear()
	if FileAccess.file_exists(scene_path_edit.text):
		var spawn_points: Array[Node] = portal_manager.get_scene_spawn_points(scene_path_edit.text)
		for spawn in spawn_points:
			spawn_list.add_item(spawn.spawn_id)
	
	update_ui_state()

func update_ui_state() -> void:
	var has_portal := portal_list.get_selected_items().size() > 0
	var has_scene := not scene_path_edit.text.is_empty() and FileAccess.file_exists(scene_path_edit.text)
	var has_spawn := spawn_list.get_selected_items().size() > 0
	
	connect_button.disabled = not (has_portal and has_scene and has_spawn)
	disconnect_button.disabled = not has_portal
	
	spawn_list.mouse_filter = Control.MOUSE_FILTER_IGNORE if not has_scene else Control.MOUSE_FILTER_STOP
	spawn_list.modulate.a = 0.5 if not has_scene else 1.0

func _on_portal_selected(index: int) -> void:
	if not is_instance_valid(portal_manager):
		show_status("Portal manager not initialized")
		return
		
	if index < 0 or index >= portal_manager.get_scene_portals().size():
		return
		
	selected_portal = portal_manager.get_scene_portals()[index]
	var connection = portal_manager.get_portal_connection(selected_portal.portal_id)
	
	if not connection.is_empty():
		scene_path_edit.text = connection.get("scene", EMPTY_TEXT)
		update_spawn_list()
		
		var spawn_id = connection.get("spawn_id", EMPTY_TEXT)
		for i in range(spawn_list.item_count):
			if spawn_list.get_item_text(i) == spawn_id:
				spawn_list.select(i)
				break
	
	update_ui_state()

func _on_spawn_selected(index: int) -> void:
	update_ui_state()

func _on_select_scene_pressed() -> void:
	var dialog = EditorFileDialog.new()
	add_child(dialog)
	
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.filters = [SCENE_FILTER]
	
	# Добавляем обработчик закрытия
	dialog.canceled.connect(func(): dialog.queue_free())
	
	dialog.file_selected.connect(
		func(path: String):
			scene_path_edit.text = path
			update_spawn_list()
			dialog.queue_free()
	)
	
	dialog.popup_centered_ratio(DIALOG_SIZE_RATIO)

func _on_connect_pressed() -> void:
	if not _is_valid_connection():
		show_status("Invalid connection parameters")
		return
		
	var spawn_id = spawn_list.get_item_text(spawn_list.get_selected_items()[0])
	portal_manager.connect_portal(
		selected_portal.portal_id,
		scene_path_edit.text,
		spawn_id
	)

func _on_disconnect_pressed() -> void:
	if not selected_portal:
		return
		
	if not portal_manager.has_portal(selected_portal.portal_id):
		show_status("Portal is not connected")
		return
		
	var dialog = ConfirmationDialog.new()
	dialog.title = DIALOG_TITLE_DISCONNECT
	dialog.dialog_text = DIALOG_TEXT_DISCONNECT
	add_child(dialog)
	
	dialog.confirmed.connect(func():
		portal_manager.disconnect_portal(selected_portal.portal_id)
		_clear_ui()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered()

func _on_connections_updated() -> void:
	update_ui_state()
	show_status("Connections updated")

func _on_connection_added(portal_id: String) -> void:
	show_status("Connection added for portal: " + portal_id)

func _on_connection_removed(portal_id: String) -> void:
	show_status("Connection removed for portal: " + portal_id)

func _on_connection_error(message: String) -> void:
	show_status("Error: " + message)

var _status_timer: SceneTreeTimer

func show_status(text: String) -> void:
	status_label.text = text
	
	if is_instance_valid(_status_timer):
		_status_timer.timeout.disconnect(_clear_status_text)
	
	_status_timer = get_tree().create_timer(STATUS_DISPLAY_TIME)
	_status_timer.timeout.connect(_clear_status_text)

func _is_valid_connection() -> bool:
	return selected_portal != null and \
		   not scene_path_edit.text.is_empty() and \
		   FileAccess.file_exists(scene_path_edit.text) and \
		   not spawn_list.get_selected_items().is_empty()

func _clear_status_text() -> void:
	status_label.text = EMPTY_TEXT
	_status_timer = null

func _exit_tree() -> void:
	_save_editor_state()
	_disconnect_signals()
	if portal_manager:
		portal_manager.queue_free()
		portal_manager = null

func _clear_ui() -> void:
	scene_path_edit.text = EMPTY_TEXT
	spawn_list.clear()
	selected_portal = null
	update_ui_state()

func _save_editor_state() -> void:
	if not portal_manager:
		return
	
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	portal_manager.save_connections(SAVE_PATH)

func _load_editor_state() -> void:
	if not portal_manager:
		return
	portal_manager.load_connections(SAVE_PATH)

func _disconnect_signals() -> void:
	if portal_manager:
		portal_manager.connections_updated.disconnect(_on_connections_updated)
		portal_manager.connection_added.disconnect(_on_connection_added)
		portal_manager.connection_removed.disconnect(_on_connection_removed)
		portal_manager.connection_error.disconnect(_on_connection_error)
	
	scene_select_button.pressed.disconnect(_on_select_scene_pressed)
	connect_button.pressed.disconnect(_on_connect_pressed)
	disconnect_button.pressed.disconnect(_on_disconnect_pressed)
	portal_list.item_selected.disconnect(_on_portal_selected)
	spawn_list.item_selected.disconnect(_on_spawn_selected)
