@tool
extends Node

const PORTAL_TYPE := "PortalPoint"
const SPAWN_TYPE := "SpawnPoint"

const DEFAULT_CONNECTION := {
	"scene": "",
	"spawn_id": ""
}

var portal_connections: Dictionary = {}:
	set(value):
		portal_connections = value
		connections_updated.emit()

signal connections_updated
signal connection_added(portal_id: String)
signal connection_removed(portal_id: String)
signal connection_error(message: String)

func connect_portal(portal_id: String, target_scene: String, spawn_id: String) -> bool:
	if portal_id.is_empty() or target_scene.is_empty() or spawn_id.is_empty():
		connection_error.emit("Invalid connection parameters")
		return false
	
	if not validate_connections(portal_id, target_scene, spawn_id):
		return false
	
	portal_connections[portal_id] = {
		"scene": target_scene,
		"spawn_id": spawn_id
	}
	
	connection_added.emit(portal_id)
	connections_updated.emit()
	return true

func disconnect_portal(portal_id: String) -> bool:
	if not portal_connections.has(portal_id):
		connection_error.emit("Portal not found: " + portal_id)
		return false
		
	portal_connections.erase(portal_id)
	connection_removed.emit(portal_id)
	connections_updated.emit()
	return true

func get_portal_connection(portal_id: String) -> Dictionary:
	return portal_connections.get(portal_id, DEFAULT_CONNECTION.duplicate())

func get_scene_portals() -> Array[Node]:
	var portals: Array[Node] = []
	var scene_root := EditorInterface.get_edited_scene_root()
	
	if scene_root:
		_find_nodes_of_type(scene_root, PORTAL_TYPE, portals)
	
	return portals

func get_scene_spawn_points(scene_path: String) -> Array[Node]:
	var spawn_points: Array[Node] = []
	
	if scene_path.is_empty():
		connection_error.emit("Invalid scene path")
		return spawn_points
	
	if not FileAccess.file_exists(scene_path):
		connection_error.emit("Scene file not found: " + scene_path)
		return spawn_points
	
	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		connection_error.emit("Failed to load scene: " + scene_path)
		return spawn_points
	
	var scene_instance := packed_scene.instantiate()
	_find_nodes_of_type(scene_instance, SPAWN_TYPE, spawn_points)
	
	if is_instance_valid(scene_instance):
		scene_instance.queue_free()
		
	return spawn_points

func _find_nodes_of_type(node: Node, type: String, result: Array[Node]) -> void:
	if node.is_class(type):
		result.append(node)
	
	for child in node.get_children():
		_find_nodes_of_type(child, type, result)

func has_portal(portal_id: String) -> bool:
	return portal_connections.has(portal_id)

func get_all_connections() -> Dictionary:
	return portal_connections.duplicate()

func clear_connections() -> void:
	portal_connections.clear()
	connections_updated.emit()

func validate_connections(portal_id: String, target_scene: String, spawn_id: String) -> bool:
	var portals := get_scene_portals()
	var portal_exists := false
	
	for portal in portals:
		if portal.portal_id == portal_id:
			portal_exists = true
			break
	
	if not portal_exists:
		connection_error.emit("Portal not found in scene: " + portal_id)
		return false
	
	if not FileAccess.file_exists(target_scene):
		connection_error.emit("Target scene not found: " + target_scene)
		return false
	
	var spawn_points := get_scene_spawn_points(target_scene)
	var spawn_exists := false
	
	for spawn in spawn_points:
		if spawn.spawn_id == spawn_id:
			spawn_exists = true
			break
	
	if not spawn_exists:
		connection_error.emit("Spawn point not found in target scene: " + spawn_id)
		return false
	
	return true

func save_connections(path: String) -> bool:
	if path.is_empty():
		connection_error.emit("Invalid save path")
		return false
		
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		connection_error.emit("Failed to save connections")
		return false
	
	var json := JSON.new()
	var data := JSON.stringify(portal_connections)
	file.store_string(data)
	return true

func load_connections(path: String) -> bool:
	if not FileAccess.file_exists(path):
		connection_error.emit("Connections file not found")
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		connection_error.emit("Failed to load connections")
		return false
	
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	if parse_result != OK:
		connection_error.emit("Failed to parse connections file")
		return false
	
	portal_connections = json.get_data()
	var loaded_data = json.get_data()
	if not loaded_data is Dictionary:
		connection_error.emit("Invalid connections file format")
		return false
	
	portal_connections = loaded_data
	connections_updated.emit()
	return true

func update_connection(portal_id: String, new_scene: String = "", new_spawn_id: String = "") -> bool:
	if not portal_connections.has(portal_id):
		connection_error.emit("Portal not found: " + portal_id)
		return false
	
	if not new_scene.is_empty():
		if not FileAccess.file_exists(new_scene):
			connection_error.emit("New scene file not found: " + new_scene)
			return false
	
	var updated_connection := {
		"scene": portal_connections[portal_id]["scene"],
		"spawn_id": portal_connections[portal_id]["spawn_id"]
	}
	
	if not new_scene.is_empty():
		updated_connection["scene"] = new_scene
	if not new_spawn_id.is_empty():
		updated_connection["spawn_id"] = new_spawn_id
	
	portal_connections[portal_id] = updated_connection
	connections_updated.emit()
	return true
