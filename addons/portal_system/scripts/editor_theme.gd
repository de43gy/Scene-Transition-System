@tool
extends RefCounted

func get_id_from_url(url: String) -> int:
	var id_pattern = "id%"
	var start_index = url.find(id_pattern)
	
	if start_index == -1:
		return -1
		
	start_index += id_pattern.length() + 5 + 5
	var end_index = url.find("%", start_index)
	
	if end_index == -1:
		return -1
		
	return url.substr(start_index, end_index - start_index).to_int()
