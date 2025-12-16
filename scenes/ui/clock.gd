extends RichTextLabel

func _process(_delta: float) -> void:
	var t := Time.get_time_dict_from_system()
	text = "%02d:%02d:%02d" % [t.hour, t.minute, t.second]
