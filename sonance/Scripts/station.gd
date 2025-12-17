extends AudioStreamPlayer3D
class_name Station

@export var frequency: float
@export var freq_range: float
var station_name : String
func _ready():
	volume_db = -80
	#stream.loop_mode = AudioStreamWAV.LoopMode.LOOP_FORWARD
	play()
